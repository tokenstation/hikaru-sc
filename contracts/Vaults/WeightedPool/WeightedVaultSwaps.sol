// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IWeightedVaultSwaps } from "./interfaces/IWeightedVault.sol";
import { IWeightedPool } from "../../SwapContracts/WeightedPool/interfaces/IWeightedPool.sol";
import { IFactory } from "../../Factories/interfaces/IFactory.sol";
import { TokenUtils } from "../../utils/TokenUtils.sol";
import { IWeightedStorage } from "../../SwapContracts/WeightedPool/interfaces/IWeightedStorage.sol";

contract WeightedVaultStorage {
    mapping (address => uint256) balances;
    IFactory public weightedPoolFactory;

    modifier registeredPool(address poolAddress) {
        require(
            weightedPoolFactory.checkPoolAddress(poolAddress),
            "Pool is not registered in factory"
        );
        _;
    }

    modifier onlyFactory() {
        require(
            msg.sender == address(weightedPoolFactory),
            "Function can only be called by factory"
        );
        _;
    }
}

contract WeightedVaultSwaps is WeightedVaultStorage, IWeightedVaultSwaps {

    using TokenUtils for IERC20;

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
        _transferSwapTokens(tokenIn, amountIn, tokenOut, amountOut);
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
        _transferSwapTokens(tokenIn, amountIn, tokenOut, amountOut);
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
    }

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
        uint256 amountOut
    ) 
        internal

    {
        IERC20(tokenIn).transferFromUser(amountIn, msg.sender);
        IERC20(tokenOut).transferToUser(amountOut, msg.sender);
    }

}