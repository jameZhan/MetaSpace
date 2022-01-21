// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Address.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";


library EnumerableSet {
    struct UintSet {
        uint256[] _values;
        mapping (uint256 => uint256) _indexes;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        if (contains(set, value)) {
            return false;
        }

        set._values.push(value);
        set._indexes[value] = set._values.length;
        return true;
    }


    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { 
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            uint256 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based
            set._values.pop();
            delete set._indexes[value];

            return true;
        } 
        else {
            return false;
        }
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        require(set._values.length < index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    function values(UintSet storage set) internal view returns (uint256[] memory _vals) {
        return set._values;
    }
}

// standard interface of IERC20 token
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @dev Allowed this contract to call 'safeMint' & 'burn' methods from the "HousesNFT" contract
 */
interface IHousesNFT {

    function safeMint(address to, uint256 level) external;

    function burn(uint256 tokenId) external;

    function totalSupply() external view returns(uint256);
}

/**
 * @dev Allowed this contract to call 'burn' and/or 'burnBatch' methods from the "Materials" contract
 */
interface IMaterials {

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    
    function materialName(uint256 id) external view returns (string memory);

    function totalSupply(uint256 id) external view returns (uint256);

    function exists(uint256 id) external view returns (bool);

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    function burn(address account, uint256 id, uint256 amount) external;

    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) external;
}

