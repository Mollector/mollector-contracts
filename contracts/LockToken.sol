// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LockToken {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  mapping(address => mapping(address => uint)) public amounts;
  mapping(address => mapping(address => uint[])) public history;

  function lock(address token, uint amount) public {
    require(amount > 0, "Wrong amount");
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    amounts[token][msg.sender] = amounts[token][msg.sender].add(amount);

    history[token][msg.sender].push(amount * 10**12 + block.timestamp);
  }

  function withdraw(address token, uint amount) public {
    require(amounts[token][msg.sender] >= amount, "Wrong amount");

    amounts[token][msg.sender] = amounts[token][msg.sender].sub(amount);
    IERC20(token).safeTransfer(msg.sender, amount);

    history[token][msg.sender].push(block.timestamp);
  }
}