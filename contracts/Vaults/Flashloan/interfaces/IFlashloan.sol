// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IFlashloanReceiver} from "./IFlashloanReceiver.sol";

interface IFlashloan {
    function flashloan(
        IFlashloanReceiver receiver,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory callbackData
    ) external;
}