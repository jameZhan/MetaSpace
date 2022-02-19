// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IStakingProof {
    
    function ownerOf(uint256 tokenId) external view returns (address);

    function safeMint(address to, uint256 tokenId) external;

    function burn(uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}