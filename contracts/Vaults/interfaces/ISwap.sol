// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for swapping tokens in pools used by vaults
// @author tokenstation.dev

pragma solidity 0.8.6;

struct SwapRoute {
    address pool;
    address tokenIn;
    address tokenOut;
}

enum SwapType {Sell, Buy}

interface ISwap {
    /**
     * @notice Swap one token to another
     * @param swapRoute Route that specifies how to perform swap
     * @param swapType Sell or Buy tokens
     * @param swapAmount Amount of tokens to sell/buy
     * @param minMaxAmount Minimal amount to receive after swap / maximal amount of tokens to pay
     * @param receiver Who will receive tokens
     * @param deadline Deadline of swap
     */
    function swap(
        SwapRoute[] calldata swapRoute,
        SwapType swapType,
        uint256 swapAmount,
        uint256 minMaxAmount,
        address receiver,
        uint64 deadline
    ) external returns (uint256 swapResult);

    /**
     * @notice Calculate swap with provided swap route
     * @param swapRoute Route that specifies how to perform swap
     * @param swapType Sell or Buy tokens
     * @param swapAmount Amount of tokens to sell/buy
     */
    function calculateSwap(
        SwapRoute[] calldata swapRoute,
        SwapType swapType,
        uint256 swapAmount
    ) external view returns (uint256 swapResult);
}
