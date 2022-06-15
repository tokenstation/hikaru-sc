// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;


// This interface is used to perform default functions that are similar between all Vaults
// Currently only swaps are the same between all Vaults
// This function must provide default interface that can be used for swaps
// Vaults can implement some special functions for operations

interface ISellTokens {
    function sellTokens(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 sellAmount,
        uint256 minAmountOut,
        address receiver,
        uint64 deadline
    ) external returns (uint256 amountOut);

    function calculateSellTokens(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 swapAmount
    ) external view returns (uint256 amountOut);
}

interface IBuyTokens {
    function buyTokens(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountToBuy,
        uint256 maxAmountIn,
        address receiver,
        uint64 deadline
    ) external returns (uint256 amountIn);

    function calculateBuyTokens(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) external view returns (uint256 amountIn);
}

interface IFullPoolJoin {
    function joinPool(
        address pool,
        uint256[] memory amounts,
        address receiver,
        uint64 deadline
    ) external returns (uint256 lpAmount);

    function calculateJoinPool(
        address pool,
        uint256[] memory amounts
    ) external view returns (uint256 lpAmount);
}

interface IPartialPoolJoin {
    function partialPoolJoin(
        address pool,
        address[] memory tokens,
        uint256[] memory amounts,
        address receiver,
        uint64 deadline
    ) external returns (uint256 lpAmount);

    function calculatePartialPoolJoin(
        address pool,
        address[] memory tokens,
        uint256[] memory amounts
    ) external view returns (uint256 lpAmount);
}

interface IFullPoolExit {
    function exitPool(
        address pool,
        uint256 lpAmount,
        address receiver,
        uint64 deadline
    ) external returns (address[] memory tokens, uint256[] memory amounts);

    function calculateExitPool(
        address pool,
        uint256 lpAmount
    ) external view returns (address[] memory tokens, uint256[] memory amounts);
}

interface IPartialPoolExit {
    function partialPoolExit(
        address pool,
        uint256 lpAmount,
        address[] memory tokens,
        address receiver,
        uint64 deadline
    ) external returns (address[] memory tokens_, uint256[] memory amounts);

    function calculatePartialPoolExit(
        address pool,
        uint256 lpAmount,
        address[] memory tokens
    ) external returns (address[] memory tokens_, uint256[] memory amounts);
}   

interface IExitPoolSingleToken {
    function exitPoolSingleToken(
        address pool,
        uint256 lpAmount,
        address token,
        address receiver,
        uint64 deadline
    ) external returns (uint256 receivedAmount);

    function calculateExitPoolSingleToken(
        address pool,
        uint256 lpAmount,
        address token
    ) external view returns (uint256 receivedAmount);
}