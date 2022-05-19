// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

interface ILPTokenFactory {
    function createNewToken(
        address vault,
        string memory name,
        string memory symbol
    ) external returns (address tokenAddress);
}