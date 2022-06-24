// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining pool balances
// @author tokenstation.dev

pragma solidity 0.8.6;

interface IExternalBalanceManager {
    /**
     * @notice Get pool balances as array
     * @param pool Address of pool
     * @return poolBalances Array with pool balances in it
     */
    function getPoolBalances(
        address pool
    ) external view returns (uint256[] memory poolBalances);

    /**
     * @notice Get pool balances of specific token
     * @dev This function will fail with require() if token is not presented in pool
     * @param pool Adress of pool
     * @param token Address of token
     * @return tokenBalance Pool balance of token
     */
    function getPoolTokenBalance(
        address pool,
        address token
    ) external view returns (uint256 tokenBalance);
}