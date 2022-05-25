// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IFactory } from "../../Factories/interfaces/IFactory.sol";
import { IVault } from "../interfaces/IVault.sol";
import { IWeightedVault } from "./interfaces/IWeightedVault.sol";
import { IWeightedPool } from "../../SwapContracts/WeightedPool/interfaces/IWeightedPool.sol";
import { SingleManager } from "../../utils/SingleManager.sol";
import { WeightedVaultPoolOperations } from "./WeightedVaultPoolOperations.sol";
import { Flashloan } from "../Flashloan.sol";

contract WeightedPoolVault is IVault, IWeightedVault, SingleManager, WeightedVaultPoolOperations, Flashloan {

    uint256 public constant MAX_UINT = 2**256 - 1;
    mapping (address => uint256) public tokenBalances;

    constructor(
        address weightedPoolFactory_,
        address lpTokenFactory_
    )
        WeightedVaultPoolOperations(weightedPoolFactory_, lpTokenFactory_)
        SingleManager(msg.sender)
    {
    }

    function defaultSwap(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 swapAmount,
        uint256 minAmountOut,
        uint64 deadline
    ) 
        external 
        override
        returns (uint256 swapResult)
    {
        _preOpChecks(pool, deadline);
        swapResult = _swap(pool, tokenIn, tokenOut, swapAmount, minAmountOut, true);
    }

    function calculateDefaultSwap(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 swapAmount
    ) 
        external
        override 
        view 
        returns (uint256 swapResult, uint256 feeAmount)
    {
        _poolOfCorrectType(pool);
        (swapResult, feeAmount) = _calculateSwap(pool, tokenIn, tokenOut, swapAmount, true);
    }

    function registerPool(
        address pool,
        address[] memory tokens
    ) 
        external 
        override
        onlyFactory
        returns (bool registerStatus)
    {
        // TODO: add call to router to approve tokens from router to vault
        // i.e. in router (IERC20(token).approve(vault, MAX_UINT256))
        _registerPoolBalance(pool, tokens.length);
        // Vault must be added to known vaults of pool before this operation
        // Or we need to think of another way of performing default swaps, also there may be a problem with tokens
        // That implement fees on transfers -> there will be two transfers involved in operation
        // TODO: think about it
        // IRouter(routerAddress).setInfiniteApprove(tokens);
        return true;
    }

    function setFactoryAddress(
        address factoryAddress
    )
        external
        onlyManager
    {
        weightedPoolFactory = IFactory(factoryAddress);
    }

    function _poolOfCorrectType(address poolAddress)
        internal
        view
    {
        require(
            weightedPoolFactory.checkPoolAddress(poolAddress),
            "Pool is not registered in factory"
        );
    }
}