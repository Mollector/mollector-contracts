// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Airdrop is Ownable {
    IERC20 public token;
    address public signer;

    mapping(address => bool) public claimed;

    address public from;
    uint public startAt;

    constructor(address signer_, address NMTAddress_, uint startAt_) {
        signer = signer_;
        token = IERC20(NMTAddress_);
        startAt = startAt_;
    }

    modifier checkClaim() {
        require(!claimed[msg.sender], "CLAIMED");
        _;
    }

    modifier checkSign(uint _amount, uint8 v, bytes32 r, bytes32 s) {
        bytes32 digest = keccak256(abi.encodePacked(_amount, msg.sender));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == signer, "wrong signer");
        _;
    }

    function claim(uint _amount, uint8 v, bytes32 r, bytes32 s) external checkClaim checkSign(_amount, v, r, s) {
        require(startAt <= block.timestamp, "CLAIM NOT OPEN");
        claimed[msg.sender] = true;
        token.transfer(msg.sender, _amount);
    }

    function withdraw(address t) external onlyOwner {
        if (t == address(0x0)) {
            (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
            require(success, "failed to send ether to owner");
        }
        else {
            IERC20(t).transfer(msg.sender, IERC20(t).balanceOf(address(this)));
        }
    }

    function changeSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    function changeStartAt(uint startAt_) external onlyOwner {
        startAt = startAt_;
    }
}