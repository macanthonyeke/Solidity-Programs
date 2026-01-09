// SPDX-License-Identifier: MIT
pragma solidity >0.8.18;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StakingVault is ReentrancyGuard, Pausable, Ownable {

    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    uint public constant REWARD_IN_SECONDS = 31536000;

    struct StakeInfo {
        uint stakeTime;
        uint amount;
        uint lockPeriod;
        uint lastClaimTime;
        bool active;
    }

    mapping (address => StakeInfo[]) private stakes;
    mapping (uint => uint) public aprByLock;

    event Staked (address indexed user, uint amount);
    event Unstaked (address indexed user, uint amount, uint reward);
    event ClaimedReward (address indexed user, uint amount);
    event OwnerDeposit (address indexed owner, uint amount);

    constructor (address _stakingToken) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        aprByLock[120] = 5;
        aprByLock[300] = 10;
        aprByLock[420] = 15;
        aprByLock[600] = 20;  
    }

    function stake (uint _amount, uint _lockPeriod) external whenNotPaused nonReentrant {
        require(_amount > 0, "cannot stake 0");
        require(aprByLock[_lockPeriod] > 0, "invalid lock period");

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        stakes[msg.sender].push(StakeInfo({
            stakeTime: block.timestamp,
            amount: _amount,
            lockPeriod: _lockPeriod,
            lastClaimTime: block.timestamp,
            active: true
        }));

        emit Staked (msg.sender, _amount);
    }

    // receive () external payable {
    //     revert ("use stake()");
    // }

    function calculateReward (address _user, uint _index) public view returns (uint) {
        StakeInfo memory s = stakes[_user][_index];

        if (!s.active) {
            return 0;
        }

        uint percentage = aprByLock[s.lockPeriod];

        return (s.amount * percentage) / 100;
    }

    function unstake (uint _index) external whenNotPaused nonReentrant {
        require(_index < stakes[msg.sender].length, "invalid stake index");

        StakeInfo storage s = stakes[msg.sender][_index];

        require(s.active, "not active");
        require(block.timestamp > s.stakeTime + s.lockPeriod, "too early");

        uint reward = calculateReward(msg.sender, _index);
        uint totalPayout = s.amount + reward;

        // require(address(this).balance >= totalPayout, "contract insolvent");

        s.amount = 0;
        s.active = false;

        stakingToken.safeTransfer(msg.sender, totalPayout);

        emit Unstaked (msg.sender, s.amount, reward);
    }

    function pause () external onlyOwner {
        _pause();
    }

    function unpause () external onlyOwner {
        _unpause();
    }
}