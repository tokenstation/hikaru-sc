// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

import { IFactory } from "../../Factories/interfaces/IFactory.sol";

contract WeightedVaultStorage {
    mapping (address => uint256) balances;
    IFactory public weightedPoolFactory;

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