// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IMollectorCard.sol";
import "./DNAGenerator.sol";

contract MoleculePack is Ownable, ERC721Enumerable {
    using SafeMath for uint256;

    string public baseURI = "https://nftmetadata.mollector.com/pack/";
    
    uint256 constant public PACK_COMMON = 1;
    uint256 constant public PACK_RARE = 2;
    uint256 constant public PACK_EPIC = 3;

    uint[] packPrice = [0, 1e17, 2e17, 3e17];
    uint[] packSold = [0, 0, 0, 0];
    
    IMollectorCard public NFTContract;
    address public signer;

    uint256[] public packs;

    event OpenedPack(address indexed receiver, uint tokenId, uint[] gene);
    event SoldPack(address indexed buyer, uint packType, uint quantity);
    
    constructor(address _NFTContract) ERC721("Mollector Genesis Pack", "MOLPACK") {
        NFTContract = IMollectorCard(_NFTContract);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function contractURI() external view returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setNFTContract(address _NFTContract) external onlyOwner {
        NFTContract = IMollectorCard(_NFTContract);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setPrice(uint[] memory _packPrice) external onlyOwner {
        packPrice = _packPrice;
    }

    function mint(address _to, uint256 _packType) internal returns (uint256 tokenId) {
        require(_packType == PACK_COMMON || _packType == PACK_RARE || _packType == PACK_EPIC, "MoleculePack: wrong type");

        tokenId = packs.length;
        packs.push(_packType);
        _safeMint(_to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        require(from == address(0x0) || to == address(0x0), "No Transfer");
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function verifyProof(uint _tokenId, uint[] memory gene, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (bool)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(address(this), msg.sender, _tokenId, gene[0], gene[1], gene[2], gene[3], gene[4])
        );
        address signatory = ecrecover(digest, v, r, s);

        if (signer != address(0x0)) {
            return signatory == signer;
        }

        return true;
    }

    function open(
        uint[] memory tokenIds, 
        uint[][] memory genes
        // uint8[] memory v,
        // bytes32[] memory r,
        // bytes32[] memory s
        ) external {
        // uint version, uint cardId, uint rarity, uint level, uint seed

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            uint[] memory gene = genes[i];
            // require(verifyProof, tokenId, gene, v[i], r[i], s[i]);
            require(ownerOf(tokenId) == msg.sender, "MoleculePack: Wrong pack");
            
            _burn(tokenId);

            NFTContract.spawn(
                msg.sender, 
                DNAGenerator.generate(
                    gene[0], // version
                    gene[1], // cardId
                    gene[2], // rarity
                    gene[3], // level
                    gene[4]  // seed
                )
            );

            emit OpenedPack(msg.sender, tokenId, gene);                    
        }
    }

    function buy(uint256 _packType, uint256 _quantity) external payable {
        require(_quantity > 0, "MoleculePackSale: Invalid quantity");
        
        uint totalPrice = packPrice[_packType] * _quantity;
        
        require(msg.value >= totalPrice, "MoleculePackSale: Invalid msg.value");

        packSold[_packType] += _quantity;

        for (uint256 i = 0; i < _quantity; i++) {
            mint(msg.sender, _packType);
        }

        payable(owner()).transfer(totalPrice);

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value.sub(totalPrice));
        }

        emit SoldPack(msg.sender, _packType, _quantity);
    }
}