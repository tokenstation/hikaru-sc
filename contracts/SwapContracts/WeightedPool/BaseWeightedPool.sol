// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

import { IERC20, IERC20Metadata, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IWeightedPoolLP } from "./interfaces/IWeightedPoolLP.sol";
import { WeightedMath } from "./libraries/WeightedMath.sol";
import { FixedPoint } from "../../utils/Math/FixedPoint.sol";
import { WeightedStorage } from "./WeightedStorage.sol";

abstract contract BaseWeightedPool is WeightedStorage {
    
    event FeesUpdate(uint256 newSwapFee);

    using FixedPoint for uint256;

    uint256 internal constant ONE = 1e18;

    uint256 public lpBalance;

    uint256 public swapFee;

    uint256[] public balances;

    constructor(
        uint256 swapFee_
    ) {
        _setPoolFees(swapFee_);
    }

    function _setPoolFees(
        uint256 swapFee_
    ) 
        internal
    {
        swapFee = swapFee_;
        emit FeesUpdate(swapFee_);
    }

    function normalizedBalance(
        address token
    )
        internal
        view
        returns (uint256 normalizedBalance_)
    {
        normalizedBalance_ = balances[_getTokenId(token)] * _getMultiplier(token);
    }

    function normalizeAmount(
        uint256 amount,
        address token
    )
        internal
        view
        returns (uint256 normalizedAmount)
    {
        normalizedAmount = amount * _getMultiplier(token);
    }

    function denormalizeAmount(
        uint256 amount,
        address token
    )
        internal
        view
        returns (uint256 denormalizedAmount)
    {
        denormalizedAmount = amount / _getMultiplier(token);
    }

    function _calculateOutGivenIn(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    )
        internal
        view
        returns(uint256 swapResult, uint256 fees)
    {
        amountIn = amountIn.sub(amountIn.mulDown(swapFee));
        swapResult = WeightedMath._calcOutGivenIn(
            normalizedBalance(tokenIn), 
            _getWeight(tokenIn), 
            normalizedBalance(tokenOut),
            _getWeight(tokenOut), 
            normalizeAmount(amountIn, tokenIn)
        );

        swapResult = denormalizeAmount(swapResult, tokenOut);
        fees = denormalizeAmount(fees, tokenIn);
    }

    function _calculateInGivenOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    )
        internal
        view
        returns (uint256 amountIn, uint256 fees)
    {
        uint256 amountInWithoutFee = WeightedMath._calcInGivenOut(
            normalizedBalance(tokenIn), 
            _getWeight(tokenIn), 
            normalizedBalance(tokenOut), 
            _getWeight(tokenOut), 
            normalizeAmount(amountOut, tokenOut)
        );

        amountIn = denormalizeAmount(
            amountInWithoutFee.divDown(ONE - swapFee),
            tokenIn
        );
        fees = amountIn - amountInWithoutFee;
    }

    function _postSwap(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut
    )
        internal
    {
        _changeBalance(tokenIn, amountIn, true);
        _changeBalance(tokenOut, amountOut, false);
    }

    function _postJoinExit(
        uint256 lpAmount,
        uint256[] memory tokenDeltas,
        bool join
    )
        internal
    {
        address[] memory tokens = _getTokens();
        for (uint256 tokenId = 0; tokenId < N_TOKENS; tokenId++) {
            _changeBalance(tokens[tokenId], tokenDeltas[tokenId], join);
        }   

        lpBalance = join ? lpBalance + lpAmount : lpBalance - lpAmount;
    }

    /*************************************************
                       Modifiers
     *************************************************/

    modifier checkDeadline(uint64 deadline) {
        require(
            block.timestamp <= deadline,
            "Cannot swap, deadline passed"
        );
        _;
    }

    modifier checkTokens(address tokenIn, address tokenOut) {
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
        _;
    }

    /*************************************************
                      Util functions
     *************************************************/

    function _changeBalance(
        address token,
        uint256 amount,
        bool positive
    ) internal {
        uint256 tokenId = _getTokenId(token);
        balances[tokenId] = positive ? balances[tokenId] + amount : balances[tokenId] - amount;
    }
}   