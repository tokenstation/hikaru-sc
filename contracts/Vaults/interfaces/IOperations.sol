// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;


// This interface is used to perform default functions that are similar between all Vaults
// Currently only swaps are the same between all Vaults
// This function must provide default interface that can be used for swaps
// Vaults can implement some special functions for operations

import "./IExit.sol";
import "./IJoin.sol";
import "./ISwap.sol";