// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AccessControl {
    using SafeERC20 for IERC20;

    address payable public _owner;

    mapping(address => bool) public operators;

    struct Proof {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event SetOperator(address indexed add, bool value);

    constructor(address _ownerAddress) {
        _owner = payable(_ownerAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender]);
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function setOwner(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        _owner = _newOwner;
    }

    function setOperator(address _operator, bool _v) external onlyOwner {
        operators[_operator] = _v;
        emit SetOperator(_operator, _v);
    }

    function verifyProof(bytes memory encode, Proof memory _proof)
        internal
        view
        returns (bool)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(getChainID(), address(this), encode)
        );
        address signatory = ecrecover(digest, _proof.v, _proof.r, _proof.s);
        return operators[signatory];
    }
    
    function withdraw(address _token, address payable _to) external onlyOwner {
        if (_token == address(0x0)) {
            (bool success, ) = payable(_to).call{ value: address(this).balance }("");
            require(success, "failed to send ether to owner");
        }
        else {
            IERC20(_token).safeTransfer(_to, IERC20(_token).balanceOf(address(this)));
        }
    }
}
