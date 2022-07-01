// SPDX-License-Identifier: GPL-3.0-or-later
// @title Base interface for factory contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

interface IFactory {
    /**
     * @notice Check if pool was created by the factory
     * @param poolAddress This address is used to check if it was deployed by factory
     * @return poolExists If contract was deployed by factory - true, else - false
     */
    function checkPoolAddress(address poolAddress) external view returns(bool poolExists);
}