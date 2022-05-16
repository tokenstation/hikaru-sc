// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

interface ILPERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}