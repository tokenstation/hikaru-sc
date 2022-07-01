// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for flashloan receiver
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IFlashloanReceiver {
    /**
     * @notice Receiver's callback function
     * @dev Flashloan receiver must inherit this interface
     * @param tokens Array of tokens that were transferred to receiver
     * @param amounts Array of token amounts transferred to receiver
     * @param fees Fees that must be repaid
     * @param userData Payload provided on flashloan call
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory fees,
        bytes memory userData
    ) external;
}