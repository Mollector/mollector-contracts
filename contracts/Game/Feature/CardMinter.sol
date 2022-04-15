// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../IMollectorCard.sol";
import "../DNAGenerator.sol";

contract CardMinter {
    
    IMollectorCard public MC;

    constructor(IMollectorCard _mc) {
        MC = _mc;
    }

    function mint() public {
        MC.spawn(
            msg.sender, 
            DNAGenerator.generate(
                1, 
                uint256(keccak256(abi.encodePacked(blockhash(block.number - 1)))) % 29 + 1, 
                1, 
                uint256(keccak256(abi.encodePacked(blockhash(block.number - 1)))) % 3 + 1, 
                uint256(keccak256(abi.encodePacked(blockhash(block.number - 1))))
            )
        );
    }
}
