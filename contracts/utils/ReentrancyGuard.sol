// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

contract ReentrancyGuard {
    uint256 constant internal LOCK = 1;
    uint256 constant internal UNLOCK = 0;
    uint256 state;

    modifier reentrancyGuard() {
        require(
            state == UNLOCK,
            "Reentrancy attempt"
        );
        state = LOCK;
        _;
        state = UNLOCK;
    }
}