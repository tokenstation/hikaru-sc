// SPDX-License-Identifier: GPL-3.0-or-later
// @title Library for token transfers and calculating balance delta
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "./SafeERC20.sol";
import "../Errors/ErrorLib.sol";


library TokenUtils {
    using SafeERC20 for IERC20;

    /**
     * @notice Transfer tokens from user and return balance difference
     * @dev Function is mainly designed for tokens with comissions
     * @param tokenIn Token that will be transferred
     * @param user Address of user
     * @param amountIn Amount of tokens to transfer from user
     * @return Amount of tokens that were really transferred
     */
    function transferFromUser(
        IERC20 tokenIn,
        address user,
        uint256 amountIn
    ) 
        internal
        returns(uint256)
    {
        if (amountIn == 0) return 0;
        uint256 balanceBefore = tokenIn.balanceOf(address(this));
        tokenIn.safeTransferFrom(user, address(this), amountIn);
        uint256 balanceAfter = tokenIn.balanceOf(address(this));
        _require(
            balanceAfter >= balanceBefore,
            Errors.ERC20_INVALID_TRANSFER_FROM_BALANCE_CHANGE
        );
        return balanceAfter - balanceBefore;
    }

    /**
     * @notice Transfer tokens to user and return balance difference
     * @dev Function is mainly designed for tokens with comissions
     * @param tokenOut Token that will be transferred
     * @param user Address of user
     * @param amountOut Amount of tokens to transfer to user
     * @return Amount of tokens that were really transferred
     */
    function transferToUser(
        IERC20 tokenOut,
        address user,
        uint256 amountOut
    )
        internal
        returns(uint256)
    {
        if (amountOut == 0) return 0;
        uint256 balanceBefore = tokenOut.balanceOf(address(this));
        tokenOut.safeTransfer(user, amountOut);
        uint256 balanceAfter = tokenOut.balanceOf(address(this));
        _require(
            balanceBefore >= balanceAfter,
            Errors.ERC20_INVALID_TRANSFER_BALANCE_CHANGE
        );
        return balanceBefore - balanceAfter;
    }
}