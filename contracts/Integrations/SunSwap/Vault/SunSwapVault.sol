// SPDX-License-Identifier: GPL-3.0-or-later
// @title Hikaru.fi integration for SunSwap
// @author tokenstation.dev

pragma solidity 0.8.6;

/**
 * For Join/Exit operations we imagine that pool has tokens in order:
 * [WTRX, T1] without regard to actual WTRX and T1 address values
 * 
 * Most of the checks are performed by SunSwap itself:
 * - Checking deadline
 * - Checking for min/max amounts
 * So we need to perform just initial parameter verifications
 */

import "../../../Vaults/interfaces/IOperations.sol";
import "../../../Vaults/interfaces/IVaultPoolInfo.sol";
import "../../../Vaults/BalanceManager/interfaces/IExternalBalanceManager.sol";

import "../interfaces/IJustswapExchange.sol";
import "../interfaces/IJustswapFactory.sol";

import "../utils/SunSwapTRXUtils.sol";

import "../../../utils/TokenAllowanceStorage.sol";
import "../../../utils/TokenInteractions.sol";
import "../../../utils/ReentrancyGuard.sol";

import "./SunSwapERC165.sol";

contract SunSwapVault is 
    ReentrancyGuard,
    SunSwapTRXUtils,
    TokenAllowancesStorage,
    SunSwapERC165,
    TokenInteractions,
    ISwap,
    IFullPoolJoin,
    IFullPoolExit,
    IExternalBalanceManager,
    IVaultPoolInfo
{

    event Swap(address pool, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, address user);
    event Deposit(address pool, uint256 lpAmount, uint256[] tokensDeposited, address user);
    event Withdraw(address pool, uint256 lpAmount, uint256[] tokensReceived, address user);

    constructor(
        ITRXWrapper trxWrapContract_
    )
        SunSwapTRXUtils(trxWrapContract_) 
    {}

    // Some trx were received
    receive() external payable {}

    /**
     * @notice Checks wether there is only one swap in route
     * @param swapRoute Swaps to perform
     * @return Does swap route contains only one element
     */
    function isSingleSwap(
        SwapRoute[] calldata swapRoute
    ) 
        internal
        pure
        returns (bool)
    {
        return swapRoute.length == 1;
    }

    /**
     * @notice This function checks wether any of tokens is WTRX
     * @param swapRoute Swap to perform
     * @return If token is WTRX
     */
    function findWTRXInSwap(
        SwapRoute calldata swapRoute
    ) 
        internal
        view
        returns (bool, bool)
    {
        return (isWTRX(swapRoute.tokenIn), isWTRX(swapRoute.tokenOut));
    }

    /**
     * @notice Check amount of swaps to perform and revert if more than one detected
     * @dev Only single swap is allowed in SunSwap integration 
     *      virtual swap between tokens is handled by SunSwap system
     * @param swapRoute Swaps to perform
     */
    function requireSingleSwap(
        SwapRoute[] calldata swapRoute
    )
        internal
        pure
    {
        require(
            isSingleSwap(swapRoute),
            "Error msg"
        );
    }

    /*************************************************
                       IVaultPoolInfo
     *************************************************/

    /**
     * @inheritdoc IVaultPoolInfo
     */
    function getPoolTokens(
        address pool
    ) 
        external 
        view 
        override
        returns (address[] memory tokens) 
    {
        tokens = new address[](2);
        tokens[0] = address(trxWrapper);
        tokens[1] = IJustswapExchange(pool).tokenAddress();
    }

    /*************************************************
                   IExternalBalanceManager
     *************************************************/

    /**
     * @inheritdoc IExternalBalanceManager
     */
    function getPoolBalances(
        address pool
    ) 
        external 
        view 
        override
        returns (uint256[] memory poolBalances)
    {
        poolBalances = new uint256[](2);
        poolBalances[0] = pool.balance;
        poolBalances[1] = IERC20(
            IJustswapExchange(pool).tokenAddress()
        ).balanceOf(pool);
    }

    /**
     * @inheritdoc IExternalBalanceManager
     */
    function getPoolTokenBalance(
        address pool,
        address token
    ) 
        external 
        view 
        override
        returns (uint256 tokenBalance)
    {
        if (token == address(trxWrapper)) return pool.balance;
        return IERC20(
            IJustswapExchange(pool).tokenAddress()
        ).balanceOf(pool);
    }

    /*************************************************
                        IOperations
     *************************************************/

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
        requireSingleSwap(swapRoute);
        SwapRoute calldata _swap = swapRoute[0];

        IJustswapExchange firstPool = IJustswapExchange(_swap.pool);

        bool wtrxFirst; bool wtrxSecond;
        (wtrxFirst, wtrxSecond) = findWTRXInSwap(_swap);

        if (wtrxFirst) {
            if (swapType == SwapType.Sell) {
                // For sell we unwrap tokens in advance and then perform swap using all provided funds
                _transferFrom(address(trxWrapper), msg.sender, swapAmount);
                unwrapAmount(swapAmount);
                swapResult =  firstPool.trxToTokenTransferInput{value: swapAmount}(minMaxAmount, deadline, receiver);
            } else {
                // When buying we need to know amount of trx to attach to call in advance
                swapResult = firstPool.getTrxToTokenOutputPrice(swapAmount);
                _transferFrom(address(trxWrapper), msg.sender, swapResult);
                unwrapAmount(swapResult);
                swapResult = firstPool.trxToTokenTransferOutput{value: swapResult}(minMaxAmount, deadline, receiver);
            }
        } else {
            // If trx is the first token, then there is no need to check allowances, as
            // we simply attach required amount to call
            _checkTokenAllowance(_swap.tokenIn, swapAmount, _swap.pool);

            if (wtrxSecond) {
                if (swapType == SwapType.Sell) {
                    // Here we need to perform swap, then wrap tokens and transfer them to user
                    // as system works only with ERC20 tokens and not with native tokens
                    swapAmount = _transferFrom(_swap.tokenIn, msg.sender, swapAmount);
                    swapResult = firstPool.tokenToTrxTransferInput(swapAmount, minMaxAmount, deadline, address(this));
                    wrapAmount(swapResult);
                    transferWTRX(receiver, swapResult);
                } else {
                    // Perform operation, wrap tokens and transfer them to user
                    swapResult = firstPool.getTokenToTrxOutputPrice(swapAmount);
                    _transferFrom(_swap.tokenIn, msg.sender, swapResult);
                    swapResult = firstPool.tokenToTrxTransferOutput(swapAmount, minMaxAmount, deadline, address(this));
                    wrapAmount(swapAmount);
                    transferWTRX(receiver, swapAmount);
                }
            } else {
                // Perform swap using only ERC20 tokens (TRX is handled by JustSwap so no need to intract with it)
                _transferFrom(
                    _swap.tokenIn,
                    msg.sender,
                    swapType == SwapType.Sell ? 
                        swapAmount : 
                        _calculateTokenToTokenSwap(_swap, swapType, swapAmount)
                );
                swapResult = swapType == SwapType.Sell ?
                    // It's possible to use minTRXBought/maxTRXSold parameters for more in-depth control
                    // But in this case we are only interested in token input and output
                    firstPool.tokenToTokenTransferInput(swapAmount, minMaxAmount, 1, deadline, receiver, _swap.tokenOut) :
                    firstPool.tokenToTokenTransferOutput(swapAmount, minMaxAmount, MAX_UINT256, deadline, receiver, _swap.tokenOut); 
            }
        }

        // All cases have the same exit point
        emit Swap(
            _swap.pool, 
            _swap.tokenIn, 
            _swap.tokenOut, 
            swapType == SwapType.Sell ? swapAmount : swapResult,
            swapType == SwapType.Sell ? swapResult : swapAmount,
            receiver
        );
        return swapResult;
    }

    /**
     * @inheritdoc ISwap
     */
    function calculateSwap(
        SwapRoute[] calldata swapRoute,
        SwapType swapType,
        uint256 swapAmount
    ) 
        external 
        override 
        view 
        returns (uint256 swapResult) 
    {
        requireSingleSwap(swapRoute);
        SwapRoute calldata _swap = swapRoute[0];

        // There are separate functions for swap depending on what is used for swap:
        // 1. TRX
        // 2. ERC20 tokens
        // So we need to know swap type - TRX -> ERC20 / ERC20 -> TRX / ERC20 -> (TRX ->) ERC20
        bool wtrxFirst; bool wtrxSecond;
        (wtrxFirst, wtrxSecond) = findWTRXInSwap(_swap);

        IJustswapExchange firstPool = IJustswapExchange(_swap.pool);

        if (wtrxFirst) {
            return swapType == SwapType.Sell ?  
                firstPool.getTrxToTokenInputPrice(swapAmount) :
                firstPool.getTrxToTokenOutputPrice(swapAmount);
        }

        if (wtrxSecond) {
            return swapType == SwapType.Sell ? 
                firstPool.getTokenToTrxInputPrice(swapAmount) :
                firstPool.getTokenToTrxOutputPrice(swapAmount);
        }

        return _calculateTokenToTokenSwap(
            _swap,
            swapType,
            swapAmount
        );
    }

    /**
     * @inheritdoc IFullPoolJoin
     * @dev If there are any ERC20 tokens left after providing liquidity 
     * They will be returned to specified receiver address 
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
        IJustswapExchange poolEx = IJustswapExchange(pool);
        // Creating array of pool tokens
        address[] memory tokens = new address[](2);
        // First token in array is assumed to always be TRX, the second - address of 
        // pool's ERC20 token
        tokens[0] = address(trxWrapper); tokens[1] = poolEx.tokenAddress();

        // Transferring tokens from msg sender
        _transferTokensFrom(
            tokens,
            amounts,
            msg.sender
        );

        // Checking allowances in case if any allowances are not set
        _checkTokenAllowance(
            tokens[1],
            amounts[1],
            pool
        );

        // Unwrapping WTRX to use unwrapped TRX for liquidity providing
        unwrapAmount(amounts[0]);

        // Providing liquidity
        lpAmount = poolEx.addLiquidity{value: amounts[0]}(
            minLPAmount,
            amounts[1],
            deadline
        );

        IERC20(pool).transfer(receiver, lpAmount);

        // There might be tokens left after providing tokens to pool
        // This is due to the fact that we need to provide tokens in proportion to pool's balances
        // And we might encounter situation when there are tokens left for contract
        // To prevent misuse of this part of code ReentrancyGuard is implemented
        uint256 tokensToReturn = IERC20(tokens[1]).balanceOf(address(this));
        if (tokensToReturn > 0) {
            _transferTo(
                tokens[1],
                receiver,
                tokensToReturn
            );
            
            // Accounting for leftover tokens
            amounts[1] -= tokensToReturn;
        }

        emit Deposit(
            pool,
            lpAmount,
            amounts,
            receiver
        );
    }

    /**
     * @inheritdoc IFullPoolJoin
     */
    function calculateJoinPool(
        address pool,
        uint256[] memory amounts
    ) 
        external 
        view 
        override 
        returns (uint256 lpAmount) 
    {
        return _calculateJoinLPAmount(
            IJustswapExchange(pool),
            amounts[0]
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
        IJustswapExchange poolEx = IJustswapExchange(pool);
        tokens = new address[](2);
        amounts = new uint256[](2);

        tokens[0] = address(trxWrapper); tokens[1] = poolEx.tokenAddress();

        // Transfer lp tokens from user
        _transferFrom(
            pool,
            msg.sender,
            lpAmount
        );
        // No need to check allowance as JustSwap burns tokens directly from the balance

        (amounts[0], amounts[1]) = 
            poolEx.removeLiquidity(lpAmount, minAmountsOut[0], minAmountsOut[1], deadline);

        // Wrapping received ether
        wrapAmount(amounts[0]);
        
        // Transferring tokens to receiver
        _transferTokensTo(
            tokens,
            amounts,
            receiver
        );

        emit Withdraw(
            pool,
            lpAmount,
            amounts,
            receiver
        );
    }


    /**
     * @inheritdoc IFullPoolExit
     */
    function calculateExitPool(
        address pool,
        uint256 lpAmount
    ) 
        external 
        view 
        override 
        returns (address[] memory tokens, uint256[] memory amounts) 
    {
        tokens = new address[](2);
        amounts = new uint256[](2);

        IJustswapExchange poolEx = IJustswapExchange(pool);
        tokens[0] = address(trxWrapper);
        tokens[1] = poolEx.tokenAddress();

        (amounts[0], amounts[1]) = _calculateExitLPAmount(poolEx, lpAmount);
    }


    /*************************************************
                   Calculation functions
     *************************************************/


    /**
     * @notice Calculate token to token swap result in JustSwap
     * @param _swap Swap route (first pool, tokenIn and tokenOut)
     * @param swapType Sell/Buy tokens
     * @param swapAmount Amount of tokens to sell/buy
     */
    function _calculateTokenToTokenSwap(
        SwapRoute calldata _swap,
        SwapType swapType,
        uint256 swapAmount
    )
        internal
        view
        returns (uint256)
    {
        IJustswapExchange firstPool = IJustswapExchange(_swap.pool);
        IJustswapExchange secondPool = IJustswapExchange(IJustswapFactory(firstPool.factoryAddress()).getExchange(_swap.tokenOut));

        // Obtaining amount of TRX after the first swap for sell
        // And amount of TRX to buy for the second swap for buy
        uint256 firstSwapAmount = swapType == SwapType.Sell ?
            firstPool.getTokenToTrxInputPrice(swapAmount) : 
            secondPool.getTrxToTokenOutputPrice(swapAmount);

        // Obtaining amount of ERC20 received after selling TRX 
        // And amount of tokens required to buy said amount of TRX
        return swapType == SwapType.Sell ?
            secondPool.getTrxToTokenInputPrice(firstSwapAmount) : 
            firstPool.getTokenToTrxOutputPrice(firstSwapAmount) ;
    }

    /**
     * @notice Calculates amount of LP tokens received after providing tokens to SunSwap pool
     * @param pool Instance of SunSwap pool
     * @param trxAmount Amount of TRX used for providing liquidity
     * @return lpAmount Amount of LP tokens received
     */
    function _calculateJoinLPAmount(
        IJustswapExchange pool,
        uint256 trxAmount
    )
        internal
        view 
        returns (uint256 lpAmount)
    {
        uint256 LPTotalSupply = IERC20(address(pool)).totalSupply();

        if (LPTotalSupply == 0) return trxAmount;
        uint256 trxReserve = address(pool).balance;

        return trxAmount * LPTotalSupply / trxReserve;
    }

    /**
     * @notice Calculate amount of tokens received after exiting pool
     * @param pool Instance of SunSwap pool
     * @param lpAmount Amount of LP tokens to use for exit
     * @return trxReceived Amount of TRX received after exiting pool
     * @return tokensReceived Amount of ERC20 tokens recived after exiting pool
     */
    function _calculateExitLPAmount(
        IJustswapExchange pool,
        uint256 lpAmount
    )
        internal
        view
        returns (uint256 trxReceived, uint256 tokensReceived)
    {
        address poolAddress = address(pool);
        uint256 LPTotalSupply = IERC20(address(pool)).totalSupply();

        uint256 tokenReserve = IERC20(pool.tokenAddress()).balanceOf(poolAddress);
        uint256 trxReserve = poolAddress.balance;

        trxReceived = lpAmount * trxReserve / LPTotalSupply;
        tokensReceived = lpAmount * tokenReserve / LPTotalSupply;
    }
}