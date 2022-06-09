// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IFactory } from "../interfaces/IFactory.sol";
import { WeightedPool } from "../../SwapContracts/WeightedPool/WeightedPool.sol";
import { IWeightedVault } from "../../Vaults/WeightedVault/interfaces/IWeightedVault.sol";
import { BaseSplitCodeFactory } from "../../utils/CodeSplitter/BaseSplitCodeFactory.sol";

// TODO: create base factory contract which implements checking pools origin (if it was deployed using factory)
// TODO: add contract for setting default pool manager
// TODO: check that all setters emit events
// TODO: add interface for weighted factory

contract WeightedPoolFactory is IFactory, BaseSplitCodeFactory {
    IWeightedVault internal weightedVault;

    event PoolCreated(address indexed poolAddress);

    string constant public version = "v1";
    string constant public basePoolsName = "WeightedPool";
    uint256 constant internal ONE = 1e18;

    address[] public pools;
    mapping(address => bool) internal knownPools;

    constructor(
        address weightedVault_
    ) 
        BaseSplitCodeFactory(type(WeightedPool).creationCode)
    {
        weightedVault = IWeightedVault(weightedVault_);
    }

    function createPool(
        address[] memory tokens,
        uint256[] memory weights,
        uint256 swapFee,
        string memory lpName,
        string memory lpSymbol,
        address poolManager
    )
        external
        returns (address poolAddress)
    {
        poolAddress = _create(
            abi.encode(
                address(this),
                address(weightedVault),
                poolManager, // TODO: IPoolManager.getManager(msg.sender) -> address of manager
                tokens,
                weights,
                swapFee,
                lpName,
                lpSymbol
            )
        );

        require(
            weightedVault.registerPool(
                poolAddress,
                tokens
            ),
            "Cannot register pool in vault, aborting pool creation"
        );

        emit PoolCreated(poolAddress);
        pools.push(poolAddress);
        knownPools[poolAddress] = true;
    }

    function checkPoolAddress(
        address poolAddress
    ) 
        external 
        view 
        override
        returns (bool knownPool)
    {
        return knownPools[poolAddress];
    }

    function totalPools()
        external
        view
        returns (uint256 N_POOLS)
    {
        return pools.length;
    }
}