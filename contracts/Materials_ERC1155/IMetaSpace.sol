// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IMetaSpace {

    function safeMint(address to, uint256 level) external;

    function burn(uint256 tokenId) external;

    function checkHouseLevel(uint256 tokenId) external view returns (uint256);

    function checkHouseBulidingPeriod(uint256 tokenId) external view returns (uint256);

    function checkHouseArea(uint256 tokenId) external view returns (uint256);

    function checkHouseLuxury(uint256 tokenId) external view returns (uint256);

    function checkHouseDurability(uint256 tokenId) external view returns (uint256);

    function checkHouseLuck(uint256 tokenId) external view returns (uint256);

    function checkHouseRentingPeriod(uint256 tokenId) external view returns (uint256);

    function checkHouseProtectingPeriod(uint256 tokenId) external view returns (uint256);
}