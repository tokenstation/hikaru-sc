// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for registering weighted pool
// @author tokenstation.dev

pragma solidity 0.8.6;

interface IWeightedVault {
    /**
     * @notice Register pool in weighted vault
     * @param pool Address of pool to register
     * @param tokens Tokens of pool
     * @return registerStatus True if pool was registered, False if it was not registered
     */
    function registerPool(
        address pool,
        address[] memory tokens
    ) external returns (bool registerStatus);
}