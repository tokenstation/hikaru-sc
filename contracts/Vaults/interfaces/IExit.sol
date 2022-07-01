// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interfaces for exiting from pool used by vaults
// @author tokenstation.dev

pragma solidity 0.8.6;

interface IFullPoolExit {
    /**
     * @notice Exit from pool using all tokens of pool
     * @param pool Address of pool
     * @param lpAmount Amount of LP tokens to burn
     * @param receiver Who will receive tokens
     * @param deadline If block.timestamp is greater than deadline, operation reverts
     * @return tokens Addresses of tokens that were transferred
     * @return amounts Amount of tokens transferred to receiver
     */
    function exitPool(
        address pool,
        uint256 lpAmount,
        address receiver,
        uint64 deadline
    ) external returns (address[] memory tokens, uint256[] memory amounts);

    /**
     * @notice Calculate amount of tokens received by burning lp tokens
     * @param pool Address of pool
     * @param lpAmount Amount of LP tokens to burn
     * @return tokens Addresses of tokens that were transferred
     * @return amounts Amount of tokens transferred to receiver
     */
    function calculateExitPool(
        address pool,
        uint256 lpAmount
    ) external view returns (address[] memory tokens, uint256[] memory amounts);
}

interface IPartialPoolExit {
    /**
     * @notice Exit from pool using only provided tokens
     * @dev Amount of tokens must be at least 2, for single-token exit use IExitPoolSingleToken interface
     * @param pool Address of pool
     * @param lpAmount Amount of LP tokens to burn
     * @param tokens Array of tokens to use for exit
     * @param receiver Who will receive tokens
     * @param deadline If block.timestamp is greater than deadline, operation reverts
     * @return tokens_ Addresses of tokens that were transferred
     * @return amounts Amount of tokens transferred to receiver
     */
    function partialPoolExit(
        address pool,
        uint256 lpAmount,
        address[] memory tokens,
        address receiver,
        uint64 deadline
    ) external returns (address[] memory tokens_, uint256[] memory amounts);

    /**
     * @notice Calculate amount of tokens received on exit
     * @param pool Address of pool
     * @param lpAmount Amount of LP tokens to burn
     * @param tokens Array of tokens to use for exit
     * @return tokens_ Addresses of tokens that were transferred
     * @return amounts Amount of tokens transferred to receiver
     */
    function calculatePartialPoolExit(
        address pool,
        uint256 lpAmount,
        address[] memory tokens
    ) external view returns (address[] memory tokens_, uint256[] memory amounts);
}   

interface IExitPoolSingleToken {
    /**
     * @notice Exit from pool using only one provided token
     * @param pool Address of pool
     * @param lpAmount Amount of LP tokens to burn
     * @param token Address of token to use for exit
     * @param receiver Who will receive token transfer
     * @param deadline If block.timestamp is greater than deadline, operation reverts
     * @return receivedAmount Amount of tokens transferred to receiver
     */
    function exitPoolSingleToken(
        address pool,
        uint256 lpAmount,
        address token,
        address receiver,
        uint64 deadline
    ) external returns (uint256 receivedAmount);

    /**
     * @notice Calculate amount of token received on burning LP tokens
     * @param pool Address of pool
     * @param lpAmount Amount of LP tokens to burn
     * @param token Address of token to use for exit
     * @return receivedAmount Amount of tokens transferred to receiver
     */
    function calculateExitPoolSingleToken(
        address pool,
        uint256 lpAmount,
        address token
    ) external view returns (uint256 receivedAmount);
}