// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

interface IERC20 {
    function balanceOf(address user) external view returns (uint256 balance);
    function transfer(address to, uint256 amount) external returns(bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

import { WeightedMath } from "./libraries/ConstantProductMath.sol";
import { FixedPoint } from "./utils/FixedPoint.sol";

contract WeightedPool {
    using FixedPoint for uint256;

    uint256 internal constant ONE = 1e18;

    address[] public immutable tokens;
    uint256[] public balances;
    uint256[] public weights;
    uint256[] public multipliers;

    uint256 public swapFee;
    uint256 public depositFee;

    constructor(
        address[] calldata tokens_,
        uint256[] calldata weights_,
        uint256 swapFee_,
        uint256 depositFee_
    ) {
        require(
            tokens_.length == weights_.length
            "Array length mismatch"
        );
        uint256 weightSum = 0;
        for(uint256 tokenId = 0; tokenId < weights_.length; tokenId++) {
            weightSum += weights[tokenId];
        }
        require(
            weightSum == ONE,
            "Weight sum is not equal to 1e18 (ONE)"
        );
        multipliers = new uint256[](tokens_.length);
        for (uint256 tokenId = 0; tokenId < tokens_.length; tokenId++) {
            multipliers[tokenId] = 10 ** (18 - IERC20(tokens[tokenId]).decimals());
        }
        tokens = tokens_;
        weights = weights_;
        swapFee = swapFee_;
        depositFee = depositFee_;
    }

    function getTokenId(address tokenAddress) external returns (uint256 tokenId) {
        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            if (tokens[tokenId] == tokenAddress) return tokenId;
        }
        require(
            false,
            "There is no token with provided token address"
        );
    }

    modifier checkDeadline(uint64 deadline) {
        require(
            block.timestamp <= deadline,
            "Cannot swap, deadline passed"
        );
        _;
    }

    modifier checkTokenIds(uint256[2] memory tokenIds) {
        for(uint256 id = 0; id < 2; id++) {
            require(
                tokenIds[id] < tokens.length,
                "There is no token with provided token id"
            );
        }
        _;
    }

    function normalizeBalance(
        uint256 amount,
        uint256 tokenId
    )
        internal
        view
        returns (uint256 normalizedBalance)
    {
        normalizedBalance = balances[tokenId] * multipliers[tokenId];
    }


    function swap(
        uint256 tokenIn,
        uint256 tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint64 deadline
    ) 
        external
        checkDeadline(deadline)
        checkTokenIds([tokenIn, tokenOut])
        returns (uint256 amountOut)
    {
        uint256 received = _transferAndCheckBalances(
            tokens[tokenIn],
            msg.sender,
            address(this),
            amountIn,
            true
        );

        uint256 swapResult = WeightedMath._calcOutGivenIn(
            balances[tokenIn], 
            weights[tokenIn], 
            balances[tokenOut],
            weights[tokenOut], 
            amountIn
        );

        uint256 fee = swapResult.mulDown(swapFee);
        uint256 swapResultWithoutFee = swapResult - fee;

        require(
            swapResultWithoutFee >= minAmountOut,
            "Not enough tokens received"
        );

        uint256 sent = _transferAndCheckBalances(
            tokens[tokenOut], 
            address(this), 
            msg.sender, 
            swapResultWithoutFee, 
            false
        );

        _changeBalance(tokenIn, amountIn, true);
        _changeBalance(tokenOut, swapResultWithoutFee, false);
        
        return swapResult;
    }

    function _changeBalance(
        uint256 tokenId,
        uint256 amount,
        bool positive
    ) internal {
        balances[tokenId] = positive ? balances[tokenId] + amount : balances[tokenId] - amount;
    }

    function swapExactOut(
        uint256 tokenIn,
        uint256 tokenOut,
        uint256 amountOut,
        uint256 amountInMax,
        uint64 deadline
    )
        external
        checkDeadline(deadline)
        checkTokenIds([tokenIn, tokenOut])
        returns (uint256 amountIn)
    {
        uint256 amountInWithoutFee = WeightedMath._calcInGivenOut(
            balances[tokenIn], 
            weights[tokenIn], 
            balances[tokenOut], 
            weights[tokenOut], 
            amountOut
        );

        // full = part / (1 - swapFee)
        uint256 amountIn = amountInWithoutFee.divDown(ONE - swapFee);
        require(
            amountIn <= amountInMax,
            "Too much tokens is used for swap"
        );

        uint256 received = _transferAndCheckBalances(
            tokens[tokenIn],
            msg.sender,
            address(this),
            amountIn,
            true
        );

        uint256 sent = _transferAndCheckBalances(
            tokens[tokenOut],
            address(this)
            msg.sender,
            amountOut,
            false
        );

        _changeBalance(tokenIn, amountIn, true);
        _changeBalance(tokenOut, amountOut, false);

        return amountIn;
    }

    function _transferAndCheckBalances(
        address token,
        address from,
        address to,
        uint256 amount,
        bool transferFrom
    ) 
        internal  
        returns (uint256 transferred)
    {
        uint256 balanceIn = IERC20(token).balanceOf(to);
        if (transferFrom) {
            IERC20(token).transfer(to, amount);
        } else {
            IERC20(token).transferFrom(from, to, amount);
        }
        uint256 balanceOut = IERC20(token).balanceOf(to);
        uint256 transferred = balanceOut - balanceIn;
        _checkTransferResult(amount, transferred)
        return transferred;
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

    function calculateSwap(
        uint256 tokenIn,
        uint256 tokenOut,
        uint256 swapAmount,
        bool exactIn
    )
        external
        returns(uint256 swapResult, uint256 fee)
    {
        if (exactIn) {
            uint256 amountOut = WeightedMath._calcOutGivenIn(
                balances[tokenIn], 
                weights[tokenIn], 
                balances[tokenOut],
                weights[tokenOut], 
                swapAmount
            );
            fee = amountOut.mulDown(swapFee);
            swapResult -= fee;
        } else {
            uint256 amountIn = WeightedMath._calcInGivenOut(
                balances[tokenIn],
                weights[tokenIn],
                balances[tokenOut],
                weights[tokenOut],
                swapAmount
            );
            swapResult = amountIn.divDown(ONE - swapFee);
            fee = swapResult - swapAmount;
        }
        
    }

    function addOrRemoveToken(
        uint256 token,
        uint256 amount,
        bool add
    )
        external
        returns(uint256 mintedAmount)
    {
        // TODO: check if we want to add or to remove tokens
        // TODO: prechecks
        // TODO: calculate amount of tokens to deposit/use for swap
        // TODO: calculate minted amount
        return 0;
    }

    function addOrRemoveTokens(
        uint256[] calldata token,
        uint256[] memory amounts,
        bool add
    )
        external
        returns(uint256 mintedAmount)
    {
        // TODO: check if we want to add or to remove tokens
        // TODO: prechecks
        // TODO: calculate amount of tokens to deposit/remove
        // TODO: calculate burnt amount and burn it
        return 0;
    }
}   