// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

interface IWeightedPool {
    function swap(
        uint256[] memory balances,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external returns (uint256 amountOut);

    function swapExactOut(
        uint256[] memory balances,
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 maxAmountIn
    ) external returns (uint256 amountIn);

    function joinPool(
        uint256[] memory balances,
        address user,
        uint256[] memory amounts_
    ) external returns(uint256 lpAmount);

    function exitPool(
        uint256[] memory balances,
        address user,
        uint256 lpAmount
    ) external returns (uint256[] memory tokensReceived);

    function exitPoolSingleToken(
        uint256[] memory balances,
        address user,
        uint256 lpAmount,
        address token
    ) external returns (uint256[] memory tokenDeltas);

    function calculateSwap(
        uint256[] memory balances,
        address tokenIn,
        address tokenOut,
        uint256 swapAmount,
        bool exactIn
    ) external view returns(uint256 swapResult, uint256 fee);

    function calculateJoin(
        uint256[] memory balances,
        uint256[] calldata amountsIn
    ) external view returns (uint256 lpAmount);

    function calculateExit(
        uint256[] memory balances,
        uint256 lpAmount
    ) external view returns (uint256[] memory tokensReceived);

    function calculatExitSingleToken(
        uint256[] memory balances,
        uint256 lpAmount,
        address token
    ) external view returns (uint256 amountOut);
}