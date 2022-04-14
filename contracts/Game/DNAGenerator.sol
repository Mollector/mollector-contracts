// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library DNAGenerator {
    function generate(uint version, uint cardId, uint rarity, uint level, uint[5] memory skills, uint seed) public pure returns (uint gene) {
        require(version <= 9999999, "DNAGenerator: Wrong version");
        require(cardId <= 9999999999, "DNAGenerator: Wrong cardId");
        require(rarity <= 99, "DNAGenerator: Wrong rarity");
        require(level <= 99, "DNAGenerator: Wrong level");
        require(skills[0] <= 9999, "DNAGenerator: Wrong skill 1");
        require(skills[1] <= 9999, "DNAGenerator: Wrong skill 2");
        require(skills[2] <= 9999, "DNAGenerator: Wrong skill 3");
        require(skills[3] <= 9999, "DNAGenerator: Wrong skill 4");
        require(skills[4] <= 9999, "DNAGenerator: Wrong skill 5");

        gene = version * 10 ** 34
                    + cardId * 10 ** 24
                    + rarity * 10 ** 22
                    + level * 10 ** 20
                    + skills[0] * 10 ** 16
                    + skills[1] * 10 ** 12
                    + skills[2] * 10 ** 8
                    + skills[3] * 10 ** 4
                    + skills[4];

        gene = gene * 10**34 + seed % 10 ** 30;

        (uint256 v, uint256 c, uint256 r, uint256 l, uint256[5] memory s, uint256 se) = parse(gene);
        
        require(v == version
            && c == cardId
            && r == rarity
            && l == level
            && s[0] == skills[0]
            && s[1] == skills[1]
            && s[2] == skills[2]
            && s[3] == skills[3]
            && s[4] == skills[4]
            && se == seed % 10**30);
    }

    function parse(uint dna) public pure returns (uint version, uint cardId, uint rarity, uint level, uint[5] memory skills, uint seed) {
        seed = dna % 10 ** 30;
        dna = dna / 10 ** 34;
        
        version     =  dna           / 10**34;
        cardId      = (dna % 10**34) / 10**24;
        rarity      = (dna % 10**24) / 10**22;
        level       = (dna % 10**22) / 10**20;
        skills[0]   = (dna % 10**20) / 10**16;
        skills[1]   = (dna % 10**16) / 10**12;
        skills[2]   = (dna % 10**12) / 10**8;
        skills[3]   = (dna % 10**8 ) / 10**4;
        skills[4]   = (dna % 10**4 );
    }
}