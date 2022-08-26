// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MollectorOriginalArtwork is ERC721Enumerable, Ownable {
    string public baseURI = "https://demo.mollector.com/nft/picture/";
    string public contractURIPrefix = "https://demo.mollector.com/nft/picture/";

    constructor() ERC721("Mollector Original Artwork", "MOA") {
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

    function mint(address _mintTo) public onlyOwner returns (uint256) {
        uint tokenId = totalSupply() + 1;
        _safeMint(_mintTo, tokenId);

        return tokenId;
    }

    function mintMulti(address _mintTo, uint number) public onlyOwner {
        for (uint i = 0; i < number; i++) {
            mint(_mintTo);
        }
    }
}