// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./MollectorCardBase.sol";

contract MollectorCard is MollectorCardBase {
    struct NFTLink {
        uint network;
        address add;
    }

    uint[] public DNAs;

    NFTLink[] public NFTLinks;
    mapping(uint => mapping(uint => uint)) CardLinks; // MolTokenId => NFT Contract Index => NFT Contract's tokenId

    event Spawned(uint256 indexed _tokenId, address indexed _owner, uint256 _dna);
    event Updated(uint256 indexed _tokenId, uint256 _dna);

    constructor(address _owner) ERC721("CyBloc", "BLOC") AccessControl(_owner) {
    }

    function _spawn(address _owner, uint256 _dna) internal returns (uint256) {
        DNAs.push(_dna);
        
        uint256 newCyblocId = DNAs.length - 1;
        _safeMint(_owner, newCyblocId);
        
        emit Spawned(newCyblocId, _owner, _dna);

        return newCyblocId;
    }

    function _update(uint _tokenId, uint256 _dna) internal {
        DNAs[_tokenId] = _dna;

        emit Updated(_tokenId, _dna);
    }

    function fusion(uint _tokenId1, uint _tokenId2) public {
        require(ownerOf(_tokenId1) == msg.sender && ownerOf(_tokenId2) == msg.sender, "You are not owner of tokens");

        uint newDNA = fusionDNA(DNAs[_tokenId1], DNAs[_tokenId2]);

        _update(_tokenId1, newDNA);
        _burn(_tokenId2);
    }

    function levelUp(uint _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "You are not owner of token");

        uint newDNA = levelUpDNA(DNAs[_tokenId]);
        _update(_token_tokenIdId1, newDNA);
    }

    function mutant(uint _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "You are not owner of token");

        uint newDNA = mutantDNA(DNAs[_tokenId]);
        _update(_tokenId, newDNA);
    }

    function linkNFT(uint _tokenId, uint _nftLinkIndex, uint _nftLinkTokenId, Proof memory _proof) public {
        require(NFTLinks[_nftLinkIndex].add != address(0x0), "Invalid NFTLink");
        require(ownerOf(_tokenId) == msg.sender, "You are not owner of token");

        bytes memory encode = abi.encodePacked(_tokenId, _nftLinkIndex, _nftLinkTokenId, msg.sender);
        require(verifyProof(encode, _proof), "Wrong proof");

        CardLinks[_tokenId][_nftLinkIndex] = _nftLinkTokenId;
    }
}
