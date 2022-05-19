// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

import { IERC20, IERC20Metadata, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { IWeightedPool } from "./interfaces/IWeightedPool.sol";
import { WeightedMath } from "./libraries/WeightedMath.sol";
import { WeightedStorage } from "./WeightedStorage.sol";
import { BaseWeightedPool } from "./BaseWeightedPool.sol";
import { SingleManager } from "../../utils/SingleManager.sol";

contract WeightedPool is IWeightedPool, BaseWeightedPool, SingleManager {

    // TODO: Check other todo's
    // TODO: refactor contract
    // TODO: add documentation
    // TODO: apply optimisations where possible and it does not obscure code
    // TODO: check real-world gas costs, must be around 100k or less (check how it may be achieved)

    constructor(
        address vault,
        address poolManager_,
        address[] memory tokens_,
        uint256[] memory weights_,
        uint256 swapFee_
    ) 
        WeightedStorage(msg.sender, vault, tokens_, weights_)
        BaseWeightedPool(swapFee_)
        SingleManager(poolManager_)
    { 

    }

    /*************************************************
                      Swap functions
     *************************************************/

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint64 deadline
    ) 
        external
        override
        onlyVault(msg.sender)
        checkDeadline(deadline)
        checkTokens(tokenIn, tokenOut)
        returns (uint256 amountOut)
    {
        (amountOut, ) = _calculateOutGivenIn(
            tokenIn,
            tokenOut,
            amountIn
        );
        require(
            amountOut >= minAmountOut,
            "Not enough tokens received"
        );
        _postSwap(
            tokenIn,
            amountIn,
            tokenOut,
            amountOut
        );
    }

    function swapExactOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 maxAmountIn,
        uint64 deadline
    )
        external
        override
        onlyVault(msg.sender)
        checkDeadline(deadline)
        checkTokens(tokenIn, tokenOut)
        returns (uint256 amountIn)
    {
        (amountIn, ) = _calculateInGivenOut(
            tokenIn, 
            tokenOut, 
            amountIn
        );
        require(
            amountIn <= maxAmountIn,
            "Too much tokens is used for swap"
        );
        _postSwap(
            tokenIn,
            amountIn,
            tokenOut,
            amountOut
        );
    }

    /*************************************************
                    Join/Exit Pool
     *************************************************/

    function joinPool(
        uint256[] memory amounts_,
        uint64 deadline
    )
        external
        override
        onlyVault(msg.sender)
        checkDeadline(deadline)
        returns(uint256 lpAmount)
    {
        require(
            amounts_.length == N_TOKENS,
            "Invalid array size"
        );

        uint256[] memory swapFees;
        (lpAmount, swapFees) = WeightedMath._calcBptOutGivenExactTokensIn(
            balances, 
            _getWeights(), 
            amounts_,
            lpBalance,
            swapFee
        );

        _postJoinExit(lpAmount, amounts_, true);
    }

    function exitPool(
        uint256 lpAmount,
        uint64 deadline
    )
        external
        override
        onlyVault(msg.sender)
        checkDeadline(deadline)
        returns (uint256[] memory tokensReceived)
    {
        tokensReceived = WeightedMath._calcTokensOutGivenExactBptIn(
            balances,
            lpAmount,
            lpBalance
        );

        _postJoinExit(lpAmount, tokensReceived, false);
    }

    function exitPoolSingleToken(
        uint256 lpAmount,
        address token,
        uint64 deadline
    )
        external
        override
        onlyVault(msg.sender)
        checkDeadline(deadline)
        returns (uint256 amountOut, uint256 nTokens, uint256 tokenId)
    {
        nTokens = N_TOKENS;
        tokenId = _getTokenId(token);
        (amountOut, ) = WeightedMath._calcTokenOutGivenExactBptIn(
            balances[tokenId], 
            _getWeight(token), 
            lpAmount, 
            lpBalance, 
            swapFee
        );
        lpBalance -= lpAmount;
    }

    /*************************************************
                    Initialize pool
     *************************************************/

    function initializePool(
        uint256[] memory tokenAmounts,
        uint64 deadline
    )
        external
        onlyVault(msg.sender)
        checkDeadline(deadline)
        returns (uint256 lpAmount)
    {
        require(
            lpBalance == 0,
            "Pool alreadly initialized"
        );
        require(
            tokenAmounts.length == N_TOKENS,
            "Invalid array length"
        );

        uint256[] memory multipliers = _getMultipliers();

        for (uint256 tokenId = 0; tokenId < N_TOKENS; tokenId++) {
            tokenAmounts[tokenId] *= multipliers[tokenId];
        }

        lpAmount = WeightedMath._calculateInvariant(_getWeights(), tokenAmounts);
        balances = tokenAmounts;
    }

    /*************************************************
                      Dry run functions
     *************************************************/

    function calculateSwap(
        address tokenIn,
        address tokenOut,
        uint256 swapAmount,
        bool exactIn
    )
        external
        override
        view
        checkTokens(tokenIn, tokenOut)
        returns(uint256 swapResult, uint256 fee)
    {
        if (exactIn) {
            (swapResult, fee) = _calculateOutGivenIn(
                tokenIn,
                tokenOut,
                swapAmount
            );
        } else {
            (swapResult, fee) = _calculateInGivenOut(
                tokenIn,
                tokenOut,
                swapAmount
            );
        }
        
    }

    function calculateJoin(
        uint256[] calldata amountsIn
    )
        external
        override
        view
        returns (uint256 lpAmount)
    {
        (lpAmount, ) = WeightedMath._calcBptOutGivenExactTokensIn(
            balances, 
            _getWeights(), 
            amountsIn,
            lpBalance,
            swapFee
        );
    }

    function calculateExit(
        uint256 lpAmount
    )
        external
        override
        view
        returns (uint256[] memory tokensReceived)
    {
        tokensReceived = WeightedMath._calcTokensOutGivenExactBptIn(
            balances,
            lpAmount,
            lpBalance
        );
    }

    function calculatExitSingleToken(
        uint256 lpAmount,
        address token
    ) 
        external
        override 
        view 
        returns (uint256 amountOut)
    {
        (amountOut,) = WeightedMath._calcTokenOutGivenExactBptIn(
            balances[_getTokenId(token)], 
            _getWeight(token), 
            lpAmount, 
            lpBalance, 
            swapFee
        );
    }


    /*************************************************
                   Change pool parameters
     *************************************************/

    function setPoolFees(
        uint256 swapFee_
    )
        external
        onlyManager
    {
        _setPoolFees(swapFee_);
    }
}   