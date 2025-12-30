// SPDX-License-Identifier: MIT
pragma solidity >0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingVault is ReentrancyGuard, Pausable, Ownable {

    struct StakeInfo {
        uint amount;
        uint stakeTime;
        uint lockPeriod;
        uint lastClaimTime;
        bool active;
    }

    mapping (address => StakeInfo[]) private stakes;

    mapping (uint => uint) public aprByLock;

    uint public constant REWARD_IN_SECONDS = 31536000;

    event Staked (address indexed user, uint amount);
    event Unstaked (address indexed user, uint amount);
    event ClaimedReward (address indexed user, uint amount);
    event OwnerDeposit (address indexed owner, uint amount);
    event Paused (bool status);

    constructor () Ownable(msg.sender) {
        aprByLock[2 minutes] = 5;
        aprByLock[5 minutes] = 10;
        aprByLock[10 minutes] = 15;
        aprByLock[30 minutes] = 20;
    }

    function stake (uint _lockPeriod) external payable whenNotPaused {
        require(msg.value > 0, "send ETH");
        require(aprByLock[_lockPeriod] > 0, "invalid lock period");

        stakes[msg.sender].push(StakeInfo({
            amount: msg.value,
            stakeTime: block.timestamp,
            lockPeriod: _lockPeriod,
            lastClaimTime: block.timestamp,
            active: true
        }));

        emit Staked (msg.sender, msg.value);   
    }

    function ownerDeposit () external payable whenNotPaused onlyOwner {
        require(msg.value > 0, "send ETH");

        emit OwnerDeposit (msg.sender, msg.value);
    }

    receive() external payable {}

    function calculateReward (address _user, uint _index) public view returns (uint) {
        StakeInfo memory s = stakes[_user][_index];

        if (!s.active) {
            return 0;
        }

        uint timeElapsed = block.timestamp - s.lastClaimTime;
        uint targetRate = aprByLock[s.lockPeriod];

        uint numerator = s.amount * targetRate * timeElapsed;
        uint denominator = s.lockPeriod * 100;

        return numerator / denominator;
    }

    function claimRewards (uint _index) external whenNotPaused nonReentrant {
        require(_index < stakes[msg.sender].length, "invalid index");
        StakeInfo storage s = stakes[msg.sender][_index];

        uint reward = calculateReward(msg.sender, _index);

        s.lastClaimTime = block.timestamp;

        (bool ok, ) = payable(msg.sender).call{value: reward}("");
        require(ok, "transaction failed");

        emit ClaimedReward (msg.sender, reward); 
    }

    function unstake (uint _index) external whenNotPaused nonReentrant {
        require(_index < stakes[msg.sender].length, "invalid index");

        StakeInfo storage s = stakes[msg.sender][_index];

        require(s.active, "not staking");
        require(block.timestamp >= s.stakeTime + s.lockPeriod, "too early to unstake");

        uint reward = calculateReward(msg.sender, _index);
        uint totalPayout = s.amount + reward;

        require(address(this).balance >= totalPayout, "contract inslovent");

        s.active = false;
        s.amount = 0;

        (bool ok, ) = payable(msg.sender).call{value: totalPayout}("");
        require(ok, "transaction failed");

        emit Unstaked (msg.sender, totalPayout);
    }

    function getStakeCount (address _user) public view returns (uint) {
        return stakes[_user].length;
    }

    function pause () public onlyOwner {
        _pause();

        emit Paused (true);
    }

    function unpause () public onlyOwner {
        _unpause();

        emit Paused (false);
    }

    function getMyStakes (uint _index) public view returns (uint amount, uint stakeTime, uint lockPeriod, uint lastClaimTime, bool active) {
        StakeInfo memory s = stakes[msg.sender][_index];

        return (s.amount, s.stakeTime, s.lockPeriod, s.lastClaimTime, s.active);
    }
}