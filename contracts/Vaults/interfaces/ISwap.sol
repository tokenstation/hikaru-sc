// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for swapping tokens in pools used by vaults
// @author tokenstation.dev

pragma solidity 0.8.6;

interface ISellTokens {
    /**
     * @notice Sell specified amount of tokens in pool
     * @param pool Address of pool
     * @param tokenIn Token to sell
     * @param tokenOut Token received in result of swap
     * @param sellAmount Amount of tokens to sell
     * @param minAmountOut Minimal amount of tokens to receive as swap result
     * @param receiver Who will receive tokens
     * @param deadline If block.timestamp is greater than deadline, operation reverts
     * @return amountOut Amount of tokens received
     */
    function sellTokens(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 sellAmount,
        uint256 minAmountOut,
        address receiver,
        uint64 deadline
    ) external returns (uint256 amountOut);

    /**
     * @notice Calculate amount of tokens received as swap result
     * @param pool Address of pool
     * @param tokenIn Token used for swap
     * @param tokenOut Token received in result of swap
     * @param sellAmount Amount of tokens to sell
     * @return amountOut Amount of tokens received
     */
    function calculateSellTokens(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 sellAmount
    ) external view returns (uint256 amountOut);
}

interface IBuyTokens {
    /**
     * @notice Sell specified amount of tokens in pool
     * @param pool Address of pool
     * @param tokenIn Token used for swap
     * @param tokenOut Token to buy
     * @param amountToBuy Amount of tokens to buy
     * @param maxAmountIn Maximal amount of tokens used to buy specified amount
     * @param receiver Who will receive tokens
     * @param deadline If block.timestamp is greater than deadline, operation reverts
     * @return amountIn How much user paid
     */
    function buyTokens(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountToBuy,
        uint256 maxAmountIn,
        address receiver,
        uint64 deadline
    ) external returns (uint256 amountIn);

    /**
     * @notice Calculate how much tokens is required to buy specified amount
     * @param pool Address of pool
     * @param tokenIn Token used for swap
     * @param tokenOut Token to buy
     * @param amountOut Amount of tokens to buy
     * @return amountIn Amount required to pay
     */
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
    /**
     * @notice Perform virtual swap (one+ swaps without transferring tokens in transit pools)
     * @dev We need to swap A -> C, but only have pools with A <-> B and B <-> C
     * @dev So we transfer token A from user, perform wirtual swaps A -> B in first pool
     * @dev B -> C in the second pool (using obtained tokens) and transfer token C to user
     * @param swapRoute Swap path that will be used
     * @param amountIn Initial amount of tokens to use for swap
     * @param minAmountOut Minimal result amount of tokens
     * @param receiver Who will receive tokens
     * @param deadline If block.timestamp is greater than deadline, operation reverts
     * @return amountOut Amount of tokens received as swap result
     */
    function virtualSwap(
        VirtualSwapInfo[] calldata swapRoute,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver,
        uint64 deadline
    ) external returns (uint256 amountOut);

    /**
     * @notice Calculate virtual swap result
     * @dev This function may produce incorrect results if pool addresses are duplicated
     * @param swapRoute Swap path that will be used
     * @param amountIn Initial amount of tokens to use for swap
     * @return amountOut Amount of tokens received as swap result
     */
    function calculateVirtualSwap(
        VirtualSwapInfo[] calldata swapRoute,
        uint256 amountIn
    ) external view returns (uint256 amountOut);
}