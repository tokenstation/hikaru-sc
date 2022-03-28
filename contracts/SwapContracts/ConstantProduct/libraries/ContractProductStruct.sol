// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

library ConstantProductStruct {
    struct ConstantProductParams {
        uint256 feeNominator;
        uint256 feeDenominator;
        address[] tokens;
        uint256[] balances;
        uint256[] multipliers;
        uint256[] weights;
    }
}