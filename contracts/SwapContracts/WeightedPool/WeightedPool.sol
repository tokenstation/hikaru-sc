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
    // TODO: refactor contract
    // TODO: add documentation
    // TODO: apply optimisations where possible and it does not obscure code
    // TODO: check real-world gas costs, must be around 100k or less (check how it may be achieved)
    // TODO: add comission boundaries check

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
        returns (uint256 amountOut)
    {
        _onlyVault();
        _checkTokens(tokenIn, tokenOut);
        (amountOut, ) = _calculateOutGivenIn(
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
        returns (uint256 amountIn)
    {
        _onlyVault();
        _checkTokens(tokenIn, tokenOut);
        (amountIn, ) = _calculateInGivenOut(
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
        returns(uint256 lpAmount)
    {
        _onlyVault();
        if (totalSupply() == 0) {
            // Pool initialization
            // First person to join pool sets initial exchange rates
            // So it's necessary to provide all tokens
            
            lpAmount = _calculateInitialization(amounts_);
        } else {
            lpAmount = _calculateJoinPool(balances, amounts_);
        }

        _postJoinExit(user, lpAmount, true);
    }

    function exitPool(
        uint256[] memory balances,
        address user,
        uint256 lpAmount
    )
        external
        override
        returns (uint256[] memory tokensReceived)
    {
        _onlyVault();
        tokensReceived = _calculateExitPool(balances, lpAmount);

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
        returns (uint256[] memory tokenDeltas)
    {
        _onlyVault();
        tokenDeltas = _calculateExitSingleToken(balances, token, lpAmount);
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
        returns(uint256 swapResult, uint256 fee)
    {
        _checkTokens(tokenIn, tokenOut);
        (swapResult, fee) = exactIn ?
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
            return _calculateJoinPool(balances, amountsIn);
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
        amountOut = _calculateExitSingleToken(balances, token, lpAmount)[tokenId];
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