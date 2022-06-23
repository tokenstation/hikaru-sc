// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;


interface IFullPoolJoin {
    function joinPool(
        address pool,
        uint256[] memory amounts,
        address receiver,
        uint64 deadline
    ) external returns (uint256 lpAmount);

    function calculateJoinPool(
        address pool,
        uint256[] memory amounts
    ) external view returns (uint256 lpAmount);
}

interface IPartialPoolJoin {
    function partialPoolJoin(
        address pool,
        address[] memory tokens,
        uint256[] memory amounts,
        address receiver,
        uint64 deadline
    ) external returns (uint256 lpAmount);

    function calculatePartialPoolJoin(
        address pool,
        address[] memory tokens,
        uint256[] memory amounts
    ) external view returns (uint256 lpAmount);
}

interface IJoinPoolSingleToken {
    function singleTokenPoolJoin(
        address pool,
        address token,
        uint256 amount,
        address receiver,
        uint64 deadline
    ) external returns (uint256 lpAmount);

    function calculateSingleTokenPoolJoin(
        address pool,
        address token,
        uint256 amount
    ) external view returns (uint256 lpAmount);
}
