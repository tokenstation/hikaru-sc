// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { TokenUtils } from "../../utils/libraries/TokenUtils.sol";
import { IWeightedStorage } from "../../SwapContracts/WeightedPool/interfaces/IWeightedStorage.sol";
import { IWeightedPoolLP } from "../../SwapContracts/WeightedPool/interfaces/IWeightedPoolLP.sol";
import { IWeightedPool } from "../../SwapContracts/WeightedPool/interfaces/IWeightedPool.sol";
import { WeightedVaultStorage } from "./WeightedVaultStorage.sol";
import { Flashloan } from "../Flashloan/Flashloan.sol";

// TODO: return swapFee on operations and calculate protocol fee
// TODO: add contract for extracting protocol fee from swap fee

abstract contract WeightedVaultPoolOperations is WeightedVaultStorage, Flashloan {

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
                    Internal functions
     *************************************************/

    function _swap(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amount,
        uint256 minMaxAmount,
        address receiver,
        bool exactIn
    )
        internal
        returns (uint256 calculationResult)
    {
        address user = msg.sender;

        uint256[] memory poolBalances = _getPoolBalances(pool);
        amount = exactIn ? 
            _transferFrom(tokenIn, user, amount) : 
            _transferTo(tokenOut, receiver, amount);

        calculationResult = exactIn ?
            IWeightedPool(pool).swap(poolBalances, tokenIn, tokenOut, amount, minMaxAmount) :
            IWeightedPool(pool).swapExactOut(poolBalances, tokenIn, tokenOut, amount, minMaxAmount);

        calculationResult = exactIn ? 
            _transferTo(tokenOut, receiver, calculationResult) :
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
        uint256[] memory tokenAmounts,
        address receiver
    )
        internal
        returns (uint256 lpAmount)
    {
        address user = msg.sender;
        uint256[] memory balances = _getPoolBalances(pool);
        tokenAmounts = _transferTokensFrom(IWeightedStorage(pool).getTokens(), tokenAmounts, user);
        lpAmount = IWeightedPool(pool).joinPool(balances, receiver, tokenAmounts);
        _postLpUpdate(pool, lpAmount, balances, tokenAmounts, receiver, true);
    }

    function _exitPool(
        address pool,
        uint256 lpAmount,
        address receiver
    )
        internal
        returns (uint256[] memory tokensReceived)
    {
        address user = msg.sender;
        uint256[] memory balances = _getPoolBalances(pool);
        tokensReceived = IWeightedPool(pool).exitPool(_getPoolBalances(pool), user, lpAmount);
        tokensReceived = _transferTokensTo(IWeightedStorage(pool).getTokens(), tokensReceived, receiver);
        _postLpUpdate(pool, lpAmount, balances, tokensReceived, receiver, false);
    }

    function _exitPoolSingleToken(
        address pool,
        uint256 lpAmount,
        address token,
        address receiver
    )
        internal
        returns (uint256 amountOut)
    {
        address user = msg.sender;
        uint256[] memory balances = _getPoolBalances(pool);
        uint256[] memory tokensReceived = IWeightedPool(pool).exitPoolSingleToken(balances, user, lpAmount, token);
        _transferTokensTo(IWeightedStorage(pool).getTokens(), tokensReceived, receiver);
        _postLpUpdate(pool, lpAmount, balances, tokensReceived, receiver, false);
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

    function _createAmountsArrayFromTokens(
        address pool,
        address[] memory tokens,
        uint256[] memory amounts
    )
        internal
        view
        returns (uint256[] memory amounts_)
    {
        IWeightedStorage poolStorage = IWeightedStorage(pool);
        amounts_ = new uint256[](poolStorage.getNTokens());
        for (uint256 tokenId = 0; tokenId < amounts_.length; tokenId++) {
            amounts_[poolStorage.getTokenId(tokens[tokenId])] = amounts[tokenId];
        }
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