
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardPool is Ownable {
    IERC20 public stakeToken;
    IERC20 public rewardToken;

    uint256 public rewardRate = 1e18; // 1 EURC par seconde (par token staké)

    struct Staker {
        uint256 balance;
        uint256 rewardDebt;
        uint256 lastUpdate;
    }

    mapping(address => Staker) public stakers;

    constructor(address _stakeToken, address _rewardToken) Ownable(msg.sender) {
        stakeToken = IERC20(_stakeToken);
        rewardToken = IERC20(_rewardToken);
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Zero deposit");
        _updateRewards(msg.sender);
        stakeToken.transferFrom(msg.sender, address(this), amount);
        stakers[msg.sender].balance += amount;
    }

    function withdraw(uint256 amount) external {
        require(stakers[msg.sender].balance >= amount, "Not enough staked");
        _updateRewards(msg.sender);
        stakers[msg.sender].balance -= amount;
        stakeToken.transfer(msg.sender, amount);
    }

    function claimRewards() external {
        _updateRewards(msg.sender);
        uint256 reward = stakers[msg.sender].rewardDebt;
        require(reward > 0, "No rewards");
        stakers[msg.sender].rewardDebt = 0;
        rewardToken.transfer(msg.sender, reward);
    }

    function _updateRewards(address user) internal {
        Staker storage s = stakers[user];
        if (s.lastUpdate > 0) {
            uint256 timeDiff = block.timestamp - s.lastUpdate;
            uint256 reward = timeDiff * s.balance * rewardRate / 1e18;
            s.rewardDebt += reward;
        }
        s.lastUpdate = block.timestamp;
    }

    function fundRewards(uint256 amount) external onlyOwner {
        rewardToken.transferFrom(msg.sender, address(this), amount);
    }

    function setRewardRate(uint256 _rate) external onlyOwner {
        rewardRate = _rate;
    }
}
