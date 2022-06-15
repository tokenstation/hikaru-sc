// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { ISellTokens, IBuyTokens, IFullPoolJoin, IPartialPoolJoin, IFullPoolExit, IExitPoolSingleToken } from "../interfaces/IOperations.sol";
import { WeightedVaultPoolOperations } from "./WeightedVaultPoolOperations.sol";
import { IWeightedStorage } from "../../SwapContracts/WeightedPool/interfaces/IWeightedStorage.sol";
import { IWeightedPool } from "../../SwapContracts/WeightedPool/interfaces/IWeightedPool.sol";

abstract contract WeightedOperations is 
    ISellTokens, 
    IBuyTokens, 
    IFullPoolJoin, 
    IPartialPoolJoin, 
    IFullPoolExit, 
    IExitPoolSingleToken,
    WeightedVaultPoolOperations 
{
    constructor (
        address weightedPoolFactory_
    ) 
        WeightedVaultPoolOperations(weightedPoolFactory_)
    {
        
    }

    function sellTokens(
        address pool, 
        address tokenIn, 
        address tokenOut, 
        uint256 sellAmount, 
        uint256 minAmountOut, 
        address receiver, 
        uint64 deadline
    )
        external
        override
        returns (uint256 amountOut)
    {
        _preOpChecks(pool, deadline);
        amountOut = _swap(
            pool, 
            tokenIn, 
            tokenOut, 
            sellAmount, 
            minAmountOut, 
            receiver,
            true
        );
    }

    function calculateSellTokens(
        address pool, 
        address tokenIn, 
        address tokenOut, 
        uint256 swapAmount
    )
        external
        override
        view
        returns (uint256 amountOut)
    {
        (amountOut, ) = _calculateSwap(pool, tokenIn, tokenOut, swapAmount, true);
    }

    function buyTokens(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountToBuy,
        uint256 maxAmountIn,
        address receiver,
        uint64 deadline
    ) 
        external
        override
        returns (uint256 amountIn)
    {
        _preOpChecks(pool, deadline);
        amountIn = _swap(
            pool, 
            tokenIn, 
            tokenOut, 
            amountToBuy, 
            maxAmountIn, 
            receiver,
            false
        );
    }

    function calculateBuyTokens(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) 
        external
        override
        view 
        returns (uint256 amountIn)
    {
        (amountIn, ) = _calculateSwap(pool, tokenIn, tokenOut, amountOut, false);
    }   

    function joinPool(
        address pool,
        uint256[] memory amounts,
        address receiver,
        uint64 deadline
    ) 
        external
        override 
        returns (uint256 lpAmount)
    {
        _preOpChecks(pool, deadline);
        return _joinPool(pool, amounts, receiver);
    }

    function calculateJoinPool(
        address pool,
        uint256[] memory amounts
    )   
        external
        override 
        view 
        returns (uint256 lpAmount)
    {
        uint256[] memory balances = _getPoolBalances(pool);
        lpAmount = IWeightedPool(pool).calculateJoin(balances, amounts);
    }


    function partialPoolJoin(
        address pool,
        address[] memory tokens,
        uint256[] memory amounts,
        address receiver,
        uint64 deadline
    ) 
        external
        override 
        returns (uint256 lpAmount)
    {
        _preOpChecks(pool, deadline);
        return _joinPool(
            pool, 
            _createAmountsArrayFromTokens(pool, tokens, amounts),
            receiver
        );
    }

    function calculatePartialPoolJoin(
        address pool,
        address[] memory tokens,
        uint256[] memory amounts
    ) 
        external
        override 
        view 
        returns (uint256 lpAmount)
    {
        uint256[] memory balances = _getPoolBalances(pool);
        lpAmount = IWeightedPool(pool).calculateJoin(
            balances, 
            _createAmountsArrayFromTokens(pool, tokens, amounts)
        );
    }

    function exitPool(
        address pool,
        uint256 lpAmount,
        address receiver,
        uint64 deadline
    ) 
        external
        override 
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        _preOpChecks(pool, deadline);
        IWeightedStorage poolStorage = IWeightedStorage(pool);
        amounts = _exitPool(pool, lpAmount, receiver);
        tokens = poolStorage.getTokens();
    }

    function calculateExitPool(
        address pool,
        uint256 lpAmount
    ) 
        external
        override 
        view 
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        uint256[] memory balances = _getPoolBalances(pool);
        amounts = IWeightedPool(pool).calculateExit(balances, lpAmount);
        tokens = IWeightedStorage(pool).getTokens();
    }

    function exitPoolSingleToken(
        address pool,
        uint256 lpAmount,
        address token,
        address receiver,
        uint64 deadline
    ) 
        external
        override 
        returns (uint256 receivedAmount)
    {
        _preOpChecks(pool, deadline);
        return _exitPoolSingleToken(pool, lpAmount, token, receiver);
    }

    function calculateExitPoolSingleToken(
        address pool,
        uint256 lpAmount,
        address token
    ) 
        external
        override 
        view 
        returns (uint256 receivedAmount)
    {
        uint256[] memory balances = _getPoolBalances(pool);
        return IWeightedPool(pool).calculatExitSingleToken(balances, lpAmount, token);
    }
}
