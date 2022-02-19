// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Math.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IMaterials.sol";
import "./IStakingProof.sol";
import "./IERC721.sol";
import "./IMetaSpace.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./RewardsDistributionRecipient.sol";


contract StarFarm is Context, Ownable, RewardsDistributionRecipient, ReentrancyGuard, IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    // This ERC721 token is used to transfer ownership while Staking; methods: ownerOf, safeMint, burn
    IStakingProof public stakingProof;
    // Staking ERC721 housesNFT; can not be withdraw but be burned;
    IERC721 public housesERC721;
    IMetaSpace public housesNFT;
    // When housesNFT is burned, 50% of materials will be minted to its stakingProof owner;
    // Notice: not mint to the original owner of housesNFT, if it was transfered to another address
    IMaterials public materials;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 14 days;  // default by 2 weeks
    uint256 public lastUpdateTime;
    uint256 public rewardPerPointStored;
    
    uint256 public constant RENTING_PERIOD = 12 hours;
    uint256 public constant PROTECTING_PERIOD = 10 minutes;
    // default for sharing 15%, can be modified by the admin. from 0 to 100
    uint256 public share = 15;
    uint256 public collectionCardId = 18;
    uint256 public collectionCardAmounts = 1;
    uint256 public starFee = 0; // defaule 0 Star


    // tokenId => bool
    mapping(uint256 => bool) public isStaked;
    // tokenId => harvest time
    mapping(uint256 => uint256) public harvestTime;
    // tokenId => star amount
    mapping(uint256 => uint256) public userRewardPerPointPaid;
    // tokenId => star amount
    mapping(uint256 => uint256) public rewards;
    // accumulated staking NFT houses points
    uint256 private _totalSupply;
    // tokenId => points for this staking Id house
    mapping(uint256 => uint256) private _balances;

    // house's level => material's ids array
    mapping(uint256 => uint256[]) private _levelToIds;
    // house's level => material's amounts array
    mapping(uint256 => uint256[]) private _levelToAmounts;


    /* ========== EVENTS ========== */

    event RewardAdded(uint256 indexed reward);
    event Staked(address indexed user, uint256 indexed tokenId, uint256 indexed initialHarvestTime);
    event Withdrawn(address indexed user, uint256 indexed tokenId, uint256 indexed withdrawTime);
    event RewardPaid(address indexed user, uint256 indexed reward, uint256 indexed nextHarvestTime);
    event RewardsDurationUpdated(uint256 indexed newDuration);
    event Recovered(address token, uint256 amount);


    /* ========== CONSTRUCTOR ========== */

    constructor() public {
        rewardsToken = IERC20(0x1C78C9Aa8B21589702A5fA6A2C8ad875f6c7d8D3);
        stakingProof = IStakingProof(0x1641B16a28375b63A12722C07E0707203B1F5ADb);
        housesERC721 = IERC721(0x99eC71BD759eA433d2408a138B80053C111cb283);
        housesNFT = IMetaSpace(0x99eC71BD759eA433d2408a138B80053C111cb283);
        materials = IMaterials(0xeD9825D3f6501D0C5379e0b3edE36D24f057A527);
        // set the initial distributor as the contract deployer
        rewardsDistribution = _msgSender();

        _setLevelIds();
        _setLevelAmounts();
    }

    function setShare(uint256 _newShare) public onlyOwner {
        share = _newShare;
    }

    function setStarFee(uint256 _newFee) public onlyOwner {
        starFee = _newFee;
    }


    /* ========== VIEWS ========== */

    // accumulated points for all staking NFT houses
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // points for each NFT house
    function balanceOf(uint256 tokenId) external view returns (uint256) {
        require(isStaked[tokenId], "this house NFT is not staked yet");
        return _balances[tokenId];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerPoint() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerPointStored;
        }
        return
            rewardPerPointStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(uint256 tokenId) public view returns (uint256) {
        require(isStaked[tokenId], "this house NFT is not staked yet");
        return _balances[tokenId].mul(rewardPerPoint().sub(userRewardPerPointPaid[tokenId])).div(1e18).add(rewards[tokenId]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function isReadyToHarvest(uint256 tokenId) public view returns (bool) {
        require(isStaked[tokenId], "this house NFT is not staked yet");
        return block.timestamp > harvestTime[tokenId] ? true : false;
    }

    function isReadyToSteal(uint256 tokenId) public view returns (bool) {
        require(isStaked[tokenId], "this house NFT is not staked yet");
        return block.timestamp > harvestTime[tokenId].add(PROTECTING_PERIOD) ? true : false;
    }

    function checkUserStakedTokenIds(address account) public view returns (uint256[] memory) {
        uint256 proofBalance = stakingProof.balanceOf(account);
        uint256[] memory result = new uint256[](proofBalance);

        if (proofBalance > 0) {
            for(uint256 i = 0; i < proofBalance; ++i) {
                result[i] = stakingProof.tokenOfOwnerByIndex(account, i);
            }
        }
        return result;
    }


    /* ========== MUTATIVE FUNCTIONS ========== */
    // house NFT contract: approve before use this method
    // this contract must be the Minter of staking proof contract
    function stake(uint256 tokenId) external nonReentrant {
        require(!isStaked[tokenId], "this house NFT has been staked");
        // update reward counting for this token
        rewardPerPointStored = rewardPerPoint();          // add rewards of this period of time to total rewards before
        lastUpdateTime = lastTimeRewardApplicable();      // reset the update timestamp
        rewards[tokenId] = 0;
        userRewardPerPointPaid[tokenId] = rewardPerPointStored;

        // read info for this tokenId
        uint256 points = housesNFT.checkHouseLuxury(tokenId);
        _totalSupply = _totalSupply.add(points);
        _balances[tokenId] = points;
        // stake house NFT
        housesERC721.safeTransferFrom(_msgSender(), address(this), tokenId);
        // send a staking proof(ERC721) to its owner
        stakingProof.safeMint(_msgSender(), tokenId);
        harvestTime[tokenId] = block.timestamp.add(RENTING_PERIOD);

        isStaked[tokenId] = true;

        emit Staked(msg.sender, tokenId, harvestTime[tokenId]);
    }

    // only the staking proof's owner can trigger this method to burn NFT house
    // and receive half amounts of materials.
    // staking proof contract: approve before use this method
    // this contract must be the Minter of materials contract
    function withdraw(uint256 tokenId) public nonReentrant {
        require(isStaked[tokenId], "this house NFT is not staked yet");
        require(stakingProof.ownerOf(tokenId) == _msgSender(), "caller is not the staking proof owner");
        _updateReward(tokenId);

        // read info for this tokenId
        uint256 level = housesNFT.checkHouseLevel(tokenId);
        uint256 points = housesNFT.checkHouseLuxury(tokenId);
        _totalSupply = _totalSupply.sub(points);
        _balances[tokenId] = 0;
        // burn house NFT and its staking proof
        housesNFT.burn(tokenId);
        stakingProof.burn(tokenId);
        // mint half materials
        uint256[] memory ids = _levelToIds[level];
        uint256[] memory amounts = _levelToAmounts[level];
        materials.mintBatch(_msgSender(), ids, amounts, "");

        // reset harvest time to 0?
        harvestTime[tokenId] = 0;

        // can not getReward anymore after withdraw
        isStaked[tokenId] = false;

        emit Withdrawn(msg.sender, tokenId, block.timestamp);
    }

    // Materials: must "setApprovalForAll" for non-owners
    // Star: must "approve" for non-owners
    function getReward(uint256 tokenId) public nonReentrant {
        require(isStaked[tokenId], "this house NFT is not staked yet");
        // must reach the 8 hours Renting period
        require(block.timestamp > harvestTime[tokenId], "Renting period has not ended yet, try later");
        _updateReward(tokenId);
        
        // the total rewards until now for this NFT staking house
        uint256 reward = rewards[tokenId];
        require(reward > 0, "Your reward is 0 now, try later");
        // read this staking house's proof owner
        address proofOwner = stakingProof.ownerOf(tokenId);

        rewards[tokenId] = 0;
        // within the protecting period: only staking proof owner can getReward
        if (_msgSender() == proofOwner) {
            rewardsToken.safeTransfer(proofOwner, reward);
            // reset 8 hours locking time
            harvestTime[tokenId] = block.timestamp.add(RENTING_PERIOD);
        } else { // beyond the protecting period: msgSender shares 50% profits with staking proof owner
            require(block.timestamp >= harvestTime[tokenId].add(PROTECTING_PERIOD), "Not allowed: within Protection period");
            // consume collectionCard
            materials.burn(_msgSender(), collectionCardId, collectionCardAmounts);
            if (starFee > 0) {
                // pay starFee
                rewardsToken.safeTransferFrom(_msgSender(), address(this), starFee);
            }
            uint256 shareReward = reward.mul(share).div(100);
            uint256 remaining = reward.sub(shareReward);
            rewardsToken.safeTransfer(proofOwner, remaining);
            rewardsToken.safeTransfer(_msgSender(), shareReward);
            // reset 8 hours locking time
            harvestTime[tokenId] = block.timestamp.add(RENTING_PERIOD);
        }

        emit RewardPaid(proofOwner, reward, harvestTime[tokenId]);
    }

    function getRewardAndWithdraw(uint256 tokenId) external {
        // change order: getReward first, then withdraw
        // can not getReward after withdraw, because "isStaked == false" after withdraw
        getReward(tokenId);
        withdraw(tokenId);
    }


    /* ========== RESTRICTED FUNCTIONS ========== */

    // 1. trasfer 'reward' amount STAR to this Farm address
    // 2. Reward Distributor address triggers this function, and START FARMING
    function notifyRewardAmount(uint256 reward) external onlyRewardsDistribution {
        // updateReward
        rewardPerPointStored = rewardPerPoint();

        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    // Added to support recovering LP Rewards from other systems to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }


    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _updateReward(uint256 tokenId) private {
        rewardPerPointStored = rewardPerPoint();          // add rewards of this period of time to total rewards before
        lastUpdateTime = lastTimeRewardApplicable();      // reset the update timestamp

        rewards[tokenId] = earned(tokenId);
        userRewardPerPointPaid[tokenId] = rewardPerPointStored;
    }

    function _setLevelIds() private {
        _levelToIds[1] = [1, 2];
        _levelToIds[2] = [1, 7, 3];
        _levelToIds[3] = [6, 7, 8];
        _levelToIds[4] = [6, 7, 8, 9, 10];
        _levelToIds[5] = [6, 7, 8, 9, 10];
        _levelToIds[6] = [6, 7, 8, 9, 10];
    }

    function _setLevelAmounts() private {
        _levelToAmounts[1] = [2400, 3600];
        _levelToAmounts[2] = [5000, 3525, 3330];
        _levelToAmounts[3] = [2750, 3675, 4500];
        _levelToAmounts[4] = [4000, 4500, 7650, 6000, 3750];
        _levelToAmounts[5] = [35000, 18750, 13500, 30000, 47500];
        _levelToAmounts[6] = [350000, 90000, 90000, 250000, 500000];
    }
}