// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Address.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";


// standard interface of IERC20 token
// using this in this contract to receive Bino token by "transferFrom" method
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

// minter role of mateirl contract
contract SkinMarket is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    IERC20 public binoAddress;
    IMaterials public materialsAddress;

    // skin's id => Bino price (decimal: 1e18)
    mapping(uint256 => uint256) private _skinIdToPrice;
    mapping(uint256 => bool) private _skinIdAvailable;

    event BuySkin(address indexed buyer, uint256 indexed skinId, uint256 indexed amounts);

    constructor () public {
        // fill in those deployed contract addresses
        binoAddress = IERC20(0xedd9Ae85a5474bBeFFb7Cb7430Bc318A79524fD7);
        materialsAddress = IMaterials(0xB4De27B5e879E6ED343e03290a9e9183d2AA41E8);

        _skinIdAvailable[11] = true;
        _skinIdAvailable[12] = true;
        _skinIdAvailable[13] = true;
        _skinIdAvailable[14] = true;
        _skinIdAvailable[15] = true;

        _skinIdToPrice[11] = 16 * 1e18;
        _skinIdToPrice[12] = 74 * 1e18;
        _skinIdToPrice[13] = 340 * 1e18;
        _skinIdToPrice[14] = 700 * 1e18;
        _skinIdToPrice[15] = 1000 * 1e18;
    }

    function setBinoAddress(address newAddress) public onlyOwner {
        binoAddress = IERC20(newAddress);
    }

    function setMaterialsAddress(address newAddress) public onlyOwner {
        materialsAddress = IMaterials(newAddress);
    }

    function setSkinIdAvailable(uint256 skinId, bool status) public onlyOwner {
        _skinIdAvailable[skinId] = status;
    }

    function setSkinPrice(uint256 skinId, uint256 price) public onlyOwner {
        _skinIdToPrice[skinId] = price;
    }

    function withdrawBino(address account, uint256 amount) public onlyOwner {
        require(amount <= binoAddress.balanceOf(address(this)), "withdraw amount > bino balance in this contract");
        binoAddress.safeTransfer(account, amount);
    }

    function checkSkinPrice(uint256 skinId) public view returns (uint256) {
        require(_skinIdAvailable[skinId], "this skin id is not available");
        return _skinIdToPrice[skinId];
    }

    function checkSkinIdAvailable(uint256 skinId) public view returns (bool) {
        return _skinIdAvailable[skinId];
    }

    // Bino "Approve"
    function buySkin(uint256 skinId, uint256 amounts) public nonReentrant {
        require(_skinIdAvailable[skinId], "this skin id is not available");
        uint256 totalPrice = _skinIdToPrice[skinId].mul(amounts);
        require(binoAddress.balanceOf(_msgSender()) >= totalPrice, "not enough Bino balance");

        binoAddress.safeTransferFrom(_msgSender(), address(this), totalPrice);
        materialsAddress.mint(_msgSender(), skinId, amounts, '');

        emit BuySkin(_msgSender(), skinId, amounts);
    }

}