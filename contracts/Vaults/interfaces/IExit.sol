// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

interface IFullPoolExit {
    function exitPool(
        address pool,
        uint256 lpAmount,
        address receiver,
        uint64 deadline
    ) external returns (address[] memory tokens, uint256[] memory amounts);

    function calculateExitPool(
        address pool,
        uint256 lpAmount
    ) external view returns (address[] memory tokens, uint256[] memory amounts);
}

interface IPartialPoolExit {
    function partialPoolExit(
        address pool,
        uint256 lpAmount,
        address[] memory tokens,
        address receiver,
        uint64 deadline
    ) external returns (address[] memory tokens_, uint256[] memory amounts);

    function calculatePartialPoolExit(
        address pool,
        uint256 lpAmount,
        address[] memory tokens
    ) external returns (address[] memory tokens_, uint256[] memory amounts);
}   

interface IExitPoolSingleToken {
    function exitPoolSingleToken(
        address pool,
        uint256 lpAmount,
        address token,
        address receiver,
        uint64 deadline
    ) external returns (uint256 receivedAmount);

    function calculateExitPoolSingleToken(
        address pool,
        uint256 lpAmount,
        address token
    ) external view returns (uint256 receivedAmount);
}