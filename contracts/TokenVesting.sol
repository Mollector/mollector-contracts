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
    mapping(address => uint256) public unlocked;

    uint256 public totalReleased = 0;
    uint256 public totalUnlocked = 0;

    address[] public beneficiaries;

    uint public withdrawAt = 0;
    bool public lockedSetting = false;

    uint public constant PRIVATE_SALE = 1;
    uint public constant ADVISOR = 2;
    uint public constant TEAM = 3;
    uint public constant MARKETING = 4;
    uint public constant ECOSYSTEM = 5;
    uint public poolFor;


    /**
    TGE Public: 1648630800
    TGE Private: 1648717200
     */

    constructor(uint _poolFor) {
        poolFor = _poolFor;
        if (poolFor == PRIVATE_SALE) {
            _init(
                address(0x06597FFaFD82E66ECeD9209d539032571ABD50d9),
                1648717200, //tge private 9AM UTC 31/03/2022
                90 days, // cliff
                730 days // duration
            );
            // _addBeneficiary later
        }
        else if (poolFor == ADVISOR) {
            _init(
                address(0x06597FFaFD82E66ECeD9209d539032571ABD50d9),
                1648717200, //tge private 9AM UTC 31/03/2022
                365 days, // cliff
                1460 days // duration
            );
            // _addBeneficiary later
        }
        else if (poolFor == TEAM) {
            _init(
                address(0x06597FFaFD82E66ECeD9209d539032571ABD50d9),
                1648717200, //tge private 9AM UTC 31/03/2022
                365 days, // cliff
                1460 days // duration
            );
            _addBeneficiary(
                msg.sender, 
                0, // 0% at TGE of 200,000,000
                200000000e18 // vestin in 1460 days
            );
        }
        else if (poolFor == MARKETING) {
            _init(
                address(0x06597FFaFD82E66ECeD9209d539032571ABD50d9),
                1648717200, //tge private 9AM UTC 31/03/2022
                90 days, // cliff
                730 days // duration
            );
            _addBeneficiary(
                msg.sender, 
                1250000e18, // 5% at TGE of 250,000,000
                250000000e18 - 1250000e18 // the rest vesting in 730 days
            );
        }
        else if (poolFor == ECOSYSTEM) {
            _init(
                address(0x06597FFaFD82E66ECeD9209d539032571ABD50d9),
                1648717200, //tge private 9AM UTC 31/03/2022
                0 days, // cliff
                730 days // duration
            );
            _addBeneficiary(
                msg.sender, 
                1250000e18, // 5% at TGE of 250,000,000
                250000000e18 - 1250000e18 // the rest vesting in 730 days
            );
        }
    }

    function lockSetting() public onlyOwner {
        lockedSetting = true;
    }

    function _init(address _token,
        uint256 _tge,
        uint256 _cliff,
        uint256 _duration) private {
        require(!lockedSetting, "Cannot update");
        require(
            _cliff <= _duration,
            "Cliff has to be lower or equal to duration"
        );

        token = IERC20(_token);
        TGE = _tge;
        start = _tge;

        cliff = start.add(_cliff);
        duration = _duration;
    }


    function _addBeneficiary(address _beneficiary, uint256 _tgeUnlockAmount, uint256 _vestingAmount)
        private
    {
        require(!lockedSetting, "Cannot update");
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

    function init(address _token,
        uint256 _tge,
        uint256 _cliff,
        uint256 _duration) public onlyOwner {
        _init(_token, _tge, _cliff, _duration);
    }

    // time lock 2 days before withdraw
    function requestWithdraw() public onlyOwner {
        withdrawAt = block.timestamp + 2 days; // TODO: need check time
    }
    
    // need request withdraw and wait 2 days
    // only use when transfer wrong token or emergency
    function withdraw(address _token, address payable _to) external onlyOwner {
        require(withdrawAt > 0 && withdrawAt < block.timestamp, "Cannot withdraw");

        if (_token == address(0x0)) {
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
        _addBeneficiary(_beneficiary, _tgeUnlockAmount, _vestingAmount);
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
        if (block.timestamp < cliff) {
            return 0;
        }
        else if (block.timestamp > start.add(duration)) {
            return shares[_beneficiary].sub(released[_beneficiary]);
        }
        else {
            return shares[_beneficiary].mul(block.timestamp.sub(start))
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
        unlocked[_beneficiary] = unlocked[_beneficiary].add(_amount);
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

    function unlockAndRelease() public {
        _unlock(msg.sender);
        _release(msg.sender);
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
}
