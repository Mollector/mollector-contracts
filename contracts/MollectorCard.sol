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

contract MollectorCard is ERC721Enumerable, Ownable, OperatorAccess {
    string public baseURI = "https://nftmetadata.mollector.com/card/";
    string public contractURIPrefix = "https://nftmetadata.mollector.com/card/";
    bool public paused = false;

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
        _addOperator(_add);
    }

    function removeOperator(address _add) public onlyOwner {
        _removeOperator(_add);
    }

    mapping(uint => uint) public DNAs; // tokenId => dna

    event Spawned(uint256 indexed _tokenId, address indexed _owner, uint256 _dna);
    event Burned(uint256 indexed _tokenId);
    event Updated(uint256 indexed _tokenId, address _newOwner, uint256 _dna);
    event Linked(uint indexed _tokenId, uint _nftLinkIndex, uint _nftLinkTokenId);
    event AddLink(uint indexed _id, uint _network, address _add);

    constructor() ERC721("Mollector Card", "MOLCARD") {
    }

    function burn(uint _tokenId) public onlyOperator {
        _burn(_tokenId);
        delete DNAs[_tokenId];

        emit Burned(_tokenId);
    }

    function spawn(address _owner, uint256 _tokenId, uint256 _dna) public onlyOperator returns (uint256) {
        require(_tokenId > 0, "Missing tokenId");
        require(DNAs[_tokenId] == 0, "TokenId already in use");
        DNAs[_tokenId] = _dna;
        
        _safeMint(_owner, _tokenId);
        
        emit Spawned(_tokenId, _owner, _dna);

        return _tokenId;
    }

    function update(uint _tokenId, address _newOwner, uint256 _dna) public onlyOperator {
        require(_exists(_tokenId), "Nonexistent token");
        address _owner = ownerOf(_tokenId);
        if (_newOwner != address(0x0) && _owner != _newOwner) {
            _safeTransfer(_owner, _newOwner, _tokenId, "");
        }

        if (_dna != 0) {
            DNAs[_tokenId] = _dna;
        }

        emit Updated(_tokenId, _newOwner, _dna);
    }
}
