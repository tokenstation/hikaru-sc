// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

import { IERC20, IERC20Metadata, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { WeightedMath } from "./libraries/ConstantProductMath.sol";
import { FixedPoint } from "./utils/FixedPoint.sol";
import { WeightedStorage } from "./utils/WeightedStorage.sol";

abstract contract BaseWeightedPool is WeightedStorage, ERC20 {

    event Swap(address tokenIn, address tokenOut, uint256 received, uint256 sent, address user);
    event Deposit(uint256 lpAmount, uint256[] received, address user);
    event Withdraw(uint256 lpAmount, uint256[] withdrawn, address user);
    
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

    // TODO: remove function
    function normalizedBalance(
        address token
    )
        internal
        view
        returns (uint256 normalizedBalance_)
    {
        normalizedBalance_ = balances[getTokenId(token)] * getMultiplier(token);
    }

    function denormalizeAmount(
        uint256 amount,
        address token
    )
        internal
        view
        returns (uint256 denormalizedAmount)
    {
        denormalizedAmount = amount / getMultiplier(token);
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
            getWeight(tokenIn), 
            normalizedBalance(tokenOut),
            getWeight(tokenOut), 
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
            getWeight(tokenIn), 
            normalizedBalance(tokenOut), 
            getWeight(tokenOut), 
            amountOut
        );

        amountIn = amountInWithoutFee.divDown(ONE - swapFee);
        fees = amountIn - amountInWithoutFee;
    }

    function _transferSwapTokens(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut
    )
        internal
    {
        _transferAndCheckBalances(
            tokenIn,
            msg.sender,
            address(this),
            amountIn,
            true
        );
        _transferAndCheckBalances(
            tokenOut,
            address(this),
            msg.sender,
            amountOut,
            false
        );
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

        emit Swap(tokenIn, tokenOut, amountIn, amountOut, msg.sender);
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
            getTokenId(tokenIn) >= 0,
            "Token in is not presented in pool."
        );
        require(
            getTokenId(tokenOut) >= 0,
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
        uint256 tokenId = getTokenId(token);
        balances[tokenId] = positive ? balances[tokenId] + amount : balances[tokenId] - amount;
    }

    function _transferAndCheckBalances(
        address token,
        address from,
        address to,
        uint256 amount,
        bool transferFrom_
    ) 
        internal  
        returns (uint256 transferred)
    {
        if (amount == 0) return 0;

        uint256 balanceIn = IERC20(token).balanceOf(to);
        if (transferFrom_) {
            IERC20(token).transfer(to, amount);
        } else {
            IERC20(token).transferFrom(from, to, amount);
        }
        uint256 balanceOut = IERC20(token).balanceOf(to);
        transferred = balanceOut - balanceIn;
        _checkTransferResult(amount, transferred);
    }

    function _checkTransferResult(
        uint256 expected,
        uint256 transferred
    )
        internal
        pure
    {
        require(
            expected == transferred,
            "Tokens with transfer fees are not supported in this pool"
        );
    }
}   