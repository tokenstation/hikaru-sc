// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

interface IWeightedPoolLP {
    function mint(address user, uint256 amount) external;
    function burn(address user, uint256 amount) external;
}