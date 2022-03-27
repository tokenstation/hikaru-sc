// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interfaces for swap functions of smart contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

interface IDSwap {
    function swap(
        uint8 tokenInId,
        uint8 tokenOutId,
        uint256 swapAmount,
        uint256 minOutAmount,
        uint64 deadline
    ) external;

    function drySwap(
        uint8 tokenInId,
        uint8 tokenOutId,
        uint256 swapAmount
    ) external;
}

interface IDSwapExtended {
    function swapExactOut(
        uint8 tokenInId,
        uint8 tokenOutId,
        uint256 toReceive,
        uint256 maxInAmount,
        uint64 deadline
    ) external;

    function drySwapExactOut(
        uint8 tokenInId,
        uint8 tokenOutId,
        uint256 toReceive
    ) external;
}