// SPDX-License-Identifier: GPL-3.0-or-later
// @title Contract for deducting protocol fees
// @author tokenstation.dev

pragma solidity 0.8.6;

import { FixedPoint } from "../../utils/Math/FixedPoint.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { TokenUtils } from "../../utils/libraries/TokenUtils.sol";
import "../../utils/Errors/ErrorLib.sol";

abstract contract ProtocolFees {
    using FixedPoint for uint256;
    using TokenUtils for IERC20;

    event ProtocolFeeUpdate(uint256 newProtocolFee);

    uint256 public protocolFee;
    mapping (address => uint256) public collectedFees;

    constructor(
        uint256 protocolFee_
    ) {
        _setProtocolFee(protocolFee_);
    }

    /**
     * @notice Deduct fees for provided token amounts
     * @param tokens Array of token addresses
     * @param amounts Array of token amounts
     * @return deductedFees Array with deducted fees
     */
    function _deductFees(
        address[] memory tokens,
        uint256[] memory amounts
    )
        internal
        returns (uint256[] memory deductedFees)
    {
        uint256 _protocolFee = protocolFee;
        deductedFees = new uint256[](tokens.length);

        for (uint256 id = 0; id < tokens.length; id++) {
           deductedFees[id] = _deductFee(tokens[id], amounts[id], _protocolFee);
        }
    }

    /**
     * @notice Deduct fee for specific token
     * @dev This function writes deducted fee to storage
     * @param token Address of token to deduct fee
     * @param amount Amount to deduct fee from
     * @param _protocolFee Protocol fee coefficient
     * @return deductedFee Deducted fees
     */
    function _deductFee(
        address token,
        uint256 amount,
        uint256 _protocolFee
    )
        internal
        returns (uint256 deductedFee)
    {
        if (_protocolFee == 0 || amount == 0) return 0;
        deductedFee = amount.mulDown(_protocolFee);
        collectedFees[token] += deductedFee;
    }

    /**
     * @notice Set new protocol fee
     * @param newProtocolFee protocol fee coefficient
     */
    function setProtocolFee(uint256 newProtocolFee) external virtual;
    /**
     * @notice Set new protocol fee
     * @param newProtocolFee protocol fee coefficient
     */
    function _setProtocolFee(
        uint256 newProtocolFee
    )
        internal
    {
        _require(
            newProtocolFee <= FixedPoint.ONE,
            Errors.PROTOCOL_FEE_TOO_HIGH
        );
        emit ProtocolFeeUpdate(newProtocolFee);
        protocolFee = newProtocolFee;
    }

    /**
     * @notice Transfer collected fees to provided addresses
     * @dev Array length must be the same
     * @param tokens Array of tokens to transfer
     * @param amounts Amounts to transfer
     * @param to Whete to transfer tokens
     */
    function withdrawCollectedFees(
        address[] memory tokens,
        uint256[] memory amounts,
        address[] memory to
    ) external virtual;
    /**
     * @notice Transfer collected fees to provided addresses
     * @dev Array length must be the same
     * @param tokens Array of tokens to transfer
     * @param amounts Amounts to transfer
     * @param to Whete to transfer tokens
     */
    function _withdrawCollectedFees(
        address[] memory tokens,
        uint256[] memory amounts,
        address[] memory to
    )
        internal
    {
        for (uint256 id = 0; id < tokens.length; id++) {
            _require(
                amounts[id] <= collectedFees[tokens[id]],
                Errors.TOO_MUCH_FEE_WITHDRAWN
            );
            IERC20 token = IERC20(tokens[id]);
            token.transferToUser(to[id], amounts[id]);
            collectedFees[tokens[id]] -= amounts[id];
        }
    }
}