// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMollectorCard {
    function DNAs(uint) external view returns (uint);
    function ownerOf(uint) external view returns (address);
}

contract UpgradeCard {
    
    IMollectorCard public MC;

    constructor(IMollectorCard _mc) {
        MC = _mc;
    }

    function levelUp(uint _tokenId, uint _toLevel) public {
        require(MC.ownerOf(_tokenId) == msg.sender, "You are not owner of token");

        uint newDNA = levelUpDNA(DNAs[_tokenId], _toLevel);
        _update(_tokenId, newDNA);
    }

    function mutant(uint _tokenId) public {
        require(MC.ownerOf(_tokenId) == msg.sender, "You are not owner of token");

        uint newDNA = mutantDNA(DNAs[_tokenId]);
        _update(_tokenId, newDNA);
    }

    function fusion(uint _tokenId1, uint _tokenId2) public {
        require(MC.ownerOf(_tokenId1) == msg.sender && MC.ownerOf(_tokenId2) == msg.sender, "You are not owner of tokens");

        uint newDNA = fusionDNA(MC.DNAs(_tokenId1), MC.DNAs(_tokenId2));

        MC.update(_tokenId1, newDNA);
        MC.burn(_tokenId2);
    }
}
