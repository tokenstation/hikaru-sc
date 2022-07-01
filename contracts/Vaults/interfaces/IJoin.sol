// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interfaces for providing tokens to pool used by vaults
// @author tokenstation.dev

pragma solidity 0.8.6;


interface IFullPoolJoin {
    /**
     * @notice Join pool using all tokens in pool
     * @param pool Address of pool
     * @param amounts Array with token amounts that will be used for providing tokens
     * @param receiver Who will receive lp tokens
     * @param deadline If block.timestamp is greater than deadline, operation reverts
     * @return lpAmount Amount of lp tokens received
     */
    function joinPool(
        address pool,
        uint256[] memory amounts,
        address receiver,
        uint64 deadline
    ) external returns (uint256 lpAmount);

    /**
     * @notice Calculate amount of LP tokens received by providing amounts of tokens
     * @param pool Address of pool
     * @param amounts Array with token amounts that will be used for providing tokens
     * return lpAmount Amount of lp tokens received
     */
    function calculateJoinPool(
        address pool,
        uint256[] memory amounts
    ) external view returns (uint256 lpAmount);
}

interface IPartialPoolJoin {
    /**
     * @notice Join pool using some tokens of pool
     * @param pool Address of pool
     * @param tokens Array of token addresses used for pool join
     * @param amounts Amounts of tokens to use for join
     * @param receiver Who will receive LP tokens
     * @param deadline If block.timestamp is greater than deadline, operation reverts
     * @return lpAmount Amount of lp tokens recieved
     */
    function partialPoolJoin(
        address pool,
        address[] memory tokens,
        uint256[] memory amounts,
        address receiver,
        uint64 deadline
    ) external returns (uint256 lpAmount);

    /**
     * @notice Calculate amount of LP tokens received by providing amounts of tokens
     * @param pool Address of pool
     * @param tokens Array of token addresses used for pool join
     * @param amounts Amounts of tokens to use for join
     * @return lpAmount Amount of lp tokens recieved
     */
    function calculatePartialPoolJoin(
        address pool,
        address[] memory tokens,
        uint256[] memory amounts
    ) external view returns (uint256 lpAmount);
}

interface IJoinPoolSingleToken {
    /**
     * @notice Join pool using one token of pool
     * @param pool Address of pool
     * @param token Token to use for join
     * @param amount Amount of token to use for join
     * @param receiver Who will receive lp tokens
     * @param deadline If block.timestamp is greater than deadline, operation reverts
     * @return lpAmount Amount of lp tokens received
     */
    function singleTokenPoolJoin(
        address pool,
        address token,
        uint256 amount,
        address receiver,
        uint64 deadline
    ) external returns (uint256 lpAmount);

    /**
     * @notice Calculate amount of LP tokens received by providing amount of token
     * @param pool Address of pool
     * @param token Address of token
     * @param amount Amount of token to provide
     * @return lpAmount Amount of lp tokens received
     */
    function calculateSingleTokenPoolJoin(
        address pool,
        address token,
        uint256 amount
    ) external view returns (uint256 lpAmount);
}
