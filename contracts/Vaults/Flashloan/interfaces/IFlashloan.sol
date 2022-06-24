// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for flashloans
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IFlashloanReceiver} from "./IFlashloanReceiver.sol";

interface IFlashloan {
    /**
     * @notice Initiate flashloan
     * @dev tokens parameter must contain sorted array (in ASCending order) without duplication
     * @dev be careful with tokens that have comission on transfers as you will need to compensate for transfer fees
     * @param receiver Who will receive flashloan
     * @param tokens Array of tokens that will be used for flashloan
     * @param amounts Array with flashloan amounts
     * @param callbackData Data to pass to flashloan receiver
     */
    function flashloan(
        IFlashloanReceiver receiver,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory callbackData
    ) external;
}