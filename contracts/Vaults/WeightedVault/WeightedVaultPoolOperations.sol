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
import { IVaultPoolInfo } from "../interfaces/IVaultPoolInfo.sol";
import "../interfaces/ISwap.sol";
import "../../utils/Errors/ErrorLib.sol";
import "../../utils/TokenInteractions.sol";


abstract contract WeightedVaultPoolOperations is WeightedVaultStorage, Flashloan, TokenInteractions, IVaultPoolInfo {

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

    /**
     * @notice Check if swap path is valid
     * @param swapPath Path which is used to perform swaps
     * @return swapPathValidity Is swap path valid
     */
    function checkSwapPathValidity(
        SwapRoute[] calldata swapPath
    )
        public
        pure
        returns (bool swapPathValidity)
    {
        swapPathValidity = true;
        uint256 swapPathLength = swapPath.length;
        SwapRoute memory currentSwap;
        if (swapPathLength != 1) {
            for (uint256 id = 0; id < swapPathLength-1; id++) {
                currentSwap = swapPath[id];
                swapPathValidity = 
                    swapPathValidity &&
                    currentSwap.tokenOut == swapPath[id+1].tokenIn;
                if (!swapPathValidity) break;
            }
        }
    }


    /*************************************************
                    Internal functions
     *************************************************/

    function _requireSwapPathValidity(
        SwapRoute[] calldata swapPath
    )
        internal
        pure
    {
        _require(
            checkSwapPathValidity(swapPath),
            Errors.INVALID_VIRTUAL_SWAP_PATH
        );
    }

    /**
     * @notice Perform swap using provided swapPath. Swap must be either full-sell or full-buy (no variation allowed)
     * @dev All swaps are treated as virtual swaps. To perform single swap of any type - just provide single-element array
     * @param swapPath Array containing swap path
     * @param swapType What swap must be performed
     * @param swapAmount Amount of tokens used for swap or amount of tokens that must be received
     * @param minMaxAmount Minimum amount of tokens received/Maximum amount of tokens paid
     * @param receiver Who will receive tokens
     * @return swapResult Amount of tokens user received or paid as swap result
     */
    function _swap(
        SwapRoute[] calldata swapPath,
        SwapType swapType,
        uint256 swapAmount,
        uint256 minMaxAmount,
        address receiver
    )
        internal
        returns (uint256 swapResult)
    {
        // uint256 swapPathLength = swapPath.length;
        _require(
            swapPath.length > 0,
            Errors.EMPTY_SWAP_PATH
        );
        _requireSwapPathValidity(swapPath);

        // address user = msg.sender;
        bool sell = swapType == SwapType.Sell;

        swapAmount = sell ? 
            _transferFrom(swapPath[0].tokenIn, msg.sender, swapAmount) : 
            _transferTo(swapPath[swapPath.length - 1].tokenOut, receiver, swapAmount);

        SwapRoute memory currentSwap;
        uint256 inMemoryProtocolFee = protocolFee;
        uint256 currentMinMax;
        for (uint256 swapId = 0; swapId < swapPath.length; swapId++) {
            currentSwap = swapPath[sell ? swapId : swapPath.length - swapId - 1]; 
            currentMinMax = swapId == swapPath.length - 1 ? 
                minMaxAmount : (sell ? 1 : type(uint256).max);
            
            swapAmount = _performSwap(
                currentSwap, 
                swapType, 
                swapAmount, 
                currentMinMax, 
                inMemoryProtocolFee
            );
            if (swapId == swapPath.length - 1) {
                swapResult = sell ?
                    _transferTo(currentSwap.tokenOut, receiver, swapAmount) :
                    _transferFrom(currentSwap.tokenIn, msg.sender, swapAmount);
            }
        }
    }

    function _performSwap(
        SwapRoute memory swap,
        SwapType swapType,
        uint256 swapAmount,
        uint256 minMaxAmount,
        uint256 inMemoryProtocolFee
    )
        internal
        returns (uint256 calculationResult)
    {
        bool sell = swapType == SwapType.Sell;
        _checkPoolAddress(swap.pool);
        uint256[] memory poolBalances = _getPoolBalances(swap.pool);
        uint256 fee;
        (calculationResult, fee) = sell ? 
            IWeightedPool(swap.pool).swap(poolBalances, swap.tokenIn, swap.tokenOut, swapAmount, minMaxAmount) :
            IWeightedPool(swap.pool).swapExactOut(poolBalances, swap.tokenIn, swap.tokenOut, swapAmount, minMaxAmount);
        
        uint256 deductedProtocolFee = _deductFee(swap.tokenIn, fee, inMemoryProtocolFee);

        uint256 tokenInBalanceDelta = sell ?
            swapAmount - deductedProtocolFee : 
            calculationResult - deductedProtocolFee;
        
        _postSwap(
            swap.pool, 
            swap.tokenIn, 
            tokenInBalanceDelta, 
            swap.tokenOut, 
            sell ? calculationResult : swapAmount, 
            msg.sender
        );
    }

    function _calculateSwap(
        SwapRoute[] calldata swapPath,
        SwapType swapType,
        uint256 swapAmount
    ) 
        internal
        view
        returns (uint256 calculationResult)
    {
        _requireSwapPathValidity(swapPath);

        bool sell = swapType == SwapType.Sell;
        uint256 swapPathLength = swapPath.length;

        for (uint256 swapId = 0; swapId < swapPathLength; swapId++) {
            SwapRoute memory currentSwap = swapPath[sell ? swapId : swapPathLength - swapId - 1];

            _checkPoolAddress(currentSwap.pool);
            uint256[] memory poolBalances = _getPoolBalances(currentSwap.pool);

            calculationResult = 
                IWeightedPool(currentSwap.pool).calculateSwap(
                    poolBalances, 
                    currentSwap.tokenIn, 
                    currentSwap.tokenOut, 
                    swapAmount,
                    sell
                );

            swapAmount = calculationResult;
        }
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
        uint256 minLPAmount,
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
        (lpAmount, fees) = IWeightedPool(pool).joinPool(balances, receiver, tokenAmounts, minLPAmount);
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
        uint256[] memory minAmountsOut,
        address receiver
    )
        internal
        returns (uint256[] memory tokensReceived)
    {
        address user = msg.sender;
        uint256[] memory balances = _getPoolBalances(pool);
        (tokensReceived, ) = IWeightedPool(pool).exitPool(_getPoolBalances(pool), user, lpAmount, minAmountsOut);
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
        uint256 minAmountOut,
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

        (tokensReceived, fees) = IWeightedPool(pool).exitPoolSingleToken(balances, user, lpAmount, token, minAmountOut);
        _protocolFees = _deductFees(tokens, fees);

        _transferTokensTo(tokens, tokensReceived, receiver);
        amountOut = tokensReceived[IWeightedStorage(pool).getTokenId(token)];

        for (uint256 id = 0; id < tokens.length; id++) {
            tokensReceived[id] += _protocolFees[id];
        }
        _postLpUpdate(pool, lpAmount, balances, tokensReceived, receiver, false);
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
}