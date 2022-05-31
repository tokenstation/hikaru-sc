// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IFlashloan, IFlashloanReceiver } from "./interfaces/IFlashloan.sol";
import { FixedPoint } from "../../utils/Math/FixedPoint.sol";
import { ReentrancyGuard } from "../../utils/ReentrancyGuard.sol";

interface IFlashloanManager {
    
    function setFeeReceiver(address newFeeReceiver) external;

    function setFlashloanFees(uint256 flashloanFees) external;
}

abstract contract Flashloan is ReentrancyGuard, IFlashloan, IFlashloanManager {

    // TODO: add external fee receiver setters in vault
    // TODO: add mechanism for setting fees for flashloans

    using FixedPoint for uint256;

    address feeReceiver;
    uint256 public flashloanFee;

    constructor(
        address feeReceiver_,
        uint256 flashloanFee_
    ) {
        _setFeeReceiver(feeReceiver_);
        _setFlashloanFees(flashloanFee_);
    }

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
        uint256[] memory fees = new uint256[](tokens.length);
        uint256[] memory initBalances = new uint256[](tokens.length);
        address token = address(1);

        // TODO: use function checkUniqueness from future library
        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            _checkTokens(token, address(tokens[tokenId]));
            token = address(tokens[tokenId]);
            initBalances[tokenId] = tokens[tokenId].balanceOf(address(this));
            fees[tokenId] = _getFee(amounts[tokenId]);
            IERC20(tokens[tokenId]).transfer(address(receiver), amounts[tokenId]);
        }

        receiver.receiveFlashLoan(tokens, amounts, fees, callbackData);

        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            uint256 balanceAfter = tokens[tokenId].balanceOf(address(this));
            require(
                balanceAfter >= initBalances[tokenId] + fees[tokenId],
                "Invalid amount repaid"
            );
            tokens[tokenId].transfer(feeReceiver, balanceAfter - initBalances[tokenId]);
        } 
    }

    function _setFeeReceiver(
        address newFeeReceiver
    ) 
        internal
    {
        require(
            newFeeReceiver != address(0),
            "Fee receiver cannot be zero address"
        );
        feeReceiver = newFeeReceiver;
    }

    function _setFlashloanFees(
        uint256 flashloanFees_
    )
        internal
    {
        flashloanFee = flashloanFees_;
    }

    function _checkTokens(
        address token1,
        address token2
    ) 
        internal 
        pure
    {
        require(
            token1 != address(0) &&
            token1 < token2,
            "Unsorted array or token duplication"
        );
    }

    function _getFee(
        uint256 amount
    )
        internal
        view
        returns(uint256 fee)
    {
        fee = amount.mulDown(flashloanFee);
    }
}