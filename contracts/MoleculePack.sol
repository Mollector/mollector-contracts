// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./AccessControl.sol";

interface IMoleculeCore {
    function newCyBloc(address _owner, uint256[5] memory _info, uint256 _mentor1, uint256 _mentor2) external returns (uint256);
}

contract MoleculePack is AccessControl, ERC721Enumerable {
    struct PackOpen {
        uint256 tokenId;
        uint256[5] gene; // [class, trait1, trait2, trait3, seed]
    }

    string public baseURI = "https://nftmetadata.cyball.com/blocpack/";
    string public contractURIPrefix = "https://nftmetadata.cyball.com/blocpack/";
    
    uint256 constant public PACK_COMMON = 1;
    uint256 constant public PACK_RARE = 2;
    uint256 constant public PACK_EPIC = 3;
    
    IMoleculeCore public NFTContract;
    mapping(address => mapping(uint256 => bool)) public Sellers;

    uint256[] public packs;
    mapping(uint256 => bool) public locks;


    event MolPacksOpened(address indexed receiver, PackOpen PacksOpen);
    
    constructor(address _owner, address _NFTContract) ERC721("Mollector Genesis Pack", "MOLPACK") AccessControl(_owner) {
        NFTContract = IMoleculeCore(_NFTContract);
    }

    modifier onlySellerOrOwner(uint256 _packType) {
        require(Sellers[msg.sender][_packType] || owner() == msg.sender, "MoleculePack: wrong seller or owner");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function contractURI() external view returns (string memory) {
        return contractURIPrefix;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setContractURI(string memory _uri) external onlyOwner {
        contractURIPrefix = _uri;
    }

    function setSeller(uint256 _packType, address _seller) external onlyOwner {
        Sellers[_seller][_packType] = true;
    }

    function removeSeller(uint256 _packType, address _seller) external onlyOwner {
        Sellers[_seller][_packType] = false;
    }

    function setNFTContract(address _NFTContract) external onlyOwner {
        NFTContract = IMoleculeCore(_NFTContract);
    }

    function mint(address _to, uint256 _packType) public onlySellerOrOwner(_packType) returns (uint256 tokenId) {
        require(_packType == PACK_COMMON || _packType == PACK_RARE || _packType == PACK_EPIC, "MoleculePack: wrong type");

        tokenId = packs.length;
        packs.push(_packType);
        _safeMint(_to, tokenId);
    }

    function mintMultiple(uint n, address _to, uint256 _packType) external onlyOwner {
        for (uint i = 0; i < n; i++) {
            mint(_to, _packType);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        require(!locks[tokenId] || to == address(0x0), "MoleculePack: Token is locked"); // only transfer if token are not LOCKED or transfer to 0x0 for burning token
        super._beforeTokenTransfer(from, to, tokenId);

    }

    function lock(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "MoleculePack: wrong id");
            locks[tokenId] = true;
        }
    }

    function open(PackOpen[] memory openPacks, Proof[] memory _proofs) external {
        require(openPacks.length > 0, "MoleculePack: empty openPacks");

        for (uint256 i = 0; i < openPacks.length; i++) {
            PackOpen memory pack = openPacks[i];

            require(ownerOf(pack.tokenId) == msg.sender, "MoleculePack: Wrong pack");
            require(locks[pack.tokenId], "MoleculePack: Pack must be lock before open");
            require(verifyProof(abi.encodePacked(pack.tokenId, pack.gene), _proofs[i]), "MoleculePack: Wrong proof");
            
            _burn(pack.tokenId);

            NFTContract.newCyBloc(msg.sender, pack.gene, 0, 0);
            emit MolPacksOpened(msg.sender, pack);                    
        }
    }
}