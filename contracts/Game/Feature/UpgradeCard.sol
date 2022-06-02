// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../DNAGenerator.sol";
import "../IMollectorCard.sol";

contract UpgradeCard {
    
    IMollectorCard public MC;

    constructor(IMollectorCard _mc) {
        MC = _mc;
    }

    function levelUp(uint _tokenId, uint _toLevel) public {
        require(MC.ownerOf(_tokenId) == msg.sender, "You are not owner of token");
        (,,, uint level,) = DNAGenerator.parse(MC.DNAs(_tokenId));
        require(level < 5, "Cannot level up");
        require(level < _toLevel, "Wrong level");

        uint newDNA = DNAGenerator.updateLevel(MC.DNAs(_tokenId), _toLevel);
        
        MC.update(_tokenId, newDNA);
    }

    function mutant(uint _tokenId, uint _seed) public {
        require(MC.ownerOf(_tokenId) == msg.sender, "You are not owner of token");
        
        uint newDNA = DNAGenerator.updateSeed(MC.DNAs(_tokenId), _seed);
        
        MC.update(_tokenId, newDNA);
    }

    function fusion(uint _tokenId1, uint _tokenId2) public {
        require(MC.ownerOf(_tokenId1) == msg.sender && MC.ownerOf(_tokenId2) == msg.sender, "You are not owner of tokens");
        (, uint cardId1, uint rarity1, uint level1,) = DNAGenerator.parse(MC.DNAs(_tokenId1));
        (, uint cardId2, uint rarity2, uint level2,) = DNAGenerator.parse(MC.DNAs(_tokenId2));

        //1: common
        //2: rare
        //3: supper rare
        require(rarity1 < 3, "Your card has max rarity, cannot upgrade");
        require(rarity1 == rarity2, "Not same rarity");
        require(cardId1 == cardId2, "Not same cardId");
        require(level1 == level2, "Not same level");
        require(level1 == 5, "Must be level 5");

        uint newDNA = DNAGenerator.updateRarityAndLevel(MC.DNAs(_tokenId1), rarity1 + 1, 1);

        MC.update(_tokenId1, newDNA);
        MC.burn(_tokenId2);
    }
}
