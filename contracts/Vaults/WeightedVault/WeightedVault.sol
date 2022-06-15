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
import { Flashloan } from "../Flashloan/Flashloan.sol";

// TODO: systematize imports
contract WeightedVault is IVault, IWeightedVault, SingleManager, WeightedVaultPoolOperations {

    uint256 public constant MAX_UINT = 2**256 - 1;
    mapping (address => uint256) public tokenBalances;

    constructor(
        address weightedPoolFactory_,
        uint256 flashloanFee_,
        address flashloanFeeReceiver_
    )
        WeightedVaultPoolOperations(weightedPoolFactory_)
        Flashloan(flashloanFeeReceiver_, flashloanFee_)
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
        reentrancyGuard
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

    event PoolRegistered(address indexed poolAddress);
    function registerPool(
        address pool,
        address[] memory tokens
    ) 
        external 
        override
        onlyFactory
        returns (bool registerStatus)
    {
        // TODO: add call for approve from router
        // i.g.: if user wants to swap token that was not swap before, router performs infinite approve to vault of this token
        emit PoolRegistered(pool);
        return _registerPoolBalance(pool, tokens.length);
    }


    event FactoryAddressUpdate(address indexed newFactoryAddress);
    function setFactoryAddress(
        address factoryAddress
    )
        external
        onlyManager
    {
        _setFactoryAddress(factoryAddress);
    }
    function _setFactoryAddress(
        address factoryAddress
    )
        internal
    {
        require(
            factoryAddress != address(0),
            "Factory address cannot be zero"
        );
        emit FactoryAddressUpdate(factoryAddress);
        weightedPoolFactory = IFactory(factoryAddress);
    }

    function setFlashloanFees(
        uint256 flashloanFees_
    )
        external
        override
        onlyManager
    {
        _setFlashloanFees(flashloanFees_);
    }

    function setFeeReceiver(
        address feeReceiver_
    )
        external
        override
        onlyManager
    {
        _setFeeReceiver(feeReceiver_);
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