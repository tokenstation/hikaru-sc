// SPDX-License-Identifier: GPL-3.0-or-later
// @title Base contract for manipulating pool balances
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IExternalBalanceManager } from "./interfaces/IExternalBalanceManager.sol";

contract InternalBalanceManager {
    mapping(address => uint256[]) internal _internalBalances;

    /**
     * @notice Add new pool balance
     * @param pool Address of pool
     * @param nTokens amount of tokens in pool
     * @return Wether pool was registered successfully
     */
    function _registerPoolBalance(
        address pool,
        uint256 nTokens
    )
        internal
        returns (bool)
    {
        if (_internalBalances[pool].length != 0) return false;
        
        _internalBalances[pool] = new uint256[](nTokens);
        return true;
    }

    /**
     * @notice Get balances of pool
     * @param pool Address of pool
     * @param tokenId Id of token
     * @return tokenBalance Pool's token balance
     */
    function _getPoolTokenBalance(
        address pool,
        uint256 tokenId
    )
        internal
        view
        returns (uint256 tokenBalance)
    {
        tokenBalance = _internalBalances[pool][tokenId];
    }

    /**
     * @notice Get pool balances
     * @param pool Address of pool
     * @return tokenBalances Pool balances
     */
    function _getPoolBalances(
        address pool
    )
        internal
        view
        returns (uint256[] memory tokenBalances)
    {
        tokenBalances = _internalBalances[pool];
    }

    /**
     * @notice Change pool balance of selected token
     * @param pool Address of pool
     * @param tokenId Id of token
     * @param amount Balance delta
     * @param positive Add or substract token balance
     * @return balanceAfter Balance after changing
     */
    function _changePoolBalance(
        address pool,
        uint256 tokenId,
        uint256 amount,
        bool positive
    )
        internal
        returns (uint256 balanceAfter)
    {
        balanceAfter = positive ? _internalBalances[pool][tokenId] + amount : _internalBalances[pool][tokenId] - amount;
        _internalBalances[pool][tokenId] = balanceAfter;
    }

    /**
     * @notice Set pool balance
     * @param pool Address of pool
     * @param balances New pool balances
     */
    function _setBalances(
        address pool,
        uint256[] memory balances
    )
        internal
    {
        _internalBalances[pool] = balances;
    }

    /**
     * @notice Calculate balance changes
     * @param balances Pool balance
     * @param deltas Balance deltas
     * @param positive Add or substract deltas
     * @return Calculated balance updates
     */
    function _calculateBalancesUpdate(
        uint256[] memory balances,
        uint256[] memory deltas,
        bool positive
    )
        internal
        pure
        returns(uint256[] memory)
    {
        for (uint256 tokenId = 0; tokenId < balances.length; tokenId++) {
            balances[tokenId] = positive ? balances[tokenId] + deltas[tokenId] : balances[tokenId] - deltas[tokenId];
        }
        return balances;
    }
}

abstract contract ExternalBalanceManager is IExternalBalanceManager, InternalBalanceManager {

    /**
     * @inheritdoc IExternalBalanceManager
     */
    function getPoolBalances(
        address pool
    )
        external
        override
        view
        returns (uint256[] memory poolBalance)
    {
        poolBalance = _internalBalances[pool];
    }

    /**
     * @inheritdoc IExternalBalanceManager
     */
    function getPoolTokenBalance(
        address pool,
        address token
    ) 
        external
        override
        virtual
        view
        returns (uint256 tokenBalance);
}