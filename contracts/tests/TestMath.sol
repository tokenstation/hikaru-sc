// SPDX-License-Identifier: GPL-3.0-or-later
// @author tokenstation.dev

pragma solidity 0.8.6;

import {WeightedMath} from "../../contracts/SwapContracts/WeightedPool/libraries/WeightedMath.sol";
import {FixedPoint} from "../../contracts/utils/Math/FixedPoint.sol";

contract TestMath {
    using FixedPoint for uint256;

    function calcOutGivenIn(
        uint256 balanceIn, 
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountIn,
        uint256 swapFee,
        uint256 protocolFee
    )
        external
        pure
        returns(uint256 amountOut, uint256 fee, uint256 pf, int256[] memory balanceChanges)
    {
        fee = amountIn.mulDown(swapFee);
        uint256 amountInWithoutFee = amountIn - fee;
        amountOut = WeightedMath._calcOutGivenIn(balanceIn, weightIn, balanceOut, weightOut, amountInWithoutFee);
        pf = fee.mulDown(protocolFee);
        fee = fee - pf;
        balanceChanges = new int256[](2);
        balanceChanges[0] = int256(amountIn - pf);
        balanceChanges[1] = -int256(amountOut);
    }

    function calcInGivenOut(
        uint256 balanceIn,
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountOut,
        uint256 swapFee,
        uint256 protocolFee
    )
        external
        pure
        returns (uint256 amountIn, uint256 fee, uint256 pf, int256[] memory balanceChanges)
    {
        amountIn = WeightedMath._calcInGivenOut(balanceIn, weightIn, balanceOut, weightOut, amountOut);
        uint256 amountInWithFee = amountIn.divDown(FixedPoint.ONE - swapFee);
        fee = amountInWithFee - amountIn;
        amountIn = amountInWithFee;
        pf = fee.mulDown(protocolFee);
        fee = fee - pf;
        balanceChanges = new int256[](2);
        balanceChanges[0] = int256(amountIn - pf);
        balanceChanges[1] = -int256(amountOut);
    }

    function calcInitialization(
        uint256[] memory amounts,
        uint256[] memory weights
    )
        external
        pure
        returns (uint256)
    {
        return WeightedMath._calculateInvariant(weights, amounts);
    }

    function calcJoin(
        uint256[] memory amounts,
        uint256[] memory balances,
        uint256[] memory weights,
        uint256 totalLP,
        uint256 swapFee,
        uint256 protocolFee
    )
        external
        pure
        returns (uint256 lpAmount, uint256[] memory fee, uint256[] memory pf, int256[] memory balanceChanges)
    {
        (lpAmount, fee) = WeightedMath._calcBptOutGivenExactTokensIn(balances, weights, amounts, totalLP, swapFee);
        pf = new uint256[](fee.length);
        for (uint256 id = 0; id < fee.length; id++) {
            pf[id] = fee[id].mulDown(protocolFee);
        }
        balanceChanges = new int256[](balances.length);
        for (uint256 id = 0; id < balances.length; id++) {
            balanceChanges[id] = int256(amounts[id] - pf[id]);
        }
    }

    function calcExit(
        uint256[] memory balances,
        uint256 lpAmount,
        uint256 totalLP
    )
        external
        pure
        returns (uint256[] memory tokensOut)
    {
        tokensOut = WeightedMath._calcTokensOutGivenExactBptIn(balances, lpAmount, totalLP);
    }

    function calcExitSingleToken(
        uint256 balance,
        uint256 tokenWeight,
        uint256 lpAmount,
        uint256 totalLP,
        uint256 swapFee,
        uint256 protocolFee
    )
        external
        pure
        returns (uint256 amountOut, uint256 fee, uint256 pf, int256 balanceChange)
    {
        (amountOut, fee) = WeightedMath._calcTokenOutGivenExactBptIn(
            balance, 
            tokenWeight, 
            lpAmount, 
            totalLP, 
            swapFee
        );
        pf = fee.mulDown(protocolFee);
        balanceChange = -int256(amountOut + pf);
    }
}