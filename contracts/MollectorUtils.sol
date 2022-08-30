// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMollectorCard {
    function DNAs(uint256) external view returns (uint256);

    function ownerOf(uint256) external view returns (address);

    function spawn(address _owner, uint256 _dna) external returns (uint256);

    function burn(uint256 _tokenId) external;

    function update(uint256 _tokenId, uint256 _dna) external;

    function link(
        uint256 _tokenId,
        uint256 _nftLinkIndex,
        uint256 _nftLinkTokenId
    ) external;

    function addLink(uint256 _network, address _add) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256);
}

interface IMollectorEscrow {
    struct NftDeposit {
        address owner;
        uint256 tokenId;
        uint64 depositedAt;
    }

    struct TokenDeposit {
        address owner;
        uint256 amount;
        uint64 depositedAt;
    }

    function getUserCountNftDeposited(address) external view returns (uint256);

    function getUserCountTokenDeposited(address)
        external
        view
        returns (uint256);

    function nftDeposits(address _owner, uint256 _index)
        external
        view
        returns (NftDeposit memory);

    function tokenDeposits(address _owner, uint256 _index)
        external
        view
        returns (TokenDeposit memory);
}

interface IMollectorPack {
    function packs(uint256) external view returns (uint256);

    function ownerOf(uint256) external view returns (address);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256);
}

interface IMollectorMarket {
    struct Auction {
        // Current owner of NFT
        address seller;
        // Price (in wei) at beginning of auction
        uint128 startingPrice;
        // Price (in wei) at end of auction
        uint128 endingPrice;
        // Duration (in seconds) of auction
        uint64 duration;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint64 startedAt;
        address payToken;
    }

    function auctions(address _tokenAddress, uint256 _tokenId)
        external
        view
        returns (Auction memory);
}

contract MollectorUtils {
    struct Card {
        uint256 tokenId;
        uint256 version;
        uint256 cardId;
        uint256 rarity;
        uint256 level;
        uint256 seed;
        address owner;
    }

    struct Pack {
        uint256 tokenId;
        uint256 packType;
        address owner;
    }

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

    function parse(uint256 dna)
        public
        pure
        returns (
            uint256 version,
            uint256 cardId,
            uint256 rarity,
            uint256 level,
            uint256 seed
        )
    {
        seed = dna % 10**50;
        dna = dna / 10**50;

        version = dna / 10**16;
        cardId = (dna % 10**16) / 10**4;
        rarity = (dna % 10**4) / 10**2;
        level = (dna % 10**2);
    }

    function getCards(address _add, uint256[] memory _tokenIds)
        public
        view
        returns (Card[] memory cards)
    {
        cards = new Card[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 dna = IMollectorCard(_add).DNAs(_tokenIds[i]);
            (
                uint256 version,
                uint256 cardId,
                uint256 rarity,
                uint256 level,
                uint256 seed
            ) = parse(dna);
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
                uint256 tokenId = owner == address(0x0)
                    ? i + from
                    : MC.tokenOfOwnerByIndex(owner, i + from);
                uint256 dna = MC.DNAs(tokenId);
                (
                    uint256 version,
                    uint256 cardId,
                    uint256 rarity,
                    uint256 level,
                    uint256 seed
                ) = parse(dna);
                cards[i] = Card({
                    tokenId: tokenId,
                    version: version,
                    cardId: cardId,
                    rarity: rarity,
                    level: level,
                    seed: seed,
                    owner: address(0x0)
                });
            }
        }
    }

    function getNftDepositOf(
        address madd,
        address owner,
        uint256 limit,
        uint256 from
    )
        public
        view
        returns (
            uint256 total,
            IMollectorEscrow.NftDeposit[] memory nftDeposits
        )
    {
        IMollectorEscrow ME = IMollectorEscrow(madd);
        total = ME.getUserCountNftDeposited(owner);
        if (from < total) {
            uint256 n = total - from > limit ? limit : total - from;
            nftDeposits = new IMollectorEscrow.NftDeposit[](n);
            for (uint256 i = 0; i < n; i++) {
                nftDeposits[i] = ME.nftDeposits(owner, i + from);
            }
        }
    }

    function getTokenDepositOf(
        address madd,
        address owner,
        uint256 limit,
        uint256 from
    )
        public
        view
        returns (
            uint256 total,
            IMollectorEscrow.TokenDeposit[] memory tokenDeposits
        )
    {
        IMollectorEscrow ME = IMollectorEscrow(madd);
        total = ME.getUserCountTokenDeposited(madd);
        if (from < total) {
            uint256 n = total - from > limit ? limit : total - from;
            tokenDeposits = new IMollectorEscrow.TokenDeposit[](n);
            for (uint256 i = 0; i < n; i++) {
                tokenDeposits[i] = ME.tokenDeposits(owner, i + from);
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
                uint256 tokenId = owner == address(0x0)
                    ? i + from
                    : MP.tokenOfOwnerByIndex(owner, i + from);
                uint256 ptype = MP.packs(tokenId);
                packs[i] = Pack({
                    tokenId: tokenId,
                    packType: ptype,
                    owner: owner
                });
            }
        }
    }

    function getPacks(address _add, uint256[] memory _tokenIds)
        public
        view
        returns (Pack[] memory packs)
    {
        packs = new Pack[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 packType = IMollectorPack(_add).packs(_tokenIds[i]);
            address owner = IMollectorPack(_add).ownerOf(_tokenIds[i]);
            packs[i] = Pack({
                tokenId: _tokenIds[i],
                packType: packType,
                owner: owner
            });
        }
    }

    function getAutions(
        address _add,
        address _tokenAddress,
        uint256[] memory _tokenIds
    ) public view returns (IMollectorMarket.Auction[] memory autions) {
        autions = new IMollectorMarket.Auction[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            autions[i] = IMollectorMarket(_add).auctions(
                _tokenAddress,
                _tokenIds[i]
            );
        }
    }
}
