// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

import { IERC20, IERC20Metadata, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IWeightedPoolLP } from "./interfaces/IWeightedPoolLP.sol";
import { WeightedMath } from "./libraries/ConstantProductMath.sol";
import { FixedPoint } from "../../utils/Math/FixedPoint.sol";
import { WeightedStorage } from "./WeightedStorage.sol";

abstract contract BaseWeightedPool is IWeightedPoolLP, WeightedStorage {
    
    event FeesUpdate(uint256 newSwapFee, uint256 newDepositFee);

    using FixedPoint for uint256;

    uint256 internal constant ONE = 1e18;

    uint256[] public balances;

    uint256 public swapFee;
    uint256 public depositFee;

    function _setPoolFees(
        uint256 swapFee_,
        uint256 depositFee_
    ) 
        internal
    {
        swapFee = swapFee_;
        depositFee = depositFee_;
        emit FeesUpdate(swapFee_, depositFee_);
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
        swapResult = WeightedMath._calcOutGivenIn(
            normalizedBalance(tokenIn), 
            _getWeight(tokenIn), 
            normalizedBalance(tokenOut),
            _getWeight(tokenOut), 
            amountIn
        );

        fees = swapResult.mulDown(swapFee);
        swapResult = swapResult - fees;

        swapResult = denormalizeAmount(swapResult, tokenIn);
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
            amountOut
        );

        amountIn = amountInWithoutFee.divDown(ONE - swapFee);
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

    /*************************************************
                      ERC20 external functions
     *************************************************/

    function mint(
        address user,
        uint256 amount
    )
        external
        override
        onlyVault(msg.sender)
    {
        _mint(user, amount);
    }

    function burn(
        address user,
        uint256 amount
    )
        external
        override
        onlyVault(msg.sender)
    {
        _burn(user, amount);
    }
}   