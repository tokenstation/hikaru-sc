// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { FixedPoint } from "../../utils/Math/FixedPoint.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { TokenUtils } from "../../utils/libraries/TokenUtils.sol";

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

    function _deductFees(
        address[] memory tokens,
        uint256[] memory amounts
    )
        internal
        returns (uint256[] memory deductedFees)
    {
        uint256 _protocolFee = protocolFee;
        if (_protocolFee == 0) return amounts;

        deductedFees = new uint256[](tokens.length);
        for (uint256 id = 0; id < tokens.length; id++) {
           deductedFees[id] = _deductFee(tokens[id], amounts[id], _protocolFee);
        }
    }

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

    function setProtocolFee(uint256 newProtocolFee) external virtual;
    function _setProtocolFee(
        uint256 newProtocolFee
    )
        internal
    {
        emit ProtocolFeeUpdate(newProtocolFee);
        protocolFee = newProtocolFee;
    }

    function withdrawCollectedFees(
        address[] memory tokens,
        uint256[] memory amounts,
        address[] memory to
    ) external virtual;
    function _withdrawCollectedFees(
        address[] memory tokens,
        uint256[] memory amounts,
        address[] memory to
    )
        internal
    {
        for (uint256 id = 0; id < tokens.length; id++) {
            require(
                amounts[id] <= collectedFees[tokens[id]],
                "Cannot withdraw more than accumulated"
            );
            IERC20 token = IERC20(tokens[id]);
            token.transferToUser(to[id], amounts[id]);
            collectedFees[tokens[id]] -= amounts[id];
        }
    }
}