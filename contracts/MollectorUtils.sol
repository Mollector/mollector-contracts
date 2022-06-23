// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMollectorCard {
    function DNAs(uint) external view returns (uint);
    function ownerOf(uint) external view returns (address);
    function spawn(address _owner, uint256 _dna) external returns (uint);
    function burn(uint256 _tokenId) external;
    function update(uint _tokenId, uint256 _dna) external;
    function link(uint _tokenId, uint256 _nftLinkIndex, uint256 _nftLinkTokenId) external;
    function addLink(uint _network, address _add) external;
    function totalSupply() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint);
    function tokenOfOwnerByIndex(address _owner, uint _index) external view returns (uint);
}

interface IMollectorEscrow {
    struct NftDeposit {
        address owner;
        uint256 tokenId;
        uint64 depositdAt;
    }

    struct TokenDeposit {
        address owner;
        uint256 amount;
        uint64 depositdAt;
    }

    function getUserCountNftDeposited(address) external view returns (uint);
    function getUserCountTokenDeposited(address) external view returns (uint);
    function nftDeposits(address _owner, uint _index) external view returns (NftDeposit memory);
    function tokenDeposits(address _owner, uint _index) external view returns (TokenDeposit memory);
}

interface IMollectorPack {
    function packs(uint) external view returns (uint);
    function ownerOf(uint) external view returns (address);
    function totalSupply() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint);
    function tokenOfOwnerByIndex(address _owner, uint _index) external view returns (uint);
}

library MollectorUtils {
    struct Card {
        uint tokenId;
        uint version;
        uint cardId;
        uint rarity;
        uint level;
        uint seed;
        address owner;
    }

    struct Pack {
        uint tokenId;
        uint packType;
        address owner;
    }

    function parse(uint dna) public pure returns (uint version, uint cardId, uint rarity, uint level, uint seed) {
        seed = dna % 10 ** 50;
        dna = dna / 10 ** 50;
        
        version     =  dna           / 10**16;
        cardId      = (dna % 10**16) / 10**4;
        rarity      = (dna % 10**4 ) / 10**2;
        level       = (dna % 10**2 );
    }

    function getCards(address _add, uint[] memory _tokenIds) public view returns (Card[] memory cards) {
        cards = new Card[](_tokenIds.length);
        for (uint i = 0; i < _tokenIds.length; i++) {
            uint dna = IMollectorCard(_add).DNAs(_tokenIds[i]);
            (uint version, uint cardId, uint rarity, uint level, uint seed) = parse(dna);
            address owner = IMollectorCard(_add).ownerOf(_tokenIds[i]);
            cards[i] = Card({
                tokenId: _tokenIds[i],
                version: version,
                cardId: cardId,
                rarity: rarity,
                level: level,
                seed: seed,
                owner: owner
            });
        }
    }

    function getCardsOf(
        address madd,
        address owner,
        uint256 limit,
        uint256 from
    ) public view returns (uint256 total, Card[] memory cards) {
        IMollectorCard MC = IMollectorCard(madd);
        total = owner == address(0x0) ? MC.totalSupply() : MC.balanceOf(owner);
        if (from < total) {
            uint256 n = total - from > limit ? limit : total - from;
            cards = new Card[](n);
            for (uint256 i = 0; i < n; i++) {
                uint256 tokenId = owner == address(0x0) ? i + from : MC.tokenOfOwnerByIndex(owner, i + from);
                uint dna = MC.DNAs(tokenId);
                (uint version, uint cardId, uint rarity, uint level, uint seed) = parse(dna);
                cards[i] = Card({
                    tokenId: tokenId,
                    version: version,
                    cardId: cardId,
                    rarity: rarity,
                    level: level,
                    seed: seed,
                    owner: address(0)
                });
            }
        }
    }

    function getNftDepositOf(
        address madd,
        address owner,
        uint256 limit,
        uint256 from
    ) public view returns (uint256 total, IMollectorEscrow.NftDeposit[] memory nftDeposits) {
        IMollectorEscrow ME = IMollectorEscrow(madd);
        total = ME.getUserCountNftDeposited(owner);
        if (from < total) {
            uint256 n = total - from > limit ? limit : total - from;
            nftDeposits = new IMollectorEscrow.NftDeposit[](n);
            for (uint256 i = 0; i < n; i++) {
                nftDeposits[i] = ME.nftDeposits(owner,  i + from);
            }
        }
    }    

    function getTokenDepositOf(
        address madd,
        address owner,
        uint256 limit,
        uint256 from
    ) public view returns (uint256 total, IMollectorEscrow.TokenDeposit[] memory tokenDeposits) {
        IMollectorEscrow ME = IMollectorEscrow(madd);
        total = ME.getUserCountTokenDeposited(owner);
        if (from < total) {
            uint256 n = total - from > limit ? limit : total - from;
            tokenDeposits = new IMollectorEscrow.TokenDeposit[](n);
            for (uint256 i = 0; i < n; i++) {
                tokenDeposits[i] = ME.tokenDeposits(owner,  i + from);
            }
        }
    }     

    function getPackOf(
        address nftadd,
        address owner,
        uint256 limit,
        uint256 from
    ) public view returns (uint256 total, Pack[] memory packs) {
        IMollectorPack MP = IMollectorPack(nftadd);
        total = owner == address(0x0) ? MP.totalSupply() : MP.balanceOf(owner);
        if (from < total) {
            uint256 n = total - from > limit ? limit : total - from;
            packs = new Pack[](n);
            for (uint256 i = 0; i < n; i++) {
                uint256 tokenId = owner == address(0x0) ? i + from : MP.tokenOfOwnerByIndex(owner, i + from);
                uint ptype = MP.packs(tokenId);
                packs[i] = Pack({
                    tokenId: tokenId,
                    packType: ptype,
                    owner: owner
                });
            }
        }
    }

    function getPacks(address _add, uint[] memory _tokenIds) public view returns (Pack[] memory packs) {
        packs = new Pack[](_tokenIds.length);
        for (uint i = 0; i < _tokenIds.length; i++) {
            uint packType = IMollectorPack(_add).packs(_tokenIds[i]);
            address owner = IMollectorPack(_add).ownerOf(_tokenIds[i]);
            packs[i] = Pack({
                tokenId: _tokenIds[i],
                packType: packType,
                owner: owner
            });
        }
    }
}