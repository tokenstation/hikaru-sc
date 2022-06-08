// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20, IERC20Metadata, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IWeightedPoolLP } from "./interfaces/IWeightedPoolLP.sol";
import { WeightedMath } from "./libraries/WeightedMath.sol";
import { FixedPoint } from "../../utils/Math/FixedPoint.sol";
import { WeightedStorage } from "./WeightedStorage.sol";

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

    function _setSwapFee(
        uint256 swapFee_
    ) 
        internal
    {
        require(
            swapFee_ <= MAX_SWAP_FEE,
            "Swap fee must be lte 5e15"
        );
        swapFee = swapFee_;
        emit SwapFeeUpdate(swapFee_);
    }

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

    function _calculateInitialization(
        uint256[] memory amounts_
    )
        internal
        view
        returns (uint256 lpAmount)
    {
        uint256[] memory normalizedAmounts = _getNormalizedBalances(amounts_);

        for (uint256 tokenId = 0; tokenId < N_TOKENS; tokenId++) {
            require(
                normalizedAmounts[tokenId] != 0,
                "Cannot initialize pool with zero token valut"
            );
        }

        lpAmount = WeightedMath._calculateInvariant(_getWeights(), normalizedAmounts);
    }

    function _calculateJoinPool(
        uint256[] memory balances,
        uint256[] memory amounts_
    )
        internal
        view
        returns (uint256 lpAmount)
    {
        (lpAmount, ) = WeightedMath._calcBptOutGivenExactTokensIn(
            _getNormalizedBalances(balances), 
            _getWeights(), 
            amounts_,
            totalSupply(),
            swapFee
        );
    }

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
    
    function _calculateExitSingleToken(
        uint256[] memory balances,
        address token,
        uint256 lpAmount
    )
        internal
        view
        returns (uint256[] memory amountsOut)
    {
        amountsOut = new uint256[](N_TOKENS);
        (uint256 amountOut,) = WeightedMath._calcTokenOutGivenExactBptIn(
            _normalizedBalance(balances, token), 
            _getWeight(token), 
            lpAmount, 
            totalSupply(), 
            swapFee
        );
        amountOut = _denormalizeAmount(amountOut, token);
        amountsOut[_getTokenId(token)] = amountOut;
    }

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
        require(
            tokenIn != tokenOut,
            "Cannot swap token to itself!"
        );
        require(
            _getTokenId(tokenIn) >= 0,
            "Token in is not presented in pool."
        );
        require(
            _getTokenId(tokenOut) >= 0,
            "Token out is not presented in pool."
        );
    }
}   