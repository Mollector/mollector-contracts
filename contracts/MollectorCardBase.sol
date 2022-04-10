// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract MollectorCardBase is ERC721Enumerable, Ownable {
    string public baseURI = "https://nftmetadata.mollector.com/card/";
    string public contractURIPrefix = "https://nftmetadata.mollector.com/card/";
    bool public paused = false;

    address[] public operators;
    mapping(address => bool) public operator;

    modifier onlyOperator() {
        require(operator[msg.sender], "No permission");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function contractURI() external view returns (string memory) {
        return contractURIPrefix;
    }    

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused, "token transfer while paused");
    }
    
    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setContractURI(string memory _uri) external onlyOwner {
        contractURIPrefix = _uri;
    }

    function addOperator(address _add) public onlyOwner {
        require(!operator[_add], "It's operator already");
        operators.push(_add);
        operator[_add] = true;
    }

    function removeOperator(address _add) public onlyOwner {
        require(operator[_add], "It's not operator");
        operator[_add] = false;
        for (uint i = 0; i < operators.length; i++) {
            if (operators[i] == _add) {
                operators[i] = operators[operators.length - 1];
                operators.pop();
                break;
            }
        }
    }
}