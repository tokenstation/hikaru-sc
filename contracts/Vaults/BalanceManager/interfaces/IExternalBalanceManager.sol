// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

interface IExternalBalanceManager {
    function getPoolBalances(
        address pool
    ) external view returns (uint256[] memory poolBalance);

    function getPoolTokenBalance(
        address pool,
        address token
    ) external view returns (uint256 tokenBalance);
}