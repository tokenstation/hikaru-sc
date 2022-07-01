// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for interacting with pool
// @author tokenstation.dev

pragma solidity 0.8.6;

interface IWeightedPool {
    /**
     * @notice This function is used to sell tokens (i.g. Sell amountIn tokenIn tokens to receive ??? tokenOut)
     * @param balances Virtual balances of pool
     * @param tokenIn Address of token used for exchange
     * @param tokenOut Address of token received as result of exchange
     * @param amountIn Amount of tokens used for swap
     * @param minAmountOut Minimum required amount of tokens received as result of exchange
     * @return amountOut Amount of tokens received as result of exchange
     * @return fee Charged fee
     */
    function swap(
        uint256[] memory balances,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external returns (uint256 amountOut, uint256 fee);

    /**
     * @notice This function is used to buy tokens (i.g. Buy amountOut tokenOut and pay ??? tokenIn)
     * @param balances Virtual balances of pool
     * @param tokenIn Address of token used for exchange
     * @param tokenOut Address of token received as result of exchange
     * @param amountOut Amount of tokens used for swap
     * @param maxAmountIn Maximum cost of buying amountOut tokenOut tokens
     * @return amountIn Cost of buying amountOut tokenOut tokens
     * @return fee Charged fee
     */
    function swapExactOut(
        uint256[] memory balances,
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 maxAmountIn
    ) external returns (uint256 amountIn, uint256 fee);

    /**
     * @notice This function is used to join pool or initialize pool if pool is empty
     * @dev If pool is empty user needs to provide all tokens (array elements must be non-zero)
     * @param balances Virtual balances of pool
     * @param user User that receives LP tokens
     * @param amounts_ Amounts of tokens provided to pool
     * @return lpAmount Amount of LP tokens received by user
     * @return fee Charged fees on amounts_
     */
    function joinPool(
        uint256[] memory balances,
        address user,
        uint256[] memory amounts_
    ) external returns(uint256 lpAmount, uint256[] memory fee);

    /**
     * @notice This function is used to exit pool
     * @dev This function is used to received all tokens of pool in proportion
     * @param balances Virtual balances of pool
     * @param user User who's LP tokens will be burnt
     * @param lpAmount Amount of lp tokens to burn
     */
    function exitPool(
        uint256[] memory balances,
        address user,
        uint256 lpAmount
    ) external returns (uint256[] memory tokensReceived, uint256[] memory fee);

    /**
     * @notice This function is used to exit pool in single token
     * @param balances Virtual balances of pool
     * @param user User who's LP tokens will be burnt
     * @param lpAmount Amount of lp tokens to burn
     * @param token Address of token that will be received
     */
    function exitPoolSingleToken(
        uint256[] memory balances,
        address user,
        uint256 lpAmount,
        address token
    ) external returns (uint256[] memory tokenDeltas, uint256[] memory fee);

    /**
     * @notice Calculate token swap
     * @param balances Virtual balances of pool
     * @param tokenIn Address of token that will be used for exchange
     * @param tokenOut Address of token that will be received as result of exchange
     * @param swapAmount Either amount of tokens to sell or amount of tokens to buy depending on exactIn parameter
     * @param exactIn If true - calculate result of token sell, if false - calculate amountIn to buy tokens
     * @return swapResult amountOut or amountIn depending on exactIn parameter
     */
    function calculateSwap(
        uint256[] memory balances,
        address tokenIn,
        address tokenOut,
        uint256 swapAmount,
        bool exactIn
    ) external view returns(uint256 swapResult);

    /**
     * @notice Calculates amount of LP tokens received by provideing amountsIn to pool
     * @param balances Virtual balances of pool
     * @param amountsIn Amount of tokens provided to pool
     * return lpAmount Amount of LP tokens received
     */
    function calculateJoin(
        uint256[] memory balances,
        uint256[] calldata amountsIn
    ) external view returns (uint256 lpAmount);

    /**
     * @notice Calculate amount of tokens received for burning lpAmount LP tokens
     * @param balances Virtual balances of pool
     * @param lpAmount Amount of LP tokens to burn
     * @return tokensReceived Amount of tokens received as result of exit
     */
    function calculateExit(
        uint256[] memory balances,
        uint256 lpAmount
    ) external view returns (uint256[] memory tokensReceived);

    /**
     * @notice Calculate maount of token received for burning lpAmount LP tokens
     * @param balances Virtual balances of pool
     * @param lpAmount AMount of LP tokens to burn
     * @param token Address of token to receive
     * @return amountOut Received amount of token
     */
    function calculatExitSingleToken(
        uint256[] memory balances,
        uint256 lpAmount,
        address token
    ) external view returns (uint256 amountOut);
}