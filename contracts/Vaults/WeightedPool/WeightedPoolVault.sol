// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IFactory } from "../../Factories/interfaces/IFactory.sol";
import { IVault } from "../interfaces/IVault.sol";
import { IWeightedVault } from "./interfaces/IWeightedVault.sol";
import { IWeightedPool } from "../../SwapContracts/WeightedPool/interfaces/IWeightedPool.sol";
import { SingleManager } from "../../utils/SingleManager.sol";
import { WeightedVaultPoolOperations } from "./WeightedVaultPoolOperations.sol";

contract WeightedPoolVault is IVault, IWeightedVault, SingleManager, WeightedVaultPoolOperations {

    uint256 public constant MAX_UINT = 2**256 - 1;
    mapping (address => uint256) public tokenBalances;

    constructor(
        address weightedPoolFactory_
    )
        SingleManager(msg.sender) 
    {
        weightedPoolFactory = IFactory(weightedPoolFactory_);
    }

    // Router uses transferFrom to get tokens from users, because
    // They need only one approve to interact with router
    // But if transferFrom is used in Vaults to get tokens from router, it will cost too much
    // Because it will need many approves for different vaults and tokens

    // Tokens that are used for swap will be transferred from router to vault
    // After calling function, swap will be performed and tokens will be
    // Transferred back to router that initiated transaction

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
        poolOfCorrectType(pool)
        returns (uint256 swapResult)
    {
        swapResult = IWeightedPool(pool).swap(
            tokenIn, 
            tokenOut,
            swapAmount, 
            minAmountOut, 
            deadline
        );
        _transferTo(
            tokenOut,
            msg.sender,
            swapResult
        );
    }

    function _transferTo(
        address token,
        address to,
        uint256 amount
    ) 
        internal
        returns (uint256 transferred)
    {
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to, amount);
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        transferred = balanceBefore - balanceAfter;
        require(
            transferred == amount,
            "Invalid amount of tokens transferred from vault or token has fees on transfer"
        );
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
        poolOfCorrectType(pool)
        returns (uint256 swapResult, uint256 feeAmount)
    {
        (swapResult, feeAmount) = IWeightedPool(pool).calculateSwap(
            tokenIn, 
            tokenOut, 
            swapAmount, 
            true
        );
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
        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            IERC20(tokens[tokenId]).approve(pool, MAX_UINT);
        }
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

    modifier poolOfCorrectType(address poolAddress) {
        require(
            weightedPoolFactory.checkPoolAddress(poolAddress),
            "Pool is not registered in factory"
        );
        _;
    }
}