// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IMetaSpace.sol";
import "./ReentrancyGuard.sol";


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


// must be a Minter Role of MetaSpace NFT contract
contract MetaSpaceBlindBox is Context, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IMetaSpace public metaspace;

    uint256 public constant CAP = 10000;
    uint256 public constant ONE_PRICE = 1300 trx;    // 1300 trx for 1 box
    uint256 public constant THREE_PRICE = 3500 trx;  // 3500 trx for 3 boxes
    uint256 public constant TEN_PRICE = 10000 trx;   // 10000 trx for 10 boxes
    uint256 private _totalSold = 0;

    event BuyBox(address indexed to, uint256 indexed level);


    constructor (address metaspaceAddress) public {
        metaspace = IMetaSpace(metaspaceAddress);
    }

    function checkRemaining() public view returns (uint256) {
        return CAP.sub(_totalSold);
    }

    function buyBox(uint256 amounts) public payable nonReentrant {
        require((amounts == 1) || (amounts == 3) || (amounts == 10), "input amounts can ONLT be 1, 3, or 10");
        require(_totalSold.add(amounts) <= CAP, "can not exceed max cap of 10000 boxes");

        if (amounts == 1) {
            require(msg.value == ONE_PRICE, "you don't have 1300 trx to buy 1 box");
        } else if (amounts == 3) {
            require(msg.value == THREE_PRICE, "you don't have 3500 trx to buy 3 box");
        } else {
            require(msg.value == TEN_PRICE, "you don't have 10000 trx to buy 10 box");
        }

        _totalSold = _totalSold.add(amounts);

        for(uint256 i = 0; i < amounts; ++i) {
            // 1,2,or 3
            uint256 randLevel = _getRandomInteger();
            metaspace.safeMint(_msgSender(), randLevel);

            emit BuyBox(_msgSender(), randLevel);
        }
    }

    function withdraw(address payable to) public onlyOwner {
        to.transfer(address(this).balance);
    }

    // generate a random integer between [1, 3]
    function _getRandomInteger() private view returns (uint256) {

        uint256 randomInt = uint256(
            keccak256(
                abi.encodePacked(
                    uint256(blockhash(block.number.sub(1))),
                    uint256(block.coinbase),
                    block.difficulty,
                    block.timestamp,
                    _totalSold
                )
            )
        ).mod(10000);
        
        if (randomInt <= 4) return 3;
        else if (randomInt <= 849) return 2;
        else return 1;
    }

}
