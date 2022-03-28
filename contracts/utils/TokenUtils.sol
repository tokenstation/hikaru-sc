// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity 0.8.13;

library TokenUtils {
    function getTokenDecimals(address token) internal view returns(uint8) {
        return IERC20Metadata(token).decimals();
    }

    function transferAndGetBalanceDelta(address token, address from, uint256 amount) internal returns(uint256 balanceDelta) {
        balanceDelta = IERC20(token).balanceOf(address(this));
        IERC20(token).transferFrom(from, address(this), amount);
        balanceDelta = IERC20(token).balanceOf(address(this)) - balanceDelta;
    }

    function transferTokens(address token, address to, uint256 amount) internal {
        IERC20(token).transfer(to, amount);
    }
}