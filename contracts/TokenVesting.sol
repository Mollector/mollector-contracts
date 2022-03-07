// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Released(address beneficiary, uint256 amount);
    event Unlocked(address beneficiary, uint256 amount);

    IERC20 public token;

    uint256 public cliff;
    uint256 public start;
    uint256 public duration;
    uint256 public TGE;

    mapping(address => uint256) public shares;
    mapping(address => uint256) public tgeUnlock;
    mapping(address => uint256) public released;

    uint256 public totalReleased = 0;
    uint256 public totalUnlocked = 0;

    address[] public beneficiaries;

    uint public withdrawAt = 0;

    constructor(
        IERC20 _token,
        uint256 _tge,
        uint256 _startBlock,
        uint256 _cliffNumberBlock,
        uint256 _durationNumberBlock
    ) {
        _init(_token, _tge, _startBlock, _cliffNumberBlock, _durationNumberBlock);
    }
    function _init(IERC20 _token,
        uint256 _tge,
        uint256 _startBlock,
        uint256 _cliffNumberBlock,
        uint256 _durationNumberBlock) private {
        require(
            _cliffNumberBlock <= _durationNumberBlock,
            "Cliff has to be lower or equal to duration"
        );

        token = _token;
        TGE = _tge;
        start = _startBlock;

        cliff = _startBlock.add(_cliffNumberBlock);
        duration = _durationNumberBlock;
    }

    function init(IERC20 _token,
        uint256 _tge,
        uint256 _startBlock,
        uint256 _cliffNumberBlock,
        uint256 _durationNumberBlock) public onlyOwner {
        _init(_token, _tge, _startBlock, _cliffNumberBlock, _durationNumberBlock);
    }

    function totalBeneficiaries() public view returns (uint) {
        return beneficiaries.length;
    }

    function totalVestingAmount() public view returns (uint) {
        uint total = 0;
        for (uint i = 0; i < beneficiaries.length; i++) {
            total = total.add(shares[beneficiaries[i]]);
        }

        return total;
    }

    function totalLockAmount() public view returns (uint) {
        uint total = 0;
        for (uint i = 0; i < beneficiaries.length; i++) {
            total = total.add(tgeUnlock[beneficiaries[i]]);
        }

        return total;
    }

    // Lock 7 days 
    function requestWithdraw() public onlyOwner {
        withdrawAt = block.timestamp + 7 days; // TODO: need check time
    }
    
    // need request withdraw and wait 7 days
    // only use when transfer wrong token or emergency
    function withdraw(address _token, address payable _to) external onlyOwner {
        require(withdrawAt > 0 && withdrawAt < block.timestamp, "Cannot withdraw");

        if (_token == address(0x0)) {
            // payable(_to).transfer(address(this).balance);
            (bool success, ) = payable(_to).call{ value: address(this).balance }("");
            require(success, "failed to send ether to owner");
        }
        else {
            IERC20(_token).safeTransfer(_to, IERC20(_token).balanceOf(address(this)));
        }

        withdrawAt = 0;
    }

    function addBeneficiary(address _beneficiary, uint256 _tgeUnlockAmount, uint256 _vestingAmount)
        public
        onlyOwner
    {
        require(
            _beneficiary != address(0),
            "The beneficiary's address cannot be 0"
        );
        require(_vestingAmount > 0, "Shares amount has to be greater than 0");

        if (shares[_beneficiary] == 0) {
            beneficiaries.push(_beneficiary);
        }

        shares[_beneficiary] = shares[_beneficiary].add(_vestingAmount);
        tgeUnlock[_beneficiary] = tgeUnlock[_beneficiary].add(_tgeUnlockAmount);
    }

    function addMultiBeneficiaries(address[] memory _beneficiaries, uint256[] memory _tgeUnlockAmounts, uint256[] memory _vestingAmounts)
        public
        onlyOwner
    {
        for (uint i = 0; i < _beneficiaries.length; i++) {
            addBeneficiary(_beneficiaries[i], _tgeUnlockAmounts[i], _vestingAmounts[i]);
        }
    }

    function calculateReleaseAmount(address _beneficiary) public view returns (uint256) {
        if (block.number < cliff) {
            return 0;
        }
        else if (block.number > start.add(duration)) {
            return shares[_beneficiary].sub(released[_beneficiary]);
        }
        else {
            return shares[_beneficiary].mul(block.number.sub(start))
                .div(duration)
                .sub(released[_beneficiary]);
        }
    }

    function _release(address _beneficiary) private {
        require(shares[_beneficiary] > 0, "Dont have share");
        require(released[_beneficiary] < shares[_beneficiary], "Cannot release more");
        
        uint _releaseAmount = calculateReleaseAmount(_beneficiary);
        require(0 < _releaseAmount, "Have not start or finished");

        uint _newReleasedAmount = released[_beneficiary].add(_releaseAmount);
        require(_newReleasedAmount <= shares[_beneficiary], "Something wrong");

        released[_beneficiary] = _newReleasedAmount;
        totalReleased = totalReleased.add(_releaseAmount);
        
        token.safeTransfer(_beneficiary, _releaseAmount);
        emit Released(_beneficiary, _releaseAmount);
    }

    function release() public {
        _release(msg.sender);
    }

    function releaseFor(address _beneficiary) public onlyOwner {
        _release(_beneficiary);
    }

    function _unlock(address _beneficiary) private {
        require(block.timestamp > TGE, "Cannot unlock right now, please wait!");
        require(tgeUnlock[_beneficiary] > 0, "You cannot unlock");
        uint _amount = tgeUnlock[_beneficiary];

        tgeUnlock[_beneficiary] = 0;
        totalUnlocked = totalUnlocked.add(_amount);

        token.safeTransfer(_beneficiary, _amount);
        emit Unlocked(_beneficiary, _amount);
    }

    function unlock() public {
        _unlock(msg.sender);
    }

    function unlockFor(address _beneficiary) public onlyOwner {
        _unlock(_beneficiary);
    }
}
