// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

import {ConstantProductStruct} from "./ContractProductStruct.sol";

/**
    Implements math described in: https://dev.balancer.fi/resources/pool-math/weighted-math
    This will allow to include multiple (2+) tokens in pair

    This library contains only functions for calculating swap results (dry-run functions)
 */

library ConstantProductMath {
    function swap(
        ConstantProductStruct.ConstantProductParams memory cpp,
        uint8 tokenInId,
        uint8 tokenOutId,
        uint256 amountIn,
        uint256[] memory balances
    ) internal returns (uint256 amountOut, uint256 fee) {
        
    }

    function swapExactOut(
        ConstantProductStruct.ConstantProductParams memory cpp,
        uint8 tokenInId,
        uint8 tokenOutId,
        uint256 amountOut,
        uint256[] memory balances
    ) internal returns (uint256 amountIn, uint256 fee) {

    }
}