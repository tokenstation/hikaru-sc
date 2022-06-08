// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

contract InternalBalanceManager {
    mapping(address => uint256[]) internal _internalBalances;

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

    function _getPoolBalances(
        address pool
    )
        internal
        view
        returns (uint256[] memory tokenBalances)
    {
        tokenBalances = _internalBalances[pool];
    }

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

    function _setBalances(
        address pool,
        uint256[] memory balances
    )
        internal
    {
        _internalBalances[pool] = balances;
    }

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

interface IExternalBalanceManager {
    function getPoolBalances(
        address pool
    ) external view returns (uint256[] memory poolBalance);

    function getPoolTokenBalance(
        address pool,
        address token
    ) external view returns (uint256 tokenBalance);
}

abstract contract ExternalBalanceManager is IExternalBalanceManager, InternalBalanceManager {
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