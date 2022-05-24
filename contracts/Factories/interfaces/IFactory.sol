// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

interface IFactory {
    function getPoolById(uint256 poolId) external view returns(address poolAddress);
    function checkPoolAddress(address poolAddress) external view returns(bool poolExists);
}