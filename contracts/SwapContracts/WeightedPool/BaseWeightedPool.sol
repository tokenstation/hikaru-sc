// SPDX-License-Identifier: GPL-3.0-or-later
// @title Contract that contains math wrappers
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20, IERC20Metadata, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { WeightedMath } from "./libraries/WeightedMath.sol";
import { FixedPoint } from "../../utils/Math/FixedPoint.sol";
import { WeightedStorage } from "./WeightedStorage.sol";
import "../../utils/Errors/ErrorLib.sol";

abstract contract BaseWeightedPool is WeightedStorage, ERC20 {
    
    event SwapFeeUpdate(uint256 newSwapFee);

    using FixedPoint for uint256;

    uint256 internal constant ONE = 1e18;
    uint256 public constant MAX_SWAP_FEE = 5e15;

    uint256 public swapFee;

    constructor(
        uint256 swapFee_,
        string memory name_,
        string memory symbol_
    ) 
        ERC20(name_, symbol_)
    {
        _setSwapFee(swapFee_);
    }

    /**
     * @dev Swap fee is capped by 5e15
     * @param swapFee_ New swap fee
     */
    function _setSwapFee(
        uint256 swapFee_
    ) 
        internal
    {
        _require(
            swapFee_ <= MAX_SWAP_FEE,
            Errors.SWAP_FEE_PERCENTAGE_TOO_HIGH
        );
        swapFee = swapFee_;
        emit SwapFeeUpdate(swapFee_);
    }

    /**
     * @notice This function normalizes balance - multiplies provided amount by corresponding multiplier
     * @param balances Provided balances
     * @param token Address of token
     * @return normalizedBalance_ Normalized balance of token
     */
    function _normalizedBalance(
        uint256[] memory balances,
        address token
    )
        internal
        view
        returns (uint256 normalizedBalance_)
    {
        normalizedBalance_ = balances[_getTokenId(token)] * _getMultiplier(token);
    }

    /**
     * @param amount Amount to normalize
     * @param token Address of token
     * @param normalizedAmount Amount multiplied by corresponding multiplier
     */
    function _normalizeAmount(
        uint256 amount,
        address token
    )
        internal
        view
        returns (uint256 normalizedAmount)
    {
        normalizedAmount = amount * _getMultiplier(token);
    }

    /**
     * @param amount Normalized amount
     * @param token Address of token
     * @return denormalizedAmount Provided amount divided by corresponding multiplier
     */
    function _denormalizeAmount(
        uint256 amount,
        address token
    )
        internal
        view
        returns (uint256 denormalizedAmount)
    {
        denormalizedAmount = amount / _getMultiplier(token);
    }

    /**
     * @param balances Provided balances
     * @return normalizedBalances Balances multiplied by corresponding multipliers
     */
    function _getNormalizedBalances(
        uint256[] memory balances
    )
        internal
        view
        returns (uint256[] memory normalizedBalances)
    {
        normalizedBalances = new uint256[](N_TOKENS);
        uint256[] memory multipliers = _getMultipliers();
        for (uint256 tokenId = 0; tokenId < N_TOKENS; tokenId++) {
            normalizedBalances[tokenId] = balances[tokenId] * multipliers[tokenId];
        }
    }

    /**
     * @notice Calculates result of token sell
     * @param balances Virtual balances of pool
     * @param tokenIn Address of token to use for swap
     * @param tokenOut Address of token to receive
     * @param amountIn Amount of tokens to sell
     * @return swapResult Amount of tokens received as swap result
     * @return fees Deducted fees
     */
    function _calculateOutGivenIn(
        uint256[] memory balances,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    )
        internal
        view
        returns(uint256 swapResult, uint256 fees)
    {
        fees = amountIn.mulDown(swapFee);
        amountIn = amountIn - fees;
        swapResult = WeightedMath._calcOutGivenIn(
            _normalizedBalance(balances, tokenIn), 
            _getWeight(tokenIn), 
            _normalizedBalance(balances, tokenOut),
            _getWeight(tokenOut), 
            _normalizeAmount(amountIn, tokenIn)
        );

        swapResult = _denormalizeAmount(swapResult, tokenOut);
    }

    /**
     * @notice Calculates result of token buy
     * @param balances Virtual balances of pool
     * @param tokenIn Address of token to use for swap
     * @param tokenOut Address of token to receive
     * @param amountOut Amount of tokens to buy
     * @return amountIn Amount of tokens required to buy amountOut tokens
     * @return fees Deducted fees
     */
    function _calculateInGivenOut(
        uint256[] memory balances,
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    )
        internal
        view
        returns (uint256 amountIn, uint256 fees)
    {
        uint256 amountInWithoutFee = WeightedMath._calcInGivenOut(
            _normalizedBalance(balances, tokenIn), 
            _getWeight(tokenIn), 
            _normalizedBalance(balances, tokenOut), 
            _getWeight(tokenOut), 
            _normalizeAmount(amountOut, tokenOut)
        );

        amountIn = amountInWithoutFee.divDown(ONE - swapFee);
        fees = amountIn - amountInWithoutFee;

        amountIn = _denormalizeAmount(amountIn, tokenIn);
        fees = _denormalizeAmount(fees, tokenIn);
    }

    /**
     * @notice Calculate amount of LP tokens received for initializing pool
     * @dev No fees are collected on initialization
     * @param amounts_ Amount of tokens used for initialization
     * @return lpAmount Amount of LP tokens received
     */
    function _calculateInitialization(
        uint256[] memory amounts_
    )
        internal
        view
        returns (uint256 lpAmount)
    {
        uint256[] memory normalizedAmounts = _getNormalizedBalances(amounts_);

        for (uint256 tokenId = 0; tokenId < N_TOKENS; tokenId++) {
            _require(
                normalizedAmounts[tokenId] != 0,
                Errors.INITIALIZATION_ZERO_AMOUNT
            );
        }

        lpAmount = WeightedMath._calculateInvariant(_getWeights(), normalizedAmounts);
    }

    /**
     * @notice Calculate amount of LP tokens received for initializing pool
     * @dev Fees are collected on joins as they are not perfectly proportional
     * @dev Only one non-zero element in amounts_ is required
     * @param balances Virtual balances of pool
     * @param amounts_ Amount of tokens used for join
     * @return lpAmount Amount of LP tokens received
     * @return fees Deducted fees
     */
    function _calculateJoinPool(
        uint256[] memory balances,
        uint256[] memory amounts_
    )
        internal
        view
        returns (uint256 lpAmount, uint256[] memory fees)
    {
        address[] memory tokens = _getTokens();
        (lpAmount, fees) = WeightedMath._calcBptOutGivenExactTokensIn(
            _getNormalizedBalances(balances), 
            _getWeights(), 
            _getNormalizedBalances(amounts_),
            totalSupply(),
            swapFee
        );

        for (uint256 tokenId = 0; tokenId < N_TOKENS; tokenId++) {
            fees[tokenId] = _denormalizeAmount(fees[tokenId], tokens[tokenId]);
        }
    }

    /**
     * @notice Calculate amount of tokens received on exit
     * @dev No fees are charged as exit is performed in perfect proporion
     * @param balances Virtual balances of pool
     * @param lpAmount Amount of lp tokens to burn
     * @return tokensReceived Amount of tokens received
     */
    function _calculateExitPool(
        uint256[] memory balances,
        uint256 lpAmount
    )
        internal
        view
        returns (uint256[] memory tokensReceived)
    {
        tokensReceived = WeightedMath._calcTokensOutGivenExactBptIn(
            _getNormalizedBalances(balances), 
            lpAmount, 
            totalSupply()
        );
        uint256[] memory multipliers = _getMultipliers();
        for (uint256 tokenId = 0; tokenId < N_TOKENS; tokenId++) {
            tokensReceived[tokenId] /= multipliers[tokenId];
        }
    }
    
    /**
     * @notice Calculate amount of token received on exit
     * @dev Arrays are returned for convenience
     * @dev In arrays there are only one non-zero element
     * @param balances Virtual balances of pool
     * @param token Address of token to receive on exit
     * @param lpAmount Amount of lp tokens to burn
     * @return amountsOut Received amounts
     * @return fees Deducted fees
     */
    function _calculateExitSingleToken(
        uint256[] memory balances,
        address token,
        uint256 lpAmount
    )
        internal
        view
        returns (uint256[] memory amountsOut, uint256[] memory fees)
    {
        amountsOut = new uint256[](N_TOKENS);
        fees = new uint256[](N_TOKENS);
        (uint256 amountOut, uint256 fee) = WeightedMath._calcTokenOutGivenExactBptIn(
            _normalizedBalance(balances, token), 
            _getWeight(token), 
            lpAmount, 
            totalSupply(), 
            swapFee
        );
        amountOut = _denormalizeAmount(amountOut, token);
        fee = _denormalizeAmount(fee, token);
        amountsOut[_getTokenId(token)] = amountOut;
        fees[_getTokenId(token)] = fee;
    }

    /**
     * @notice Mint or burn tokens for user
     * @param user Address of user
     * @param lpAmount Amount of LP tokens to mint/burn
     * @param join True - mint tokens, false - burn tokens
     */
    function _postJoinExit(
        address user,
        uint256 lpAmount,
        bool join
    )
        internal
    {
        if(join) {
            _mint(user, lpAmount); 
        } else {
            _burn(user, lpAmount);
        }
    }

    /*************************************************
                       Modifiers
     *************************************************/

    function _checkTokens(
        address tokenIn, 
        address tokenOut
    ) 
        internal
        view
    {
        _require(
            _getTokenId(tokenIn) != _getTokenId(tokenOut),
            Errors.SAME_TOKEN_SWAP
        );
    }
}   