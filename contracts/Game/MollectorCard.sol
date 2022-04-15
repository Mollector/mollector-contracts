// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./MollectorCardBase.sol";

contract MollectorCard is MollectorCardBase {
    struct Link {
        uint network;
        address add;
    }

    uint[] public DNAs; /// 10002000120034002300

    Link[] public Links;
    mapping(uint => mapping(uint => uint)) public CardLinks; // MolTokenId => NFT Contract Index => NFT Contract's tokenId

    event Spawned(uint256 indexed _tokenId, address indexed _owner, uint256 _dna);
    event Burned(uint256 indexed _tokenId);
    event Updated(uint256 indexed _tokenId, uint256 _dna);
    event Linked(uint indexed _tokenId, uint _nftLinkIndex, uint _nftLinkTokenId);
    event AddLink(uint indexed _id, uint _network, address _add);

    constructor() ERC721("Mollector Card", "MOLCARD") {
    }

    /**
        Only burn by Operator, and Operator is a SmartContract that define how and why it burns 
        an item, This function help improve UX 
     */
    function burn(uint _tokenId) public onlyOperator {
        _burn(_tokenId);

        emit Burned(_tokenId);
    }

    function spawn(address _owner, uint256 _dna) public onlyOperator returns (uint256) {
        DNAs.push(_dna);
        
        uint256 newCyblocId = DNAs.length - 1;
        _safeMint(_owner, newCyblocId);
        
        emit Spawned(newCyblocId, _owner, _dna);

        return newCyblocId;
    }

    function update(uint _tokenId, uint256 _dna) public onlyOperator {
        require(_exists(_tokenId), "Nonexistent token");

        DNAs[_tokenId] = _dna;

        emit Updated(_tokenId, _dna);
    }

    function link(uint _tokenId, uint _nftLinkIndex, uint _nftLinkTokenId) public onlyOperator {
        require(_exists(_tokenId), "Nonexistent token");
        require(Links[_nftLinkIndex].add != address(0x0), "Invalid NFTLink");
        
        CardLinks[_tokenId][_nftLinkIndex] = _nftLinkTokenId;

        emit Linked(_tokenId, _nftLinkIndex, _nftLinkTokenId);
    }

    function addLink(uint _network, address _add) public onlyOperator {
        Links.push(Link({
            network: _network,
            add: _add
        }));

        emit AddLink(Links.length - 1, _network, _add);
    }
}
