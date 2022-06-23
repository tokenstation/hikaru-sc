// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

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

struct VirtualSwapInfo {
    address pool;
    address tokenIn;
    address tokenOut;
}

interface IVirtualSwap {
    function virtualSwap(
        VirtualSwapInfo[] calldata swapRoute,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver,
        uint64 deadline
    ) external returns (uint256 amountOut);

    function calculateVirtualSwap(
        VirtualSwapInfo[] calldata swapRoute,
        uint256 amountIn
    ) external view returns (uint256 amountOut);
}