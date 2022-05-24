// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IFactory } from "../interfaces/IFactory.sol";
import { WeightedPool } from "../../SwapContracts/WeightedPool/WeightedPool.sol";
import { IWeightedVault } from "../../Vaults/WeightedPool/interfaces/IWeightedVault.sol";
import { ILPTokenFactory } from "../ERC20Factory/interfaces/ILPTokenFactory.sol";

// TODO: create base factory contract which implements checking pools origin (if it was deployed using factory)

contract WeightedPoolFactory is IFactory {

    uint256 constant internal MAX_TOKENS = 20;

    IWeightedVault internal weightedVault;
    ILPTokenFactory internal lpTokenFactory;

    event PoolCreated(
        address indexed poolAddress,
        address indexed lpTokenAddress,
        address[] tokens,
        uint256[] weights,
        uint256 swapFee,
        uint256 indexed poolId
    );

    string constant public version = "v1";
    string constant public basePoolsName = "WeightedPool";
    uint256 constant internal ONE = 1e18;

    address[] internal pools;
    mapping(address => bool) internal knownPools;

    constructor(
        address weightedVault_,
        address lpTokenFactory_
    ) {
        weightedVault = IWeightedVault(weightedVault_);
        lpTokenFactory = ILPTokenFactory(lpTokenFactory_);
    }

    function createPool(
        address[] memory tokens_,
        uint256[] memory weights_,
        uint256 swapFee_,
        string memory lpName,
        string memory lpSymbol
    )
        external
        returns (address poolAddress)
    {
        // TODO: real values for checking boundaries
        require(
            tokens_.length == weights_.length,
            "Invalid array length"
        );
        require(
            tokens_.length >= 2,
            "Cannot create pool with 0 or 1 token"
        );
        require(
            tokens_.length <= MAX_TOKENS,
            "Cannot create pool with more than 20 tokens"
        );

        uint256 weightSum = 0;
        address currentToken = address(1);
        for (uint256 tokenId = 0; tokenId < tokens_.length; tokenId++) {
            require(
                weights_[tokenId] >= 0, // TODO: add real value
                "Weight cannot be lower than {value}"
            );
            require(
                currentToken < tokens_[tokenId],
                "Invalid order of tokens or token duplication detected"
            );
            currentToken = tokens_[tokenId];
            weightSum += weights_[tokenId];
        }

        require(
            weightSum == ONE,
            "Sum of all weights is not equal to ONE (1e18)"
        );

        poolAddress = address(
            new WeightedPool(
                address(weightedVault),
                msg.sender,
                tokens_,
                weights_,
                swapFee_
            )
        );

        address lpTokenAddress = lpTokenFactory.createNewToken(
            address(weightedVault), 
            lpName, 
            lpSymbol
        );

        require(
            weightedVault.registerPool(
                poolAddress,
                lpTokenAddress,
                tokens_
            ),
            "Cannot register pool in vault, aborting pool creation"
        );

        emit PoolCreated(poolAddress, lpTokenAddress, tokens_, weights_, swapFee_, pools.length);
        pools.push(poolAddress);
        knownPools[poolAddress] = true;
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