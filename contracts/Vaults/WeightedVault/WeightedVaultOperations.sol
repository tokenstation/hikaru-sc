// SPDX-License-Identifier: GPL-3.0-or-later
// @title Contract implementing default interfaces
// @author tokenstation.dev

pragma solidity 0.8.6;

import { ISellTokens, IBuyTokens, IVirtualSwap, VirtualSwapInfo } from "../interfaces/ISwap.sol";
import { IFullPoolJoin, IPartialPoolJoin, IJoinPoolSingleToken } from "../interfaces/IJoin.sol";
import { IFullPoolExit, IExitPoolSingleToken } from "../interfaces/IExit.sol";
import { WeightedVaultPoolOperations } from "./WeightedVaultPoolOperations.sol";
import { IWeightedStorage } from "../../SwapContracts/WeightedPool/interfaces/IWeightedStorage.sol";
import { IWeightedPool } from "../../SwapContracts/WeightedPool/interfaces/IWeightedPool.sol";

abstract contract WeightedOperations is 
    ISellTokens, 
    IBuyTokens, 
    IVirtualSwap,
    IFullPoolJoin, 
    IPartialPoolJoin, 
    IJoinPoolSingleToken,
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

    /**
     * @inheritdoc ISellTokens
     */
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

    /**
     * @inheritdoc ISellTokens
     */
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
        amountOut = _calculateSwap(pool, tokenIn, tokenOut, swapAmount, true);
    }

    /**
     * @inheritdoc IBuyTokens
     */
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

    /**
     * @inheritdoc IBuyTokens
     */
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
        amountIn = _calculateSwap(pool, tokenIn, tokenOut, amountOut, false);
    }   

    /**
     * @inheritdoc IVirtualSwap
     */
    function virtualSwap(
        VirtualSwapInfo[] calldata swapRoute, 
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver,
        uint64 deadline
    ) 
        external
        override
        returns (uint256 amountOut)
    {
        _deadlineCheck(deadline);
        amountOut = _virtualSwap(
            swapRoute,
            amountIn,
            minAmountOut,
            receiver
        );
    }

    // CAUTION!
    // This function will provide correct result only
    // When there are no pool duplication
    /**
     * @inheritdoc IVirtualSwap
     */
    function calculateVirtualSwap(
        VirtualSwapInfo[] calldata swapRoute,
        uint256 amountIn
    )
        external
        override
        view
        returns (uint256 amountOut)
    {
        amountOut = amountIn;
        VirtualSwapInfo memory currentSwap;
        for (uint256 id = 0; id < swapRoute.length; id++) {
            if (
                (id != swapRoute.length - 1) && 
                (swapRoute.length != 1)
            ) {
                require(
                    currentSwap.tokenOut == swapRoute[id+1].tokenIn,
                    "Route contains mismatched tokens"
                );
            }
            currentSwap = swapRoute[id];
            amountOut = _calculateSwap(
                currentSwap.pool, 
                currentSwap.tokenIn, 
                currentSwap.tokenOut, 
                amountOut, 
                true
            );
        }
    }

    /**
     * @inheritdoc IFullPoolJoin
     */
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

    /**
     * @inheritdoc IFullPoolJoin
     */
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

    /**
     * @inheritdoc IPartialPoolJoin
     */
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

    /**
     * @inheritdoc IPartialPoolJoin
     */
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

    /**
     * @inheritdoc IJoinPoolSingleToken
     */
    function singleTokenPoolJoin(
        address pool,
        address token,
        uint256 amount,
        address receiver,
        uint64 deadline
    ) 
        external 
        override
        returns (uint256 lpAmount)
    {
        _preOpChecks(pool, deadline);
        address[] memory tokens = new address[](1); tokens[0] = token;
        uint256[] memory amounts = new uint256[](1); amounts[0] = amount;
        return _joinPool(
            pool, 
            _createAmountsArrayFromTokens(pool, tokens, amounts), 
            receiver
        );
    }

    /**
     * @inheritdoc IJoinPoolSingleToken
     */
    function calculateSingleTokenPoolJoin(
        address pool,
        address token,
        uint256 amount
    ) 
        external 
        override
        view 
        returns (uint256 lpAmount)
    {
        uint256[] memory balances = _getPoolBalances(pool);
        address[] memory tokens = new address[](1);  tokens[0] = token;
        uint256[] memory amounts = new uint256[](1); amounts[0] = amount;
        lpAmount = IWeightedPool(pool).calculateJoin(
            balances, 
            _createAmountsArrayFromTokens(pool, tokens, amounts)
        );
    }

    /**
     * @inheritdoc IFullPoolExit
     */
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

    /**
     * @inheritdoc IFullPoolExit
     */
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

    /**
     * @inheritdoc IExitPoolSingleToken
     */
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

    /**
     * @inheritdoc IExitPoolSingleToken
     */
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
