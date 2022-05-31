// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "./SafeERC20.sol";


library TokenUtils {
    using SafeERC20 for IERC20;

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
        return balanceAfter - balanceBefore;
    }

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
        return balanceBefore - balanceAfter;
    }
}