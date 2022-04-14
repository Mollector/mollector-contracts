// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract OperatorAccess {
    address[] public operators;
    mapping(address => bool) public operator;

    modifier onlyOperator() {
        require(operator[msg.sender], "No permission");
        _;
    }

    function _addOperator(address _add) internal {
        require(!operator[_add], "It's operator already");
        operators.push(_add);
        operator[_add] = true;
    }

    function _removeOperator(address _add) internal {
        require(operator[_add], "It's not operator");
        operator[_add] = false;
        for (uint i = 0; i < operators.length; i++) {
            if (operators[i] == _add) {
                operators[i] = operators[operators.length - 1];
                operators.pop();
                break;
            }
        }
    }
}
