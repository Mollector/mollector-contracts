// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./AccessControl.sol";
import "./MoleculePack.sol";

contract MoleculePackSale is AccessControl {
    using SafeMath for uint256;

    MoleculePack public MOL_PACK;
    uint256 public PACK_TYPE;

    uint256 public PRESALE_START;
    uint256 public PRESALE_END;

    uint256 public TOTAL_PACK;
    uint256 public MAX_PER_USER;
    uint256 public PACK_PRICE = 0.00001 ether;

    mapping(address => uint) public userPackCount;
    mapping(uint256 => uint256) public tokenIdToPackId;
    uint256 public numberOfSoldPack;


    event MoleculePackPurchased(address indexed adopter, uint256 quantity);

    constructor(
        address _owner,
        address _molPackNFT,
        uint256 _packType,
        uint256 _price, 
        uint256 _totalPack, 
        uint256 _start,
        uint256 _end,
        uint256 _maxPerUser
    ) AccessControl (_owner) {
        MOL_PACK = MoleculePack(_molPackNFT);
        PACK_TYPE = _packType;
        PACK_PRICE = _price;
        TOTAL_PACK = _totalPack;
        PRESALE_START = _start;
        PRESALE_END = _end;
        MAX_PER_USER = _maxPerUser;
    }

    modifier notStart() {
        require (block.timestamp < PRESALE_START, "MoleculePackSale: Presale started, Cannot change");
        _;
    }

    modifier started() {
        require (PRESALE_START <= block.timestamp && block.timestamp <= PRESALE_END, "MoleculePackSale: Have not start or already ended");
        _;
    }

    function setPackages(uint256 _totalPack, uint256 _price, uint256 _maxPerUser) external onlyOwner notStart {
        TOTAL_PACK = _totalPack;
        PACK_PRICE = _price;
        MAX_PER_USER = _maxPerUser;
    }

    function setTime(uint256 _start, uint256 _end) external onlyOwner notStart {
        PRESALE_START = _start;
        PRESALE_END = _end;
    }

    function buy(uint256 quantity, uint256 max, Proof memory _proof) external payable started {
        require(quantity > 0, "MoleculePackSale: Invalid quantity");
        require(verifyProof(abi.encodePacked(msg.sender, max), _proof), "MoleculePackSale: Wrong proof");
        require(quantity <= TOTAL_PACK.sub(numberOfSoldPack), "MoleculePackSale: Not enough packs for you");
        require(userPackCount[msg.sender] + quantity <= max, "MoleculePackSale: You buy too much");
        require(userPackCount[msg.sender] + quantity <= MAX_PER_USER, "MoleculePackSale: You buy too much2");

        uint totalPrice = PACK_PRICE * quantity;
        
        require(msg.value >= totalPrice, "MoleculePackSale: Invalid msg.value");

        uint packId = numberOfSoldPack;

        numberOfSoldPack += quantity;
        userPackCount[msg.sender] += quantity;

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = MOL_PACK.mint(msg.sender, PACK_TYPE);
            tokenIdToPackId[tokenId] = packId + 1; // if tokenId map to packId, it must be greater than 0
            packId++;
        }

        payable(owner()).transfer(totalPrice);

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value.sub(totalPrice));
        }

        emit MoleculePackPurchased(msg.sender, quantity);
    }
}
