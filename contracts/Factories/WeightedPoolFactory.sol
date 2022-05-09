// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

import { WeightedPool } from "../SwapContracts/WeightedPool/WeightedPool.sol";
import { IFactory } from "./interfaces/IFactory.sol";
import { IWeightedPoolVault } from "../Vaults/interfaces/IWeightedVault.sol";

// TODO: Add interface for default (fallback) swap that can be used in any pool
// TODO: Create contract that will construct name and symbol;


contract WeightedPoolFactory is IFactory {

    event PoolCreated(
        address indexed poolAddress,
        address[] tokens,
        uint256[] weights,
        uint256 swapFee,
        uint256 depositFee,
        uint256 indexed poolId
    );

    string constant public basePoolsName = "WeightedPool";
    string constant public version = "v1";

    address[] public pools;
    mapping(address => bool) public knownPools;
    /**
      Initial cost of writing non-zero value is 22100 gas
      When we restore previously written value to 0 (if storage slot previously had 0 value) 
      we pay 2200 get 19900 gas refund, so final cost is:
      cost = 22100 + 2200 - 19900 = 4400 gas per token
      usually there are 2-5 tokens, so cost of uniqueness check is ~8k-20k

      Also, mappings can only be created as state variables (because there are memes with mapping memory layout)
     */
    mapping(address => bool) internal uniqueTokens;

    function crearePool(
        address[] memory tokens_,
        uint256[] memory weights_,
        uint256 swapFee_,
        uint256 depositFee_,
        string memory lpName,
        string memory lpSymbol
    )
        external
        returns (address poolAddress)
    {
        require(
            tokens_.length == weights_.length,
            "Invalid array length"
        );
        uint256 weightSum = 0;
        for (uint256 tokenId = 0; tokenId < tokens_.length; tokenId++) {
            require(
                tokens_[tokenId] != address(0),
                "Zero-address is prohibited"
            );
            require(
                !uniqueTokens[tokens_[tokenId]],
                "Token duplication is prohibited"
            );

            uniqueTokens[tokens_[tokenId]] = true;
            weightSum += weights_[tokenId];
        }
        require(
            weightSum == 1e18,
            "Invalid weights sum"
        );

        // Free storage to get gas refund
        for (uint256 tokenId = 0; tokenId < tokens_.length; tokenId++) {
            delete uniqueTokens[tokens_[tokenId]];
        }

        poolAddress = address(
            new WeightedPool(
                msg.sender,
                tokens_,
                weights_,
                swapFee_,
                depositFee_,
                lpName,
                lpSymbol
            )
        );

        require(
            IWeightedPoolVault(address(1)).registerPool(
                poolAddress,
                tokens_,
                weights_,
                swapFee_
            ),
            "Cannot register pool in vault, aborting pool creation"
        );

        pools.push(poolAddress);
        knownPools[poolAddress] = true;
        emit PoolCreated(poolAddress, tokens_, weights_, swapFee_, depositFee_, pools.length);
    }

    function getPoolById(
        uint256 poolId
    ) 
        external
        view
        override
        returns (address)
    {
        return pools[poolId];
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
}