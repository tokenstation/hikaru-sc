// SPDX-License-Identifier: GPL-3.0-or-later
// @title Contract for performing flashloans
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IFlashloan, IFlashloanReceiver } from "./interfaces/IFlashloan.sol";
import { FixedPoint } from "../../utils/Math/FixedPoint.sol";
import { ReentrancyGuard } from "../../utils/ReentrancyGuard.sol";
import { ArrayUtils } from "../../utils/libraries/ArrayUtils.sol";

import "../ProtocolFees/ProtocolFees.sol";
import "../../utils/Errors/ErrorLib.sol";

interface IFlashloanManager {

    /**
     * @notice Set new flashloan fees coefficient
     * @param flashloanFees New flashloan fees coefficient
     */
    function setFlashloanFees(uint256 flashloanFees) external;
}

abstract contract Flashloan is ProtocolFees, ReentrancyGuard, IFlashloan, IFlashloanManager {

    event FlashloanFeesUpdate(uint256 indexed newFlashloanFees);

    using FixedPoint for uint256;

    uint256 public flashloanFee;

    constructor(
        uint256 flashloanFee_
    ) {
        _setFlashloanFees(flashloanFee_);
    }

    /**
     * @inheritdoc IFlashloan
     */
    function flashloan(
        IFlashloanReceiver receiver,
        IERC20[] memory tokens, 
        uint256[] memory amounts, 
        bytes memory callbackData
    ) 
        external
        override
        reentrancyGuard
    {
        uint256 flashloanFee_ = flashloanFee;
        uint256[] memory fees = new uint256[](tokens.length);
        uint256[] memory initBalances = new uint256[](tokens.length);

        ArrayUtils.checkUniqueness(tokens);
        ArrayUtils.checkZeroElement(amounts);

        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            initBalances[tokenId] = tokens[tokenId].balanceOf(address(this));
            fees[tokenId] = _calculateFee(amounts[tokenId], flashloanFee_);
            IERC20(tokens[tokenId]).transfer(address(receiver), amounts[tokenId]);
        }

        receiver.receiveFlashLoan(tokens, amounts, fees, callbackData);

        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            uint256 balanceAfter = tokens[tokenId].balanceOf(address(this));
            _require(
                balanceAfter >= initBalances[tokenId] + fees[tokenId],
                Errors.NOT_ENOUGH_FEE_RECEIVED
            );
            _addProtocolFee(address(tokens[tokenId]), balanceAfter - initBalances[tokenId]);
        } 
    }

    /**
     * @notice Set new flashloan fee coefficient
     * @param flashloanFees_ Flashloan fee coefficient
     */
    function _setFlashloanFees(
        uint256 flashloanFees_
    )
        internal
    {
        _require(
            flashloanFees_ <= FixedPoint.ONE,
            Errors.FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH
        );
        emit FlashloanFeesUpdate(flashloanFees_);
        flashloanFee = flashloanFees_;
    }
}