// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IFactory } from "../../Factories/interfaces/IFactory.sol";
import { ILPTokenFactory } from "../../Factories/ERC20Factory/interfaces/ILPTokenFactory.sol";
import { ILPERC20 } from "../../Factories/ERC20Factory/interfaces/ILPToken.sol";
import { ExternalBalanceManager } from "../BalancesManager.sol";
import { IWeightedStorage } from "../../SwapContracts/WeightedPool/interfaces/IWeightedStorage.sol";

contract WeightedVaultStorage is ExternalBalanceManager {
    address constant internal ZERO_ADDRESS = address(0);
    IFactory public weightedPoolFactory;
    ILPTokenFactory public lpTokenFactory;

    constructor(
        address weightedPoolFactory_,
        address lpTokenFactory_
    ) {
        weightedPoolFactory = IFactory(weightedPoolFactory_);
        lpTokenFactory = ILPTokenFactory(lpTokenFactory_);
    }

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