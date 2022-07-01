// SPDX-License-Identifier: GPL-3.0-or-later
// @title Storage of weighted vault
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IFactory } from "../../Factories/interfaces/IFactory.sol";
import { ExternalBalanceManager } from "../BalanceManager/BalancesManager.sol";
import { IWeightedStorage } from "../../SwapContracts/WeightedPool/interfaces/IWeightedStorage.sol";

contract WeightedVaultStorage is ExternalBalanceManager {
    address constant internal ZERO_ADDRESS = address(0);
    IFactory public weightedPoolFactory;

    constructor(
        address weightedPoolFactory_
    ) {
        weightedPoolFactory = IFactory(weightedPoolFactory_);
    }

    /**
     * @notice Get pool's token balance by token address
     * @param pool Address of pool
     * @param token Address of token
     * @return tokenBalance Balance of token
     */
    function _getPoolTokenBalanceByAddress(
        address pool,
        address token
    )
        internal
        view
        returns (uint256 tokenBalance)
    {
        return _getPoolTokenBalance(
            pool, 
            IWeightedStorage(pool).getTokenId(token)
        );
    }

    /**
     * @notice Get pool's token balance by token address
     * @param pool Address of pool
     * @param token Address of token
     * @return tokenBalance Balance of token
     */
    function getPoolTokenBalance(
        address pool, 
        address token
    )
        external
        override
        view
        returns(uint256 tokenBalance)
    {
        tokenBalance = _getPoolTokenBalanceByAddress(pool, token);
    }

    modifier registeredPool(address poolAddress) {
        require(
            weightedPoolFactory.checkPoolAddress(poolAddress),
            "Pool is not registered in factory"
        );
        _;
    }

    modifier onlyFactory() {
        require(
            msg.sender == address(weightedPoolFactory),
            "Function can only be called by factory"
        );
        _;
    }
}