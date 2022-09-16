// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Game/IMollectorCard.sol";
import "./Game/MollectorDNAGenerator.sol";
// export const PlayerPackTypeMapping = {
//     'wooden': 1,
//     'bronze': 2,
//     'silver': 3,
//     'golden': 4,
//     'magic': 5,
//     'legendary': 6,
//     'mollector': 7,
//     'mythic': 8,
//     'ultimate': 9,
//     'starter': 10,
//     'fighter': 11,
//     'veteran': 12,
//     'master': 13,
//     'champion': 14,
//     'merchant': 15,
//     'vip': 16,
//     'noble': 17,
//     'royal': 18
// }
contract MollectorPack is Ownable, ERC721Enumerable {
    using SafeMath for uint256;

    string public baseURI = "https://nftmetadata.mollector.com/pack/";
    
    IMollectorCard public NFTContract;
    MollectorDNAGenerator public DNAGenerator;
    address public signer;
    mapping(uint => uint) public price;


    uint256[] public packs;

    event OpenedPack(address indexed receiver, uint tokenId);
    event SoldPack(address indexed buyer, uint packType, uint quantity);
    
    constructor(address _NFTContract, address _DNAGenerator, address _signer) ERC721("Mollector Genesis Pack", "MOLPACK") {
        NFTContract = IMollectorCard(_NFTContract);
        DNAGenerator = MollectorDNAGenerator(_DNAGenerator);
        signer = _signer;
        price[6] = 1e16;
        price[7] = 2e16;
        price[8] = 3e16;
        price[9] = 4e16;
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

    function setDNAGenerator(address _DNAGenerator) external onlyOwner {
        DNAGenerator = MollectorDNAGenerator(_DNAGenerator);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setPrice(uint _packType, uint _price) external onlyOwner {
        price[_packType] = _price;
    }

    function mint(address _to, uint256 _packType) internal returns (uint256 tokenId) {
        tokenId = packs.length;
        packs.push(_packType);
        _safeMint(_to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        require(from == address(0x0) || to == address(0x0), "No Transfer");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }


    function verifyProof(uint _packId, uint _tokenId, uint[] memory gene, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (bool)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(getChainID(), address(this), msg.sender, _packId, _tokenId, gene[0], gene[1], gene[2], gene[3], gene[4])
        );
        address signatory = ecrecover(digest, v, r, s);

        if (signer != address(0x0)) {
            return signatory == signer;
        }

        return true;
    }

    function open(
        uint[] memory packIds, 
        uint[] memory tokenIds,
        uint[][] memory genes,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
        ) external {
        // uint version, uint cardId, uint rarity, uint level, uint seed

        uint index = 0;

        for (uint256 i = 0; i < packIds.length; i++) {
            uint packId = packIds[i];
            require(ownerOf(packId) == msg.sender, "MoleculePack: Wrong pack");
            
            _burn(packId);
            for (uint256 j = 0; j < 5; j++) {
                uint[] memory gene = genes[index];
                require(verifyProof(packId, tokenIds[index], gene, v[index], r[index], s[index]));
                NFTContract.spawn(msg.sender, tokenIds[index],
                    DNAGenerator.generate(
                        gene[0], // version
                        gene[1], // cardId
                        gene[2], // rarity
                        gene[3], // level
                        gene[4]  // seed
                    )
                );
                index++;
            }

            emit OpenedPack(msg.sender, packId);                    
        }
    }

    function buy(uint256 _packType, uint256 _quantity) external payable {
        require(_quantity > 0, "MoleculePackSale: Invalid quantity");
        
        uint totalPrice = price[_packType] * _quantity;

        require(totalPrice > 0, "Wrong pack type");
        
        require(msg.value >= totalPrice, "MoleculePackSale: Invalid msg.value");

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