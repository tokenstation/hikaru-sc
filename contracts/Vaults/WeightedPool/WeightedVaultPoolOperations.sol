// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IWeightedVaultSwaps } from "./interfaces/IWeightedVault.sol";
import { TokenUtils } from "../../utils/TokenUtils.sol";
import { IWeightedStorage } from "../../SwapContracts/WeightedPool/interfaces/IWeightedStorage.sol";
import { IWeightedPoolLP } from "../../SwapContracts/WeightedPool/interfaces/IWeightedPoolLP.sol";
import { IWeightedPool } from "../../SwapContracts/WeightedPool/interfaces/IWeightedPool.sol";
import { WeightedVaultStorage } from "./WeightedVaultStorage.sol";


contract WeightedVaultPoolOperations is WeightedVaultStorage, IWeightedVaultSwaps {

    event Swap(address pool, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, address user);
    event Deposit(address pool, uint256 lpAmount, uint256[] tokensDeposited, address user);
    event Withdraw(address pool, uint256 lpAmount, uint256[] tokensReceived, address user);

    using TokenUtils for IERC20;

    /*************************************************
                    Real functions
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
        registeredPool(pool)
        returns (uint256 amountOut) 
    {
        amountOut = IWeightedPool(pool).swap(tokenIn, tokenOut, amountIn, minAmountOut, deadline);
        _transferSwapTokens(tokenIn, amountIn, tokenOut, amountOut, msg.sender);
        _postSwap(pool, tokenIn, amountIn, tokenOut, amountOut, msg.sender);
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
        registeredPool(pool)
        returns (uint256 amountIn)
    {
        amountIn = IWeightedPool(pool).swapExactOut(tokenIn, tokenOut, amountOut, maxAmountIn, deadline);
        _transferSwapTokens(tokenIn, amountIn, tokenOut, amountOut, msg.sender);
        _postSwap(pool, tokenIn, amountIn, tokenOut, amountOut, msg.sender);
    }

    function joinPool(
        address pool,
        uint256[] memory amounts_,
        uint64 deadline
    ) 
        external 
        registeredPool(pool)
        returns(uint256 lpAmount) 
    {
        lpAmount = IWeightedPool(pool).joinPool(amounts_, deadline);
        _transferTokensFrom(IWeightedStorage(pool).getTokens(), amounts_, msg.sender);
        _postLpUpdate(pool, lpAmount, amounts_, msg.sender, true);
    }

    function exitPool(
        address pool,
        uint256 lpAmount,
        uint64 deadline
    ) 
        external 
        registeredPool(pool)
        returns (uint256[] memory tokensReceived)
    {
        tokensReceived = IWeightedPool(pool).exitPool(lpAmount, deadline);
        _transferTokensTo(IWeightedStorage(pool).getTokens(), tokensReceived, msg.sender);
        _postLpUpdate(pool, lpAmount, tokensReceived, msg.sender, true);
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
        registeredPool(pool)
        view 
        returns(uint256 swapResult, uint256 fee)
    {
        (swapResult, fee) = IWeightedPool(pool).calculateSwap(tokenIn, tokenOut, swapAmount, exactIn);
    }

    function calculateJoin(
        address pool,
        uint256[] calldata amountsIn
    ) 
        external 
        registeredPool(pool)
        view 
        returns (uint256 lpAmount)
    {
        lpAmount = IWeightedPool(pool).calculateJoin(amountsIn);
    }

    function calculateExit(
        address pool,
        uint256 lpAmount
    ) 
        external 
        registeredPool(pool)
        view 
        returns (uint256[] memory tokensReceived)
    {
        tokensReceived = IWeightedPool(pool).calculateExit(lpAmount);
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
        emit Swap(pool, tokenIn, tokenOut, amountIn, amountOut, user);
    }

    function _postLpUpdate(
        address pool,
        uint256 lpAmount,
        uint256[] memory tokenAmounts,
        address user,
        bool enterPool
    )
        internal
    {
        if (enterPool) {
            _mintTokensTo(pool, user, lpAmount);
            emit Deposit(pool, lpAmount, tokenAmounts, user);
        } else {
            _burnTokensFrom(pool, user, lpAmount);
            emit Withdraw(pool, lpAmount, tokenAmounts, user);
        }
    }

    function _transferTokensFrom(
        address[] memory tokens,
        uint256[] memory amounts,
        address user
    ) 
        internal
    {
        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            IERC20(tokens[tokenId]).transferFromUser(amounts[tokenId], user);
        }
    }

    function _transferTokensTo(
        address[] memory tokens,
        uint256[] memory amounts,
        address user
    ) 
        internal
    {
        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            IERC20(tokens[tokenId]).transferToUser(amounts[tokenId], user);
        }
    }


    function _transferSwapTokens(
        address tokenIn, 
        uint256 amountIn, 
        address tokenOut, 
        uint256 amountOut,
        address user
    ) 
        internal

    {
        IERC20(tokenIn).transferFromUser(amountIn, user);
        IERC20(tokenOut).transferToUser(amountOut, user);
    }

}