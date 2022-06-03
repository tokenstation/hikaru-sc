pragma solidity 0.8.6;

import {WeightedMath} from "../../contracts/SwapContracts/WeightedPool/libraries/WeightedMath.sol";
import {FixedPoint} from "../../contracts/utils/Math/FixedPoint.sol";

contract TestMath {
    using FixedPoint for uint256;

    function calculateOutGivenIn(
        uint256 balanceIn, 
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountIn,
        uint256 swapFee
    )
        external
        pure
        returns(uint256)
    {
        uint256 fee = amountIn.mulDown(swapFee);
        amountIn = amountIn - fee;
        return WeightedMath._calcOutGivenIn(balanceIn, weightIn, balanceOut, weightOut, amountIn);
    }

    function calcInGivenOut(
        uint256 balanceIn,
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountOut,
        uint256 swapFee
    )
        external
        pure
        returns (uint256 amountIn)
    {

        amountIn = WeightedMath._calcInGivenOut(balanceIn, weightIn, balanceOut, weightOut, amountOut);
        amountIn = amountIn.divDown(FixedPoint.ONE - swapFee);
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
        uint256 swapFee
    )
        external
        pure
        returns (uint256 lpAmount)
    {
        (lpAmount,) = WeightedMath._calcBptOutGivenExactTokensIn(balances, weights, amounts, totalLP, swapFee);
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
        uint256 swapFee
    )
        external
        pure
        returns (uint256 amountOut)
    {
        (amountOut, ) = WeightedMath._calcTokenOutGivenExactBptIn(
            balance, 
            tokenWeight, 
            lpAmount, 
            totalLP, 
            swapFee
        );
    }
}