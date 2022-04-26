// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

interface IERC20 {
    function balanceOf(address user) external view returns (uint256 balance);
    function transfer(address to, uint256 amount) external returns(bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

import { WeightedMath } from "./libraries/ConstantProductMath.sol";
import { FixedPoint } from "./utils/FixedPoint.sol";

contract WeightedPool {
    using FixedPoint for uint256;

    address[] public tokens;
    uint256[] public balances;
    uint256[] public weights;
    uint256[] public multipliers;

    uint256 public swapFee;
    uint256 public depositFee;

    function getTokenId(address tokenAddress) external returns (uint256 tokenId) {}

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
        _checkTransferResult(amountIn, received);

        uint256 fee = amountIn.mulDown(swapFee);

        uint256 swapResult = WeightedMath._calcOutGivenIn(
            balances[tokenIn], 
            weights[tokenIn], 
            balances[tokenOut],
            weights[tokenOut], 
            amountIn - fee
        );

        require(
            swapResult >= minAmountOut,
            "Not enough tokens received"
        );

        uint256 sent = _transferAndCheckBalances(
            tokens[tokenOut], 
            address(this), 
            msg.sender, 
            swapResult, 
            false
        );
        _checkTransferResult(swapResult, sent);

        _changeBalance(tokenIn, amountIn, true);
        _changeBalance(tokenOut, swapResult, false);
        
        return swapResult;
    }

    function _changeBalance(
        uint256 tokenId,
        uint256 amount,
        bool positive
    ) internal {
        balances[tokenId] = positive ? balances[tokenId] + amount : balances[tokenId] - amount;
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

    function swapExactOut(
        uint256 tokenIn,
        uint256 tokenOut,
        uint256 amountOut,
        uint256 amountOutMax,
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
        uint256 amountIn = amountInWithoutFee.div
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
        return balanceOut - balanceIn;
    }

    function calculateSwap(
        uint256 tokenIn,
        uint256 tokenOut,
        uint256 amountIn,
        bool exactIn
    )
        external
        returns(uint256 amountOut)
    {
        // TODO: get fees
        // TODO: calculate swap
        return 0;
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