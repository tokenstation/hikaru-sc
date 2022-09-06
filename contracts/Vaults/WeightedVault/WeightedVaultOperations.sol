// SPDX-License-Identifier: GPL-3.0-or-later
// @title Contract implementing default interfaces
// @author tokenstation.dev

pragma solidity 0.8.6;

import "../interfaces/ISwap.sol";
import { IFullPoolJoin, IPartialPoolJoin, IJoinPoolSingleToken } from "../interfaces/IJoin.sol";
import { IFullPoolExit, IExitPoolSingleToken } from "../interfaces/IExit.sol";
import { WeightedVaultPoolOperations } from "./WeightedVaultPoolOperations.sol";
import { IWeightedStorage } from "../../SwapContracts/WeightedPool/interfaces/IWeightedStorage.sol";
import { IWeightedPool } from "../../SwapContracts/WeightedPool/interfaces/IWeightedPool.sol";
import "../../utils/Errors/ErrorLib.sol";

abstract contract WeightedOperations is 
    ISwap,
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
     * @inheritdoc ISwap
     */
    function swap(
        SwapRoute[] calldata swapRoute,
        SwapType swapType,
        uint256 swapAmount,
        uint256 minMaxAmount,
        address receiver,
        uint64 deadline
    )
        external
        override
        reentrancyGuard
        returns (uint256 swapResult)
    {
        _deadlineCheck(deadline);
        return _swap(swapRoute, swapType, swapAmount, minMaxAmount, receiver);
    }

    function calculateSwap(
        SwapRoute[] calldata swapPath,
        SwapType swapType,
        uint256 swapAmount
    )
        external 
        override
        view 
        returns (uint256 swapResult)
    {
        return _calculateSwap(swapPath, swapType, swapAmount);
    }

    /**
     * @inheritdoc IFullPoolJoin
     */
    function joinPool(
        address pool,
        uint256[] memory amounts,
        uint256 minLPAmount,
        address receiver,
        uint64 deadline
    ) 
        external
        override
        reentrancyGuard 
        returns (uint256 lpAmount)
    {
        _preOpChecks(pool, deadline);
        return _joinPool(pool, amounts, minLPAmount, receiver);
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
        uint256 minLPAmount,
        address receiver,
        uint64 deadline
    ) 
        external
        override
        reentrancyGuard 
        returns (uint256 lpAmount)
    {
        _preOpChecks(pool, deadline);
        return _joinPool(
            pool, 
            _createAmountsArrayFromTokens(pool, tokens, amounts),
            minLPAmount,
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
        uint256 minLPAmount,
        address receiver,
        uint64 deadline
    ) 
        external 
        override
        reentrancyGuard
        returns (uint256 lpAmount)
    {
        _preOpChecks(pool, deadline);
        address[] memory tokens = new address[](1); tokens[0] = token;
        uint256[] memory amounts = new uint256[](1); amounts[0] = amount;
        return _joinPool(
            pool, 
            _createAmountsArrayFromTokens(pool, tokens, amounts), 
            minLPAmount,
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
        uint256[] memory minAmountsOut,
        address receiver,
        uint64 deadline
    ) 
        external
        override
        reentrancyGuard 
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        _preOpChecks(pool, deadline);
        IWeightedStorage poolStorage = IWeightedStorage(pool);
        amounts = _exitPool(pool, lpAmount, minAmountsOut, receiver);
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
        uint256 minAmountOut,
        address receiver,
        uint64 deadline
    ) 
        external
        override
        reentrancyGuard 
        returns (uint256 receivedAmount)
    {
        _preOpChecks(pool, deadline);
        return _exitPoolSingleToken(pool, lpAmount, token, minAmountOut, receiver);
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