// This contract MUST be set as a MinterRole of the MetaSpace contract.
contract MetaSpaceFactory is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    struct claimInfo {
        bool isClaimed;
        address owner;
        uint256 level;
        uint256 finishedTime;
    }

    IHousesNFT public housesAddress;
    IMaterials public materialsAddress;

    // house's level => house's building period
    mapping(uint256 => uint256) private _levelToPeriod;
    // house's level => material's ids array
    mapping(uint256 => uint256[]) private _levelToIds;
    // house's level => material's amounts array
    mapping(uint256 => uint256[]) private _levelToAmounts;
    // buildId => bool; exist or not
    mapping(uint256 => bool) private _isBuildIdExists;
    // buildId => claimInfo
    mapping(uint256 => claimInfo) private _buildIdToClaimInfo;
    // builder => UintSet
    mapping(address => EnumerableSet.UintSet) private _builderBuildIds;

    event BuildHouse(address indexed builder, uint256 indexed buildId, uint256 expectedTime, uint256 level);
    event ClaimHouse(address indexed builder, uint256 indexed buildId, uint256 level);

    constructor () public {
        // fill in those deployed contract addresses
        setHousesAddress(0xa07ed548eE4E92e5e71eC402B9aB0514fd97A69C);
        setMaterialsAddress(0xD5483cCe65d2059c47Fbd8f7E07342942Fb7F82A);
        // set building period for each level's house
        _setHouseBuildingPeriod();
        // set house's Ids array for each level
        _setLevelIds();
        // set house's Amounts array for each level
        _setLevelAmounts();
    }

    function setHousesAddress(address newAddress) public onlyOwner {
        housesAddress = IHousesNFT(newAddress);
    }

    function setMaterialsAddress(address newAddress) public onlyOwner {
        materialsAddress = IMaterials(newAddress);
    }

    function setLevelIds(uint256 level, uint256[] memory newIds) external onlyOwner {
        _levelToIds[level] = newIds;
    }

    function setLevelAmounts(uint256 level, uint256[] memory newAmounts) external onlyOwner {
        _levelToAmounts[level] = newAmounts;
    }

    function checkHouseBuildingPeriod(uint256 level) public view returns (uint256) {
        require(level > 0 && level <=6, "level is out of range of [1, 6]");
        return _levelToPeriod[level];
    }

    function checkLevelToIds(uint256 level) public view returns (uint256[] memory) {
        require(level > 0 && level <=6, "level is out of range of [1, 6]");
        return _levelToIds[level];
    }

    function checkLevelToAmounts(uint256 level) public view returns (uint256[] memory) {
        require(level > 0 && level <=6, "level is out of range of [1, 6]");
        return _levelToAmounts[level];
    }

    function isBuildIdExists(uint256 buildId) public view returns (bool) {
        return _isBuildIdExists[buildId];
    }

    function checkBuilderBuildIds(address builder) public view returns (uint256[] memory) {
        return _builderBuildIds[builder].values();
    }

    function checkHouseClaimInfo(uint256 buildId) public view returns (claimInfo memory) {
        require(_isBuildIdExists[buildId], "this build id does not exist");
        return _buildIdToClaimInfo[buildId];
    }

    function isReadyToClaim(uint256 buildId) public view returns (bool) {
        require(_isBuildIdExists[buildId], "this build id does not exist");
        claimInfo storage thisClaim = _buildIdToClaimInfo[buildId];
        require(!thisClaim.isClaimed, "this hous Id has been claimed");
        if (block.timestamp >= thisClaim.finishedTime) {
            return true;
        } else {
            return false;
        }
    }

    function checkMaterialName(uint256 Id) public view returns (string memory) {
        return materialsAddress.materialName(Id);
    }

    // Approve material contract's 'burnBatch' method BEFORE calling this method.
    function buildHouse (uint256 buildId, 
                         uint256 level) public nonReentrant returns (uint256) {
        require(!_isBuildIdExists[buildId], "this build id already existed");
        require(level > 0 && level <=6, "level is out of range of [1, 6]");

        // check user's material balance is enough or not
        uint256[] memory materialIds = checkLevelToIds(level);
        uint256[] memory materialAmounts = checkLevelToAmounts(level);
        for (uint256 i = 0; i < materialIds.length; ++i) {
            uint256 id = materialIds[i];
            uint256 amount = materialAmounts[i];
            require(materialsAddress.balanceOf(_msgSender(), id) >= amount, "materials are not enough");
        }
        // if both are enough, burn material tokens and transfer Star, then you can mint HousesNFT
        materialsAddress.burnBatch(_msgSender(), materialIds, materialAmounts);
        // record the owner, level, buildId, and finish time
        uint256 expectedTime = block.timestamp.add(_levelToPeriod[level]);
        _buildIdToClaimInfo[buildId] = claimInfo({
                                                    isClaimed: false, 
                                                    owner: _msgSender(),
                                                    level: level,
                                                    finishedTime: expectedTime
                                                });
        
        _isBuildIdExists[buildId] = true;
        _builderBuildIds[_msgSender()].add(buildId);

        emit BuildHouse(_msgSender(), buildId, expectedTime, level);
        return buildId;
    }

    // This contract MUST be set as a MinterRole of the HousesNFT contract.
    function claimHouse(uint256 buildId) public nonReentrant {
        require(_isBuildIdExists[buildId], "this build id does not exist");
        claimInfo storage thisClaim = _buildIdToClaimInfo[buildId];
        require(!thisClaim.isClaimed, "this build Id has been claimed");
        address owner = thisClaim.owner;
        uint256 level = thisClaim.level;
        uint256 finishedTime = thisClaim.finishedTime;
        require(owner == _msgSender(), "only house owner can claim it");
        require(block.timestamp >= finishedTime, "house is building now, not ready to be claimed yet");

        housesAddress.safeMint(owner, level);
        thisClaim.isClaimed = true;
        _builderBuildIds[owner].remove(buildId);

        emit ClaimHouse(owner, buildId, level);
    }

    function _setHouseBuildingPeriod() private {
        _levelToPeriod[1] = 30 minutes;
        _levelToPeriod[2] = 1 hours;
        _levelToPeriod[3] = 2 hours;
        _levelToPeriod[4] = 5 hours;
        _levelToPeriod[5] = 24 hours;
        _levelToPeriod[6] = 720 hours;
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
        _levelToAmounts[1] = [4800, 7200];
        _levelToAmounts[2] = [10000, 7050, 6660];
        _levelToAmounts[3] = [5500, 7350, 9000];
        _levelToAmounts[4] = [8000, 9000, 15300, 12000, 7500];
        _levelToAmounts[5] = [70000, 37500, 27000, 60000, 95000];
        _levelToAmounts[6] = [700000, 180000, 180000, 500000, 1000000];
    }

}