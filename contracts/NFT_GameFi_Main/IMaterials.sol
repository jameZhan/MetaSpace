// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IMaterials {
    
    function materialName(uint256 id) external view returns (string memory);

    function totalSupply(uint256 id) external view returns (uint256);

    function exists(uint256 id) external view returns (bool);

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    function burn(address account, uint256 id, uint256 amount) external;

    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) external;
}