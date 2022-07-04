// SPDX-License-Identifier: GPL-3.0-or-later
// @title Reentrancy guard contract
// @author tokenstation.dev

pragma solidity 0.8.6;

import "./Errors/ErrorLib.sol";

contract ReentrancyGuard {
    uint256 constant internal LOCK = 1;
    uint256 constant internal UNLOCK = 0;
    uint256 state;

    modifier reentrancyGuard() {
        _require(
            state == UNLOCK,
            Errors.REENTRANCY
        );
        state = LOCK;
        _;
        state = UNLOCK;
    }
}