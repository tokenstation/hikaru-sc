// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

interface IWeightedPoolVault {
    function registerPool(
        address pool,
        address[] memory tokens,
        uint256[] memory weights,
        uint256 swapFee
    ) external returns (bool registerStatus);
}