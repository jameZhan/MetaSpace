// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./MinterRole.sol";
import "./Pausable.sol";
import "./ERC1155.sol";
import "./IMaterials.sol";


contract Materials is Context, Ownable, MinterRole, ERC1155, Pausable, IMaterials {
    using SafeMath for uint256;


    // id => amount
    mapping(uint256 => uint256) private _totalSupply;
    // id => material's name
    mapping(uint256 => string) private _materialName;


    constructor () public {
        _setMaterialName(1, "crystal");
        _setMaterialName(2, "gas");
        _setMaterialName(3, "gold");
        _setMaterialName(6, "diamond");
        _setMaterialName(7, "hydrogen");
        _setMaterialName(8, "radium");
    }
    

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMaterialName(uint256 id, string memory name) public onlyOwner {
        _setMaterialName(id, name);
    }

    function materialName(uint256 id) public override view returns (string memory) {
        return _materialName[id];
    }

    function totalSupply(uint256 id) public override view returns (uint256) {
        return _totalSupply[id];
    }

    function exists(uint256 id) public override view returns (bool) {
        return totalSupply(id) > 0 ? true : false;
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public override onlyMinter {
        _mint(account, id, amount, data);
        _totalSupply[id] = _totalSupply[id].add(amount);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public override onlyMinter {
        _mintBatch(to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] = _totalSupply[ids[i]].add(amounts[i]);
        }
    }

    function burn(address account, uint256 id, uint256 amount) public override {
        require(account == _msgSender() || isApprovedForAll(account, _msgSender()), "ERC1155: Caller is not owner nor approved");
        _burn(account, id, amount);
        _totalSupply[id] = _totalSupply[id].sub(amount);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) public override {
        require(account == _msgSender() || isApprovedForAll(account, _msgSender()), "ERC1155: Caller is not owner nor approved");
        _burnBatch(account, ids, amounts);
        for(uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] = _totalSupply[ids[i]].sub(amounts[i]);
        }
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }

    function _setMaterialName(uint256 id, string memory name) private {
        _materialName[id] = name;
    }

}