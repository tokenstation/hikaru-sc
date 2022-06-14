// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IWeightedVaultOperations } from "./interfaces/IWeightedVault.sol";
import { TokenUtils } from "../../utils/libraries/TokenUtils.sol";
import { IWeightedStorage } from "../../SwapContracts/WeightedPool/interfaces/IWeightedStorage.sol";
import { IWeightedPoolLP } from "../../SwapContracts/WeightedPool/interfaces/IWeightedPoolLP.sol";
import { IWeightedPool } from "../../SwapContracts/WeightedPool/interfaces/IWeightedPool.sol";
import { WeightedVaultStorage } from "./WeightedVaultStorage.sol";
import { Flashloan } from "../Flashloan/Flashloan.sol";

// TODO: return swapFee on operations and calculate protocol fee
// TODO: add contract for extracting protocol fee from swap fee

abstract contract WeightedVaultPoolOperations is WeightedVaultStorage, IWeightedVaultOperations, Flashloan {

    event Swap(address pool, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, address user);
    event Deposit(address pool, uint256 lpAmount, uint256[] tokensDeposited, address user);
    event Withdraw(address pool, uint256 lpAmount, uint256[] tokensReceived, address user);

    using TokenUtils for IERC20;

    constructor(
        address weightedPoolFactory_
    ) 
        WeightedVaultStorage(weightedPoolFactory_)
    {

    }

    /*************************************************
                External non-view functions
     *************************************************/

    function swap(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint64 deadline
    ) 
        external 
        override
        reentrancyGuard
        returns (uint256 amountOut) 
    {
        _preOpChecks(pool, deadline);
        amountOut = _swap(
            pool, 
            tokenIn, 
            tokenOut, 
            amountIn, 
            minAmountOut, 
            true
        );
    }

    function swapExactOut(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 maxAmountIn,
        uint64 deadline
    ) 
        external 
        override
        reentrancyGuard
        returns (uint256 amountIn)
    {
        _preOpChecks(pool, deadline);
        amountIn = _swap(
            pool, 
            tokenIn, 
            tokenOut, 
            amountOut, 
            maxAmountIn, 
            false
        );
    }

    function joinPool(
        address pool,
        uint256[] memory amounts_,
        uint64 deadline
    ) 
        external 
        override
        reentrancyGuard
        returns(uint256 lpAmount) 
    {
        _preOpChecks(pool, deadline);
        return _joinPool(pool, amounts_);
    }

    function exitPool(
        address pool,
        uint256 lpAmount,
        uint64 deadline
    ) 
        external 
        override
        reentrancyGuard
        returns (uint256[] memory tokensReceived)
    {
        _preOpChecks(pool, deadline);
        return _exitPool(pool, lpAmount);
    }

    function exitPoolSingleToken(
        address pool,
        uint256 lpAmount,
        address token,
        uint64 deadline
    )
        external
        override
        reentrancyGuard
        returns (uint256 amountOut)
    {
        _preOpChecks(pool, deadline);
        return _exitPoolSingleToken(pool, lpAmount, token);
    }

    /*************************************************
                    Internal functions
     *************************************************/

    function _swap(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amount,
        uint256 minMaxAmount,
        bool exactIn
    )
        internal
        returns (uint256 calculationResult)
    {
        address user = msg.sender;

        uint256[] memory poolBalances = _getPoolBalances(pool);
        amount = exactIn ? 
            _transferFrom(tokenIn, user, amount) : 
            _transferTo(tokenOut, user, amount);

        calculationResult = exactIn ?
            IWeightedPool(pool).swap(poolBalances, tokenIn, tokenOut, amount, minMaxAmount) :
            IWeightedPool(pool).swapExactOut(poolBalances, tokenIn, tokenOut, amount, minMaxAmount);

        calculationResult = exactIn ? 
            _transferTo(tokenOut, user, calculationResult) :
            _transferFrom(tokenIn, user, calculationResult);

        _postSwap(
            pool, 
            tokenIn, 
            exactIn ? amount : calculationResult, 
            tokenOut, 
            exactIn ? calculationResult : amount, 
            user
        );
    }

    function _joinPool(
        address pool,
        uint256[] memory tokenAmounts
    )
        internal
        returns (uint256 lpAmount)
    {
        address user = msg.sender;
        uint256[] memory balances = _getPoolBalances(pool);
        tokenAmounts = _transferTokensFrom(IWeightedStorage(pool).getTokens(), tokenAmounts, user);
        lpAmount = IWeightedPool(pool).joinPool(balances, user, tokenAmounts);
        _postLpUpdate(pool, lpAmount, balances, tokenAmounts, user, true);
    }

    function _exitPool(
        address pool,
        uint256 lpAmount
    )
        internal
        returns (uint256[] memory tokensReceived)
    {
        address user = msg.sender;
        uint256[] memory balances = _getPoolBalances(pool);
        tokensReceived = IWeightedPool(pool).exitPool(_getPoolBalances(pool), user, lpAmount);
        tokensReceived = _transferTokensTo(IWeightedStorage(pool).getTokens(), tokensReceived, msg.sender);
        _postLpUpdate(pool, lpAmount, balances, tokensReceived, msg.sender, false);
    }

    function _exitPoolSingleToken(
        address pool,
        uint256 lpAmount,
        address token
    )
        internal
        returns (uint256 amountOut)
    {
        address user = msg.sender;
        uint256[] memory balances = _getPoolBalances(pool);
        uint256[] memory tokensReceived = IWeightedPool(pool).exitPoolSingleToken(balances, user, lpAmount, token);
        _transferTokensTo(IWeightedStorage(pool).getTokens(), tokensReceived, user);
        _postLpUpdate(pool, lpAmount, balances, tokensReceived, msg.sender, false);
        amountOut = tokensReceived[IWeightedStorage(pool).getTokenId(token)];
    }

    function _calculateSwap(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 swapAmount,
        bool exactIn
    )
        internal
        view
        returns (uint256 swapResult, uint256 fee)
    {
        uint256[] memory balances = _getPoolBalances(pool);
        (swapResult, fee) = IWeightedPool(pool).calculateSwap(balances, tokenIn, tokenOut, swapAmount, exactIn);
    }

    /*************************************************
                    Dry run functions
     *************************************************/

    function calculateSwap(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 swapAmount,
        bool exactIn
    ) 
        external 
        override
        view 
        returns(uint256 swapResult, uint256 fee)
    {
        (swapResult, fee) = _calculateSwap(pool, tokenIn, tokenOut, swapAmount, exactIn);
    }

    function calculateJoin(
        address pool,
        uint256[] calldata amountsIn
    ) 
        external 
        override
        view 
        returns (uint256 lpAmount)
    {
        uint256[] memory balances = _getPoolBalances(pool);
        lpAmount = IWeightedPool(pool).calculateJoin(balances, amountsIn);
    }

    function calculateExit(
        address pool,
        uint256 lpAmount
    ) 
        external 
        override
        view 
        returns (uint256[] memory tokensReceived)
    {
        uint256[] memory balances = _getPoolBalances(pool);
        tokensReceived = IWeightedPool(pool).calculateExit(balances, lpAmount);
    }

    /*************************************************
                    Utility functions
     *************************************************/

    function _postSwap(
        address pool,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut,
        address user
    )
        internal
    {
        _changePoolBalance(pool, IWeightedStorage(pool).getTokenId(tokenIn), amountIn, true);
        _changePoolBalance(pool, IWeightedStorage(pool).getTokenId(tokenOut), amountOut, false);
        emit Swap(pool, tokenIn, tokenOut, amountIn, amountOut, user);
    }

    function _postLpUpdate(
        address pool,
        uint256 lpAmount,
        uint256[] memory balances,
        uint256[] memory tokenAmounts,
        address user,
        bool enterPool
    )
        internal
    {
        balances = _calculateBalancesUpdate(balances, tokenAmounts, enterPool);
        _setBalances(pool, balances);
        if (enterPool) {
            emit Deposit(pool, lpAmount, tokenAmounts, user);
        } else {
            emit Withdraw(pool, lpAmount, tokenAmounts, user);
        }
    }

    function _preOpChecks(
        address pool,
        uint64 deadline
    )
        internal
        view
    {
        require(
            weightedPoolFactory.checkPoolAddress(pool),
            "Pool is not registered in factory"
        );
        require(
            deadline >= block.timestamp,
            "Deadline check failed"
        );
    }

    /*************************************************
                Token transfer functions
     *************************************************/

    function _transferTokensFrom(
        address[] memory tokens,
        uint256[] memory amounts,
        address user
    ) 
        internal
        returns (uint256[] memory balanceDeltas)
    {
        balanceDeltas = new uint256[](tokens.length);
        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            balanceDeltas[tokenId] = IERC20(tokens[tokenId]).transferFromUser(user, amounts[tokenId]);
        }
    }

    function _transferTokensTo(
        address[] memory tokens,
        uint256[] memory amounts,
        address user
    ) 
        internal
        returns (uint256[] memory balanceDeltas)
    {
        balanceDeltas = new uint256[](tokens.length);
        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            balanceDeltas[tokenId] = IERC20(tokens[tokenId]).transferToUser(user, amounts[tokenId]);
        }
    }
    
    function _transferFrom(
        address token,
        address user,
        uint256 amount
    ) 
        internal
        returns (uint256)
    {
        return IERC20(token).transferFromUser(user, amount);
    }

    function _transferTo(
        address token,
        address user,
        uint256 amount
    )
        internal
        returns (uint256)
    {
        return IERC20(token).transferToUser(user, amount);
    }

}