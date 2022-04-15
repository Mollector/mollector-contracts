// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library DNAGenerator {
    function generate(uint version, uint cardId, uint rarity, uint level, uint seed) public pure returns (uint gene) {
        require(version <= 9999999, "DNAGenerator: Wrong version");
        require(1 <= cardId && cardId <= 999999999999, "DNAGenerator: Wrong cardId");
        require(1 <= rarity && rarity <= 99, "DNAGenerator: Wrong rarity");
        require(1 <= level && level <= 99, "DNAGenerator: Wrong level");

        gene = version * 10 ** 16
                + cardId * 10 ** 4
                + rarity * 10 ** 2
                + level;

        gene = gene * 10**50 + seed % 10 ** 50;

        (uint256 v, uint256 c, uint256 r, uint256 l, uint256 s) = parse(gene);
        
        require(v == version
            && c == cardId
            && r == rarity
            && l == level
            && s == seed % 10**50);
    }

    function parse(uint dna) public pure returns (uint version, uint cardId, uint rarity, uint level, uint seed) {
        seed = dna % 10 ** 50;
        dna = dna / 10 ** 50;
        
        version     =  dna           / 10**16;
        cardId      = (dna % 10**16) / 10**4;
        rarity      = (dna % 10**4 ) / 10**2;
        level       = (dna % 10**2 );
    }

    function updateRarityAndLevel(uint dna, uint newRarity, uint newLevel) public pure returns (uint newDNA) {
        (uint version, uint cardId,,, uint seed) = parse(dna);

        return generate(version, cardId, newRarity, newLevel, seed);
    }

    function updateLevel(uint dna, uint newLevel) public pure returns (uint newDNA) {
        (uint version, uint cardId, uint rarity,, uint seed) = parse(dna);

        return generate(version, cardId, rarity, newLevel, seed);
    }

    function updateRarity(uint dna, uint newRarity) public pure returns (uint newDNA) {
        (uint version, uint cardId,, uint level, uint seed) = parse(dna);

        return generate(version, cardId, newRarity, level, seed);
    }

    function updateSeed(uint dna, uint newSeed) public pure returns (uint newDNA) {
        (uint version, uint cardId, uint rarity, uint level,) = parse(dna);

        return generate(version, cardId, rarity, level, newSeed);
    }
}