// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @dev implement interface for staking and withdraw CAKE by PancakeSwap Syrup
 * Syrup manual address on BSC mainnet: 0x73feaa1eE314F8c655E354234017bE2193C9E24E
 */
interface ICakeManual {
    //Stake CAKE Tokens to PancakeSwap Syrup
    function enterStaking(uint256 _amount) external;

    //Withdraw CAKE Tokens from PancakeSwap Syrup
    function leaveStaking(uint256 _amount) external;
}