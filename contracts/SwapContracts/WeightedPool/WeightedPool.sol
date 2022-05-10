// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

import { IERC20, IERC20Metadata, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { WeightedMath } from "./libraries/ConstantProductMath.sol";
import { WeightedStorage } from "./utils/WeightedStorage.sol";

import {BaseWeightedPool} from "./BaseWeightedPool.sol";

contract WeightedPool is BaseWeightedPool {

    // TODO: Check other todo's
    // DONE: add functions to change pool parameters (swap fees)
    // DONE: hide weighted math usage + token transfers
    // DONE: add base contract that holds all internal functions + modifiers
    // TODO: add join/exit pool using one token
    // TODO: add unified interface for exchange (probably will be added to vault)
    // DONE: use same names for variables in contract
    // TODO: refactor contract
    // TODO: apply optimisations where possible and it does not obscure code
    // DONE: check difference between immutable and default variable cost
    // TODO: check real-world gas costs, must be around 100k or less (check how it may be achieved)

    constructor(
        address poolManager_,
        address[] memory tokens_,
        uint256[] memory weights_,
        uint256 swapFee_,
        uint256 depositFee_,
        string memory name,
        string memory symbol
    ) 
        WeightedStorage(tokens_, weights_)
        ERC20(name, symbol)
    {
        _setPoolManager(poolManager_);

        _setPoolFees(swapFee_, depositFee_);
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
        _transferSwapTokens(
            tokenIn,
            amountIn,
            tokenOut,
            amountOut
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
        _transferSwapTokens(
            tokenIn,
            amountIn,
            tokenOut,
            amountOut
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
            getMultipliers(), 
            amounts_,
            totalSupply(),
            swapFee
        );

        _mint(msg.sender, lpAmount);

        address[] memory tokens = getTokens();

        for (uint256 tokenId = 0; tokenId < N_TOKENS; tokenId++) {
            _transferAndCheckBalances(
                tokens[tokenId],
                msg.sender,
                address(this),
                amounts_[tokenId],
                true
            );
            _changeBalance(tokens[tokenId], amounts_[tokenId], false);
        }

        emit Deposit(lpAmount, amounts_, msg.sender);
    }

    function exitPool(
        uint256 lpAmount,
        uint64 deadline
    )
        external
        checkDeadline(deadline)
        returns (uint256[] memory tokensReceived)
    {
        tokensReceived = WeightedMath._calcTokensOutGivenExactBptIn(
            balances,
            lpAmount,
            totalSupply()
        );

        _burn(msg.sender, lpAmount);

        address[] memory tokens = getTokens();
        for (uint256 tokenId = 0; tokenId < N_TOKENS; tokenId++) {
            _transferAndCheckBalances(
                tokens[tokenId],
                address(this),
                msg.sender,
                tokensReceived[tokenId],
                false
            );
            _changeBalance(tokens[tokenId], tokensReceived[tokenId], true);
        }

        emit Withdraw(lpAmount, tokensReceived, msg.sender);
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
        view
        returns (uint256 lpAmount)
    {
        (lpAmount, ) = WeightedMath._calcBptOutGivenExactTokensIn(
            balances, 
            getMultipliers(), 
            amountsIn,
            totalSupply(),
            swapFee
        );
    }

    function calculateExit(
        uint256 lpAmount
    )
        external
        view
        returns (uint256[] memory tokensReceived)
    {
        tokensReceived = WeightedMath._calcTokensOutGivenExactBptIn(
            balances,
            lpAmount,
            totalSupply()
        );
    }

    /*************************************************
                   Change pool parameters
     *************************************************/

    function setPoolFees(
        uint256 swapFee_,
        uint256 depositFee_
    )
        external
        onlyPoolManager(msg.sender)
    {
        _setPoolFees(swapFee_, depositFee_);
    }

    function setPoolManager(
        address poolManager_
    )
        external
        onlyPoolManager(msg.sender)
    {
        _setPoolManager(poolManager_);
    }
}   