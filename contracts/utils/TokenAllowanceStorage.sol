// SPDX-License-Identifier: GPL-3.0-or-later
// @title Router for default interfaces defined in v0.6 for vaults
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

enum TokenAllowanceStatus {NO_ALLOWANCE, REQUIRES_ALLOWANCE_EVERY_TIME, INF_ALLOWANCE}

contract TokenAllowancesStorage {
    constructor() {}

    uint256 constant MAX_UINT256 = type(uint256).max;
    mapping(address => mapping(address => TokenAllowanceStatus)) public _tokenAllowances;

    /**
     * @dev Here we check token allowances to vaults before executing operations
     * There are three token allowance types:
     * 1. INF_ALLOWANCES -> if token allowes uint256 approve
     * 2. REQUIRES_APPROVE_EVERY_TIME -> if it's not possible to set uint256 allowance,
     * most likely token uses uint96, which is ~8e28 (10 billion tokens with 18 decimals), which may not be enough
     * so we perform approve on every operation
     * 3. NO_ALLOWANCE -> there was no attempt of setting allowance
     *
     * Generally it will save gas for users as it mostly will require only read from storage
     */
    function _checkTokenAllowance(
        address tokenAddress,
        uint256 amount,
        address vault
    )
        internal
    {
        TokenAllowanceStatus ts = _tokenAllowances[vault][tokenAddress];
        if (ts == TokenAllowanceStatus.INF_ALLOWANCE) return;

        IERC20 token = IERC20(tokenAddress);
        if (ts == TokenAllowanceStatus.REQUIRES_ALLOWANCE_EVERY_TIME) {
            token.approve(vault, amount);
            return;
        }

        if (ts == TokenAllowanceStatus.NO_ALLOWANCE) {
            token.approve(vault, MAX_UINT256);
            uint256 allowance = token.allowance(address(this), vault);
            _tokenAllowances[vault][tokenAddress] = allowance == MAX_UINT256 ?
                TokenAllowanceStatus.INF_ALLOWANCE :
                TokenAllowanceStatus.REQUIRES_ALLOWANCE_EVERY_TIME;
            return;
        }
    }

    function _checkAllowanceAndSetInf(
        address[] memory tokens,
        uint256[] memory amounts,
        address vault
    )
        internal
    {
        for (uint256 id = 0; id < tokens.length; id++) {
            _checkTokenAllowance(tokens[id], amounts[id], vault);
        }
    }
}