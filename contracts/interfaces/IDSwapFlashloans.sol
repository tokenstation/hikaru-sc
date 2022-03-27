// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interfaces for swap functions of smart contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

interface IDSwapFlashloans {
    function flashloan(
        uint8 tokenId,
        uint256 amount
    ) external;
}