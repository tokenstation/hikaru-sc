// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interfaces for obtaining pool tokens from vaults
// @author tokenstation.dev

pragma solidity 0.8.6;

interface IVaultPoolInfo {
    /**
     * @notice Get tokens of pool using vault
     * @param pool Address of pool
     * @return tokens Array of pool's tokens
     */
    function getPoolTokens(address pool) external view returns (address[] memory tokens);
}