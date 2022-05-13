// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

interface IWeightedPool {
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint64 deadline
    ) external returns (uint256 amountOut);

    function swapExactOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 maxAmountIn,
        uint64 deadline
    ) external returns (uint256 amountIn);

    function joinPool(
        uint256[] memory amounts_,
        uint64 deadline
    ) external returns(uint256 lpAmount);

    function exitPool(
        uint256 lpAmount,
        uint64 deadline
    ) external returns (uint256[] memory tokensReceived);

    function calculateSwap(
        address tokenIn,
        address tokenOut,
        uint256 swapAmount,
        bool exactIn
    ) external view returns(uint256 swapResult, uint256 fee);

    function calculateJoin(
        uint256[] calldata amountsIn
    ) external view returns (uint256 lpAmount);

    function calculateExit(
        uint256 lpAmount
    ) external view returns (uint256[] memory tokensReceived);
}