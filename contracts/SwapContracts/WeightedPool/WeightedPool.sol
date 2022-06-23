// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20, IERC20Metadata, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { IWeightedPool } from "./interfaces/IWeightedPool.sol";
import { WeightedMath } from "./libraries/WeightedMath.sol";
import { WeightedStorage } from "./WeightedStorage.sol";
import { BaseWeightedPool } from "./BaseWeightedPool.sol";
import { SingleManager } from "../../utils/SingleManager.sol";

contract WeightedPool is IWeightedPool, BaseWeightedPool, SingleManager {

    // TODO: Check other todo's
    // TODO: add documentation
    // TODO: apply optimisations where possible and it does not obscure code
    // TODO: check real-world gas costs, must be around 100k or less (check how it may be achieved)

    constructor(
        address factoryAddress_,
        address vaultAddress_,
        address poolManager_,
        address[] memory tokens_,
        uint256[] memory weights_,
        uint256 swapFee_,
        string memory name_,
        string memory symbol_
    ) 
        WeightedStorage(factoryAddress_, vaultAddress_, tokens_, weights_)
        BaseWeightedPool(swapFee_, name_, symbol_)
        SingleManager(poolManager_)
    { 

    }

    /*************************************************
                      Swap functions
     *************************************************/

    function swap(
        uint256[] memory balances,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) 
        external
        override
        view
        returns (uint256 amountOut, uint256 fee)
    {
        _onlyVault();
        _checkTokens(tokenIn, tokenOut);
        (amountOut, fee) = _calculateOutGivenIn(
            balances,
            tokenIn,
            tokenOut,
            amountIn
        );
        require(
            amountOut >= minAmountOut,
            "Not enough tokens received"
        );
    }

    function swapExactOut(
        uint256[] memory balances,
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 maxAmountIn
    )
        external
        override
        view
        returns (uint256 amountIn, uint256 fee)
    {
        _onlyVault();
        _checkTokens(tokenIn, tokenOut);
        (amountIn, fee) = _calculateInGivenOut(
            balances,
            tokenIn, 
            tokenOut, 
            amountOut
        );
        require(
            amountIn <= maxAmountIn,
            "Too much tokens is used for swap"
        );
    }

    /*************************************************
                    Join/Exit Pool
     *************************************************/

    function joinPool(
        uint256[] memory balances,
        address user,
        uint256[] memory amounts_
    )
        external
        override
        returns(uint256 lpAmount, uint256[] memory fee)
    {
        _onlyVault();
        if (totalSupply() == 0) {
            // Pool initialization
            // First person to join pool sets initial exchange rates
            // So it's necessary to provide all tokens
            
            lpAmount = _calculateInitialization(amounts_);
            fee = new uint256[](N_TOKENS);
        } else {
            (lpAmount, fee) = _calculateJoinPool(balances, amounts_);
        }

        _postJoinExit(user, lpAmount, true);
    }

    // TODO: _calcBptInGivenExactTokensOut
    // Для выхода по части токенов, а не по всем/одному

    function exitPool(
        uint256[] memory balances,
        address user,
        uint256 lpAmount
    )
        external
        override
        returns (uint256[] memory tokensReceived, uint256[] memory fees)
    {
        _onlyVault();
        tokensReceived = _calculateExitPool(balances, lpAmount);
        fees = new uint256[](N_TOKENS);
        _postJoinExit(user, lpAmount, false);
    }

    function exitPoolSingleToken(
        uint256[] memory balances,
        address user,
        uint256 lpAmount,
        address token
    )
        external
        override
        returns (uint256[] memory tokenDeltas, uint256[] memory fee)
    {
        _onlyVault();
        (tokenDeltas, fee) = _calculateExitSingleToken(balances, token, lpAmount);
        _postJoinExit(user, lpAmount, false);
    }

    /*************************************************
                      Dry run functions
     *************************************************/

    function calculateSwap(
        uint256[] memory balances,
        address tokenIn,
        address tokenOut,
        uint256 swapAmount,
        bool exactIn
    )
        external
        override
        view
        returns(uint256 swapResult)
    {
        _checkTokens(tokenIn, tokenOut);
        (swapResult, ) = exactIn ?
            _calculateOutGivenIn(
                balances,
                tokenIn,
                tokenOut,
                swapAmount
            ) : _calculateInGivenOut(
                balances,
                tokenIn,
                tokenOut,
                swapAmount
            );
    }

    function calculateJoin(
        uint256[] memory balances,
        uint256[] calldata amountsIn
    )
        external
        override
        view
        returns (uint256 lpAmount)
    {
        if (totalSupply() == 0) 
            return _calculateInitialization(amountsIn);
        else 
            (lpAmount, ) = _calculateJoinPool(balances, amountsIn);
    }

    function calculateExit(
        uint256[] memory balances,
        uint256 lpAmount
    )
        external
        override
        view
        returns (uint256[] memory tokensReceived)
    {
        tokensReceived = _calculateExitPool(balances, lpAmount);
    }

    function calculatExitSingleToken(
        uint256[] memory balances,
        uint256 lpAmount,
        address token
    ) 
        external
        override 
        view 
        returns (uint256 amountOut)
    {
        uint256 tokenId = _getTokenId(token);
        uint256[] memory amountsOut = new uint256[](N_TOKENS);
        (amountsOut, ) = _calculateExitSingleToken(balances, token, lpAmount);
        amountOut = amountsOut[tokenId];
    }


    /*************************************************
                   Change pool parameters
     *************************************************/

    function setSwapFee(
        uint256 swapFee_
    )
        external
        onlyManager
    {
        _setSwapFee(swapFee_);
    }
}   