// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

interface IWeightedVault {
    function registerPool(
        address pool,
        address[] memory tokens
    ) external returns (bool registerStatus);

    function transferFromUser(
        address pool,
        address token,
        address amount
    ) external returns (bool status);

    function transferToUser(
        address pool,
        address token,
        address amount
    ) external returns (bool status);
}

interface IWeightedVaultSwaps {
    function swap(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint64 deadline
    ) external returns (uint256 amountOut);

    function swapExactOut(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 maxAmountIn,
        uint64 deadline
    ) external returns (uint256 amountIn);

    function joinPool(
        address pool,
        uint256[] memory amounts_,
        uint64 deadline
    ) external returns(uint256 lpAmount);

    function exitPool(
        address pool,
        uint256 lpAmount,
        uint64 deadline
    ) external returns (uint256[] memory tokensReceived);

    function calculateSwap(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 swapAmount,
        bool exactIn
    ) external view returns(uint256 swapResult, uint256 fee);

    function calculateJoin(
        address pool,
        uint256[] calldata amountsIn
    ) external view returns (uint256 lpAmount);

    function calculateExit(
        address pool,
        uint256 lpAmount
    ) external view returns (uint256[] memory tokensReceived);
}