// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OperatorAccess {
    address[] public operators;
    mapping(address => bool) public operator;

    modifier onlyOperator() {
        require(operator[msg.sender], "No permission");
        _;
    }

    function _addOperator(address _add) internal {
        require(!operator[_add], "It's operator already");
        operators.push(_add);
        operator[_add] = true;
    }

    function _removeOperator(address _add) internal {
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

contract NeogenesisCard is ERC721Enumerable, Ownable, OperatorAccess {
    string public baseURI = "https://api-dev.mollector.com/api/nft/";

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function contractURI() external view returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function addOperator(address _add) public onlyOwner {
        _addOperator(_add);
    }

    function removeOperator(address _add) public onlyOwner {
        _removeOperator(_add);
    }
    
    constructor(address _operator) ERC721("TEST Mollector Card", "TESTMOLCARD") {
        _addOperator(_operator);
    }

    function update(address _owner, uint _tokenId) public onlyOperator returns (uint256) {
        require(_tokenId > 0, "Missing tokenId");

        if (_exists(_tokenId)) {
            if (_owner == address(0x0)) {
                _burn(_tokenId);
            }
            else {
                address _oldOwner = ownerOf(_tokenId);
                if (_oldOwner != _owner) {
                    _safeTransfer(_oldOwner, _owner, _tokenId, "");
                }
            }
        }
        else {
            _safeMint(_owner, _tokenId);
        }

        return _tokenId;
    }

    function batch(address[] memory _owners, uint[] memory _tokenIds) public onlyOperator {
        for (uint i = 0; i < _owners.length; i++) {
            update(_owners[i], _tokenIds[i]);
        }
    }

    function ownerOfIds(uint[] memory _tokenIds) public view returns (address[] memory owners) {
        owners = new address[](_tokenIds.length);
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (_exists(_tokenIds[i])) {
                owners[i] = ownerOf(_tokenIds[i]);
            }
            else {
                owners[i] = owner();
            }
        }
    }
}
