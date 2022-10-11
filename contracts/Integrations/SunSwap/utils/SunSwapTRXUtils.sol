// SPDX-License-Identifier: GPL-3.0-or-later
// @title TRX utilities for SunSwap integration
// @author tokenstation.dev

pragma solidity 0.8.6;

import "../interfaces/ITRXWrapper.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract SunSwapTRXUtils {
    using Address for address payable;

    // Contract for wrapping/unwrapping TRX
    ITRXWrapper immutable public trxWrapper;


    constructor(
        ITRXWrapper trxWrapper_
    ) {
        trxWrapper = trxWrapper_;
    }

    function isWTRX(address token) internal view returns (bool) {
        return token == address(trxWrapper);
    } 

    function wrapAmount(
        uint256 amount
    ) 
        internal 
        returns (uint256)
    {
        payable(address(trxWrapper)).sendValue(amount);
        return amount;
    } 

    function unwrapAmount(
        uint256 amount
    )
        internal
        returns (uint256)
    {
        trxWrapper.withdraw(amount);
        return amount;
    }

    function transferWTRX(
        address receiver,
        uint256 amount
    )
        internal
        returns (uint256)
    {
        IERC20(address(trxWrapper)).transfer(receiver, amount);
        return amount;
    }
}