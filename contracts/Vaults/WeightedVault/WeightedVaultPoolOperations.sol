// SPDX-License-Identifier: GPL-3.0-or-later
// @title Contract for interacting with Weighted Pool
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { TokenUtils } from "../../utils/libraries/TokenUtils.sol";
import { IWeightedStorage } from "../../SwapContracts/WeightedPool/interfaces/IWeightedStorage.sol";
import { IWeightedPool } from "../../SwapContracts/WeightedPool/interfaces/IWeightedPool.sol";
import { WeightedVaultStorage } from "./WeightedVaultStorage.sol";
import { Flashloan } from "../Flashloan/Flashloan.sol";
import { ProtocolFees } from "../ProtocolFees/ProtocolFees.sol";
import { IVaultPoolInfo } from "../interfaces/IVaultPoolInfo.sol";
import "../interfaces/ISwap.sol";
import "../../utils/Errors/ErrorLib.sol";

// TODO: return swapFee on operations and calculate protocol fee
// TODO: add contract for extracting protocol fee from swap fee

abstract contract WeightedVaultPoolOperations is WeightedVaultStorage, Flashloan, ProtocolFees, IVaultPoolInfo {

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

    /**
     * @inheritdoc IVaultPoolInfo
     */
    function getPoolTokens(
        address pool
    )
        external
        override
        view
        returns (address[] memory tokens)
    {
        return IWeightedStorage(pool).getTokens();
    }


    /*************************************************
                    Internal functions
     *************************************************/

    /**
     * @notice Perform sell tokens swap without token transfers
     * @param pool Address of pool
     * @param tokenIn Token that will be used for swaps
     * @param tokenOut Token that will be received as swap result
     * @param amountIn Amount of tokens to sell
     * @param minAmountOut Minimal amount out
     * @param receiver Who will receive tokens
     * @param protocolFee_ Protocol fee
     * @param transferToUser If parameter is true, resulting tokens will be transferred to receiver
     * @return amountOut Amount of tokens received as swap result
     */
    function _lightSwap(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver,
        uint256 protocolFee_,
        bool transferToUser
    )
        internal
        returns (uint256 amountOut)
    {
        uint256[] memory poolBalances = _getPoolBalances(pool);
        uint256 fee;
        (amountOut, fee) = IWeightedPool(pool).swap(poolBalances, tokenIn, tokenOut, amountIn, minAmountOut);

        uint256 _protocolFee = _deductFee(tokenIn, fee, protocolFee_);
        amountIn -= _protocolFee;
        if (transferToUser) amountOut = _transferTo(tokenOut, receiver, amountOut);
        _postSwap(pool, tokenIn, amountIn, tokenOut, amountOut, receiver);
    }

    /**
     * @notice Internal function for virtual swap
     * @param swapRoute Swap path that will be used
     * @param amountIn Initial amount of tokens to use for swap
     * @param minAmountOut Minimal result amount of tokens
     * @param receiver Who will receive tokens
     * @return amountOut Amount of tokens received as swap result
     */
    function _virtualSwap(
        VirtualSwapInfo[] calldata swapRoute,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver
    )
        internal
        returns (uint256 amountOut)
    {
        uint256 protocolFee_ = protocolFee;
        uint256 pathLength = swapRoute.length;
        VirtualSwapInfo memory currentSwap = swapRoute[0];
        amountIn = _transferFrom(currentSwap.tokenIn, msg.sender, amountIn);
        amountOut = amountIn;
        
        // If there are mismatches in token addresses
        // They will be spotted before actual operation begin
        // And therefore will save some gas
        for (uint256 id = 0; id < pathLength; id++) {
            if (
                (id != pathLength - 1) && 
                (pathLength != 1)
            ) {
                currentSwap = swapRoute[id];
                _require(
                    currentSwap.tokenOut == swapRoute[id+1].tokenIn,
                    Errors.INVALID_VIRTUAL_SWAP_PATH
                );
            }
        }

        for (uint256 id = 0; id < pathLength; id++) {
            currentSwap = swapRoute[id];
            _checkPoolAddress(currentSwap.pool);
            // Value of minAmountOut is hardcoded to 1
            // This is done intentional, as we are only interested in
            // Resulting value of swap
            amountOut = _lightSwap(
                currentSwap.pool, 
                currentSwap.tokenIn, 
                currentSwap.tokenOut, 
                amountOut, 
                id == pathLength - 1 ? minAmountOut : 1,
                receiver,
                protocolFee_,
                id == pathLength - 1
            );
        }

        return amountOut;
    }

    /**
     * @notice Sell or buy tokens
     * @param pool Address of pool
     * @param tokenIn Token to sell or to use for token buying
     * @param tokenOut Token received as sell result or to buy
     * @param amount Amount to sell or to buy
     * @param minMaxAmount Minimal amount to receive or maximum amount to pay
     * @param receiver Who will receive tokens
     * @param exactIn Sell or Buy tokens
     * @return calculationResult Amount of tokens received/that must be paid
     */
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

        uint256 fee;

        (calculationResult, fee) = exactIn ?
            IWeightedPool(pool).swap(poolBalances, tokenIn, tokenOut, amount, minMaxAmount) :
            IWeightedPool(pool).swapExactOut(poolBalances, tokenIn, tokenOut, amount, minMaxAmount);

        uint256 _protocolFee = _deductFee(tokenIn, fee, protocolFee);

        calculationResult = exactIn ? 
            _transferTo(tokenOut, receiver, calculationResult) :
            _transferFrom(tokenIn, user, calculationResult);

        uint256 tokenInBalanceDelta = exactIn ?
            amount - _protocolFee : 
            calculationResult - _protocolFee;

        _postSwap(
            pool, 
            tokenIn, 
            tokenInBalanceDelta, 
            tokenOut, 
            exactIn ? calculationResult : amount, 
            user
        );
    }

    /**
     * @notice Join pool by all tokens/some tokens/one token
     * @param pool Address of pool
     * @param tokenAmounts Amount of tokens to use for join
     * @param receiver Who will receive lp tokens
     * @return lpAmount Amount of LP tokens received
     */
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
        address[] memory tokens = IWeightedStorage(pool).getTokens();
        tokenAmounts = _transferTokensFrom(tokens, tokenAmounts, user);
        uint256[] memory fees;
        (lpAmount, fees) = IWeightedPool(pool).joinPool(balances, receiver, tokenAmounts);
        uint256[] memory _protocolFees = _deductFees(tokens, fees);
        for(uint256 id = 0; id < tokens.length; id++) {
            tokenAmounts[id] -= _protocolFees[id];
        }
        _postLpUpdate(pool, lpAmount, balances, tokenAmounts, receiver, true);
    }

    /**
     * @notice Exit pool by all tokens
     * @param pool Address of pool
     * @param lpAmount Amount of LP tokens to burn
     * @param receiver Who will receive tokens
     * @return tokensReceived Amount of tokens received as exit result
     */
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
        (tokensReceived, ) = IWeightedPool(pool).exitPool(_getPoolBalances(pool), user, lpAmount);
        tokensReceived = _transferTokensTo(IWeightedStorage(pool).getTokens(), tokensReceived, receiver);
        _postLpUpdate(pool, lpAmount, balances, tokensReceived, receiver, false);
    }

    /**
     * @notice Exit pool using only one token
     * @param pool Address of pool
     * @param lpAmount Amount of LP tokens to burn
     * @param token Token to use for exit
     * @param receiver Who will receive tokens
     * @return amountOut Amount of tokens received as exit result
     */
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
        address[] memory tokens = IWeightedStorage(pool).getTokens();
        uint256[] memory tokensReceived;
        uint256[] memory fees;
        uint256[] memory _protocolFees;

        (tokensReceived, fees) = IWeightedPool(pool).exitPoolSingleToken(balances, user, lpAmount, token);
        _protocolFees = _deductFees(tokens, fees);

        _transferTokensTo(tokens, tokensReceived, receiver);
        amountOut = tokensReceived[IWeightedStorage(pool).getTokenId(token)];

        for (uint256 id = 0; id < tokens.length; id++) {
            tokensReceived[id] += _protocolFees[id];
        }
        _postLpUpdate(pool, lpAmount, balances, tokensReceived, receiver, false);
    }

    /**
     * @notice Calculate sell/buy result
     * @param pool Address of pool
     * @param tokenIn Token to sell/use to buy
     * @param tokenOut Token to receive/token to buy
     * @param swapAmount Amount of tokens to sell/buy
     * @param exactIn Sell tokens or buy tokens
     * @return swapResult Result token amount
     */
    function _calculateSwap(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 swapAmount,
        bool exactIn
    )
        internal
        view
        returns (uint256 swapResult)
    {
        uint256[] memory balances = _getPoolBalances(pool);
        swapResult = IWeightedPool(pool).calculateSwap(balances, tokenIn, tokenOut, swapAmount, exactIn);
    }

    /*************************************************
                    Utility functions
     *************************************************/

    /**
     * @notice Post swap sequence
     * @param pool Address of pool
     * @param tokenIn Token transferred from user
     * @param amountIn Amount of tokens received from user
     * @param tokenOut Token transferred to user
     * @param amountOut Amount of tokens transferred to user
     * @param user Who received tokens
     */
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

    /**
     * @notice Post exit/join sequence
     * @param pool Address of pool
     * @param lpAmount Amount of lp tokens burned/received
     * @param balances Initial pool's token balances
     * @param tokenAmounts Pool's token balance change
     * @param user Who burnt/received tokens
     * @param enterPool False=exit, True=join
     */
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

    function _checkPoolAddress(
        address pool
    )
        internal
        view
    {
        _require(
            weightedPoolFactory.checkPoolAddress(pool),
            Errors.UNKNOWN_POOL_ADDRESS
        );
    }

    function _deadlineCheck(
        uint256 deadline
    )
        internal
        view
    {
        _require(
            deadline >= block.timestamp,
            Errors.DEADLINE
        );
    }

    function _preOpChecks(
        address pool,
        uint64 deadline
    )
        internal
        view
    {
        _checkPoolAddress(pool);
        _deadlineCheck(deadline);
    }

    /**
     * @notice Create full array from some tokens
     * @param pool Address of pool
     * @param tokens Array of tokens that are provided
     * @param amounts Amount of tokens
     * @return amounts_ Result amounts array
     */
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
        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            amounts_[poolStorage.getTokenId(tokens[tokenId])] = amounts[tokenId];
        }
    }

    /*************************************************
                Token transfer functions
     *************************************************/

    /**
     * @notice Transfer tokens from user and return balance deltas
     * @param tokens Token addresses
     * @param amounts Amounts of tokens to transfer
     * @param user Where to transfer tokens from
     * @return balanceDeltas Amount of tokens received from user
     */
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

    /**
     * @notice Transfer tokens to user and return balance deltas
     * @param tokens Token addresses
     * @param amounts Amounts of tokens to transfer
     * @param user Who will receive tokens
     * @return balanceDeltas Amount of tokens transferred to user
     */
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
    
    /**
     * @notice Utility function for transferFrom
     * @param token Token address
     * @param user Address to transfer from
     * @param amount Amount of tokens to transfer from
     * @return Amount of tokens received
     */
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

    /**
     * @notice Utility function for transfer
     * @param token Token address
     * @param user Address to transfer to
     * @param amount Amount of tokens to transfer
     * @return Amount of tokens transferred
     */
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