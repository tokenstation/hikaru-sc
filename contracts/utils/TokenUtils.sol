// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity 0.8.13;

library TokenUtils {
    function transferFromUser(
        IERC20 tokenIn,
        uint256 amountIn,
        address user
    ) 
        internal
    {
        IERC20 tokenContract = IERC20(tokenIn);
        uint256 balanceBefore = tokenContract.balanceOf(address(this));
        tokenContract.transferFrom(user, address(this), amountIn);
        uint256 balanceAfter = tokenContract.balanceOf(address(this));
        _checkIfTransferOk(
            balanceAfter - balanceBefore == amountIn
        );
    }

    function transferToUser(
        IERC20 tokenOut,
        uint256 amountOut,
        address user
    )
        internal
    {
        IERC20 tokenContract = IERC20(tokenOut);
        uint256 balanceBefore = tokenContract.balanceOf(address(this));
        tokenContract.transfer(user, amountOut);
        uint256 balanceAfter = tokenContract.balanceOf(address(this));
        _checkIfTransferOk(
            balanceBefore - balanceAfter == amountOut
        );
    }

    function _checkIfTransferOk(
        bool transferResult
    ) 
        internal
        pure
    {
        require(
            transferResult,
            "Invalid amount of tokens "
        );
    }
}