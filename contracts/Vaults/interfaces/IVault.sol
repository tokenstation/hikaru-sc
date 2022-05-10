// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;


// This interface is used to perform default functions that are similar between all Vaults
// Currently only swaps are the same between all Vaults
// This function must provide default interface that can be used for swaps
// Vaults can implement some special functions for operations

interface IVault {
    function defaultSwap(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 swapAmount,
        uint256 minAmountOut,
        uint64 deadline
    ) external returns (uint256 swapResult);

    function calculateDefaultSwap(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 swapAmount
    ) external view returns (uint256 swapResult, uint256 feeAmount);
}