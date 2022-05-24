// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity 0.8.6;

library TokenUtils {
    function transferFromUser(
        IERC20 tokenIn,
        address user,
        uint256 amountIn
    ) 
        internal
        returns(uint256)
    {
        IERC20 tokenContract = IERC20(tokenIn);
        uint256 balanceBefore = tokenContract.balanceOf(address(this));
        tokenContract.transferFrom(user, address(this), amountIn);
        uint256 balanceAfter = tokenContract.balanceOf(address(this));
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
        IERC20 tokenContract = IERC20(tokenOut);
        uint256 balanceBefore = tokenContract.balanceOf(address(this));
        tokenContract.transfer(user, amountOut);
        uint256 balanceAfter = tokenContract.balanceOf(address(this));
        return balanceBefore - balanceAfter;
    }
}