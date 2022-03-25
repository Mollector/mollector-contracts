// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./MollectorCardBase.sol";

contract MollectorCard is MollectorCardBase {

    struct Card {
        uint256 gene;
        uint256 art;
    }

    Card[] public cards;
    
    event Spawned(uint256 indexed _tokenId, address indexed _owner, uint256 _gene);
    event Updated(uint256 indexed _tokenId, uint256 _gene);

    constructor(address _owner) ERC721("CyBloc", "BLOC") AccessControl(_owner) {
    }

    function _spawn(address _owner, uint256 _gene) internal returns (uint256) {
        cards.push(Card({
            gene: _gene,
            art: 0
        }));
        
        uint256 newCyblocId = cards.length - 1;
        _safeMint(_owner, newCyblocId);
        
        emit Spawned(newCyblocId, _owner, _gene);

        return newCyblocId;
    }

    function _update(uint _tokenId, uint256 _gene) internal {
        cards[_tokenId].gene = _gene;

        emit Updated(_tokenId, _gene);
    }
}
