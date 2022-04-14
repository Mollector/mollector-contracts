// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../OperatorAccess.sol";

contract OriginOwner is Ownable, OperatorAccess {
    mapping(uint => address) public originOwner;
    
    function addOperator(address _add) public onlyOwner {
        _addOperator(_add);
    }

    function removeOperator(address _add) public onlyOwner {
        _removeOperator(_add);
    }

    function setOriginOwner(uint _tokenId, address _owner) public onlyOperator {
        originOwner[_tokenId] = _owner;
    }
}
