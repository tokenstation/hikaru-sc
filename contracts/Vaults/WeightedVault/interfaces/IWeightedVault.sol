// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

interface IWeightedVault {
    function registerPool(
        address pool,
        address[] memory tokens
    ) external returns (bool registerStatus);
}