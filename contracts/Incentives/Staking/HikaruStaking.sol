// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "../../utils/libraries/TokenUtils.sol";
import "./StakingManageable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract HikaruStaking is Manageable {
    using TokenUtils for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many deposit tokens the user has provided.
        uint256 rewardDebt;
        uint256 vested;
        uint256 released;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 depositToken; // Address of deposit token contract
        IERC20 rewardToken; // Address of reward token contract
        uint256 depositedAmount; // number of deposited tokens
        uint256 accRewardPerShare; // Accumulated reward per share, times 1e12. See below.
        uint256 rewardTokenPerSecond; // number of tokens distributed per second between all users in pool
        uint256 rewardTokensToDistribute; // overall sum of reward tokens to distribute across users
        uint256 unclaimedRewardTokens; // reward tokens that could be claimed by admins, because no users pretend to claim it
        uint64 lastRewardTime;  // Last block timestamp that tokens distribution occurs.
        uint64 start; // timestamp when farming starts
        uint64 duration; // duration of farming after start
        uint64 lockTime;
        uint64 vestingStart;
        uint64 vestingDuration;
    }

    // amount of deposited tokens that cannot be withdrawn by admins
    // we need this because 1 token could be used as a reward and deposit at the same time
    mapping (address => uint256) public depositedTokens;
    // amount of reward tokens that cannot be withdrawn by admins
    mapping (address => uint256) public rewardTokens;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes deposit tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    uint256 constant PRECISION_MULTIPLIER = 1e18;

    event Reward(uint256 indexed pid, address indexed user, uint256 amount);
    event Deposit(uint256 indexed pid, address indexed user, uint256 amount);
    event Withdraw(uint256 indexed pid, address indexed user, uint256 amount);
    event WithdrawUnclaimed(uint256 amount);
    event NewPool(
        IERC20 depositToken,
        IERC20 rewardToken,
        uint256 rewardTokensToDistribute,
        uint64 start,
        uint64 duration,
        uint64 lockTime,
        uint256 pid
    );

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /// @notice Add a new farm pool. Can only be called by the staking manager.
    /// Same deposit/reward tokens could be used more than once
    /// @param depositToken_ Token used for users deposits
    /// @param rewardToken_ Token used as a reward for staking in pool
    /// @param rewardTokensToDistribute_ Amount of reward tokens to distribute among users
    /// @param start_ Timestamp when farming starts. Users who deposited before this moment wont be rewarded until start
    /// @param duration_ Interval of farming after start
    /// @param lockTime_ Users wont be able to withdraw deposit tokens during this period after farming start
    /// @param vestingStart_ Timestamp when reward vesting will start
    /// @param vestingDuration_ Interval of reward vesting after start
    function add(
        IERC20 depositToken_,
        IERC20 rewardToken_,
        uint256 rewardTokensToDistribute_,
        uint64 start_,
        uint64 duration_,
        uint64 lockTime_,
        uint64 vestingStart_,
        uint64 vestingDuration_
    ) public onlyStakingManager {
        uint64 lastRewardTime = uint64(block.timestamp) > start_ ? uint64(block.timestamp) : start_;
        rewardTokensToDistribute_ = rewardToken_.transferFromUser(_msgSender(), rewardTokensToDistribute_);
        rewardTokens[address(rewardToken_)] += rewardTokensToDistribute_;

        uint256 rewardTokenPerSecond = rewardTokensToDistribute_ / duration_;
        poolInfo.push(PoolInfo({
            depositToken: depositToken_,
            rewardToken: rewardToken_,
            rewardTokensToDistribute: rewardTokensToDistribute_,
            rewardTokenPerSecond: rewardTokenPerSecond,
            lastRewardTime: lastRewardTime,
            depositedAmount: 0,
            accRewardPerShare: 0,
            unclaimedRewardTokens: 0,
            start: start_,
            duration: duration_,
            lockTime: lockTime_,
            vestingStart: vestingStart_,
            vestingDuration: vestingDuration_
        }));

        emit NewPool(depositToken_, rewardToken_, rewardTokensToDistribute_, start_, duration_, lockTime_, poolInfo.length);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return (_to > _from) ? (_to - _from) : 0;
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid_ The index of the pool. See `poolInfo`.
    function updatePool(uint256 pid_) public {
        PoolInfo storage pool = poolInfo[pid_];
        // pool was updated on this block already or farming not started
        if (uint64(block.timestamp) <= pool.lastRewardTime) {
            return;
        }
        uint256 newReward = _calcNewReward(pool);
        // no stakers, nothing to distribute
        if (pool.depositedAmount == 0) {
            pool.unclaimedRewardTokens += newReward;
            pool.lastRewardTime = uint64(block.timestamp);
            return;
        }
        pool.accRewardPerShare += ((newReward * PRECISION_MULTIPLIER) / pool.depositedAmount);
        pool.lastRewardTime = uint64(block.timestamp);
    }

    function _calcNewReward(PoolInfo storage pool) internal view returns (uint256 _newReward) {
        uint64 farming_end = pool.start + pool.duration;
        uint64 to = uint64(block.timestamp) > farming_end ? farming_end : uint64(block.timestamp);
        uint256 multiplier = getMultiplier(pool.lastRewardTime, to);
         _newReward = multiplier * pool.rewardTokenPerSecond;
    }

    function _calcPendingReward(UserInfo storage user, uint256 accRewardPerShare) internal view returns (uint256 pending) {
        return ((user.amount * accRewardPerShare) / PRECISION_MULTIPLIER) - user.rewardDebt;
    }

    function _calcReleasable(PoolInfo storage pool, uint256 vested, uint256 released) internal view returns (uint256 releasable) {
        if (uint64(block.timestamp) <= pool.vestingStart) {
            return 0;
        } else if (uint64(block.timestamp) >= (pool.vestingStart + pool.vestingDuration)) {
            return vested - released;
        } else {
            return (vested * (uint64(block.timestamp) - pool.vestingStart)) / (pool.vestingDuration) - released;
        }
    }

    /// @notice View function to see pending reward on frontend.
    /// @param pid_ The index of the pool. See `poolInfo`.
    /// @param user_ Address of user.
    function pendingReward(uint256 pid_, address user_) external view returns (uint256 locked, uint256 releasable) {
        PoolInfo storage pool = poolInfo[pid_];
        UserInfo storage user = userInfo[pid_][user_];

        uint256 accRewardPerShare = pool.accRewardPerShare;
        if (uint64(block.timestamp) > pool.lastRewardTime && pool.depositedAmount != 0) {
            uint256 newReward = _calcNewReward(pool);
            accRewardPerShare += (newReward * PRECISION_MULTIPLIER) / pool.depositedAmount;
        }

        uint256 new_vested = user.vested + _calcPendingReward(user, accRewardPerShare);
        releasable = _calcReleasable(pool, new_vested, user.released);
        locked = new_vested - user.released - releasable;
    }

    /// @notice Deposit tokens to contract for reward allocation.
    /// @param pid_ The index of the pool. See `poolInfo`.
    /// @param amount_ LP token amount to deposit.
    function deposit(uint256 pid_, uint256 amount_) external {
        require (amount_ > 0, "HikaruStaking::deposit: amount should be positive");
        PoolInfo storage pool = poolInfo[pid_];
        UserInfo storage user = userInfo[pid_][_msgSender()];
        updatePool(pid_);

        // user deposited something already, transfer reward
        if (user.amount > 0) {
            uint256 pending = _calcPendingReward(user, pool.accRewardPerShare);
            user.vested += pending;
        }

        amount_ = pool.depositToken.transferFromUser(_msgSender(), amount_);
        // update user deposit amount and stats
        user.amount += amount_;
        pool.depositedAmount += amount_;
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / PRECISION_MULTIPLIER;
        depositedTokens[address(pool.depositToken)] += amount_;

        emit Deposit(pid_, _msgSender(), amount_);
    }

    /// @notice Withdraw tokens from contract.
    /// @param pid_ The index of the pool. See `poolInfo`.
    /// @param amount_ Token amount to withdraw.
    function withdraw(uint256 pid_, uint256 amount_) external {
        require (amount_ > 0, "HikaruStaking::withdraw: amount should be positive");

        PoolInfo storage pool = poolInfo[pid_];
        UserInfo storage user = userInfo[pid_][_msgSender()];

        // transfer first to be sure we know exact amount of tokens transferred
        amount_ = pool.depositToken.transferToUser(_msgSender(), amount_);

        require (user.amount >= amount_, "HikaruStaking::withdraw: withdraw amount exceeds balance");
        require (pool.start + pool.lockTime <= uint64(block.timestamp), "HikaruStaking::withdraw: lock is active");

        updatePool(pid_);
        uint256 pending = _calcPendingReward(user, pool.accRewardPerShare);
        user.vested += pending;

        user.amount -= amount_;
        pool.depositedAmount -= amount_;
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / PRECISION_MULTIPLIER;
        depositedTokens[address(pool.depositToken)] -= amount_;

        emit Withdraw(pid_, _msgSender(), amount_);
    }

    /// @notice Harvest pending reward tokens for given pool
    /// @param pid_ The index of the pool. See `poolInfo`.
    function claim(uint256 pid_) external {
        PoolInfo storage pool = poolInfo[pid_];
        UserInfo storage user = userInfo[pid_][_msgSender()];

        updatePool(pid_);
        uint256 pending = _calcPendingReward(user, pool.accRewardPerShare);
        user.vested += pending;

        if (user.vested > 0) {
            uint256 releasable = _calcReleasable(pool, user.vested, user.released);
            user.released += releasable;

            if (releasable > 0) {
                releasable = pool.rewardToken.transferToUser(_msgSender(), releasable);
                rewardTokens[address(pool.rewardToken)] -= releasable;
                emit Reward(pid_, _msgSender(), releasable);
            }
        }

        user.rewardDebt = (user.amount * pool.accRewardPerShare) / PRECISION_MULTIPLIER;
    }

    /// @notice Claim reward tokens that wont be claimed by users.
    /// Could be called only by admin
    /// @param pid_ The index of the pool. See `poolInfo`.
    function pullUnclaimedTokens(uint256 pid_) external onlyAdmin {
        PoolInfo storage pool = poolInfo[pid_];

        updatePool(pid_);
        uint256 _unclaimed = pool.unclaimedRewardTokens;
        require (_unclaimed > 0, "HikaruStaking::pullUnclaimedTokens: zero unclaimed amount");

        pool.unclaimedRewardTokens = 0;
        _unclaimed = pool.rewardToken.transferToUser(_msgSender(), _unclaimed);
        rewardTokens[address(pool.rewardToken)] -= _unclaimed;

        emit WithdrawUnclaimed(_unclaimed);
    }

    /// @notice Claim tokens sent to this contract by mistake. Tokens deposited by users or reward tokens are reserved
    /// @param token_ Token to withdraw
    /// @param amount_ Amount to withdraw
    function sweep(address token_, uint256 amount_) external onlyAdmin {
        uint256 token_balance = IERC20(token_).balanceOf(address(this));

        require (amount_ <= token_balance, "HikaruStaking::sweep: amount exceeds balance");
        require (
            token_balance - amount_ >= depositedTokens[token_] + rewardTokens[token_],
            "HikaruStaking::sweep: cant withdraw reserved tokens"
        );

        IERC20(token_).transferToUser(_msgSender(), amount_);
    }
}