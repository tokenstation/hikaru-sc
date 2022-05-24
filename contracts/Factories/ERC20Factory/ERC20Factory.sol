// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { ILPTokenFactory } from "./interfaces/ILPTokenFactory.sol";
import { LPTokenERC20 } from "./LPToken.sol";

contract LPTokenFactory is ILPTokenFactory {
    function createNewToken(
        address vault, 
        string memory name,
        string memory symbol
    )
        external
        override
        returns (address tokenAddress)
    {
        tokenAddress = address(new LPTokenERC20(vault, name, symbol));
    }
}