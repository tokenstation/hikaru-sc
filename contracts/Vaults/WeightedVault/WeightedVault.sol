// SPDX-License-Identifier: GPL-3.0-or-later
// @title Vault for interaction with Weighted pools
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { WeightedOperations } from "./WeightedVaultOperations.sol";
import { IFactory } from "../../Factories/interfaces/IFactory.sol";
import { IWeightedVault } from "./interfaces/IWeightedVault.sol";
import { IWeightedPool } from "../../SwapContracts/WeightedPool/interfaces/IWeightedPool.sol";
import { Manageable } from "../../utils/Manageable.sol";
import { Flashloan, IFlashloanManager } from "../Flashloan/Flashloan.sol";
import { WeightedVaultERC165 } from "./WeightedVaultERC165.sol";
import { ProtocolFees } from "../ProtocolFees/ProtocolFees.sol";
import "../../utils/Errors/ErrorLib.sol";

// TODO: systematize imports
contract WeightedVault is WeightedOperations, WeightedVaultERC165, IWeightedVault, Manageable {

    uint256 public constant MAX_UINT = 2**256 - 1;
    mapping (address => uint256) public tokenBalances;

    constructor(
        address weightedPoolFactory_,
        uint256 flashloanFee_,
        uint256 protocolFee_
    )
        WeightedOperations(weightedPoolFactory_)
        ProtocolFees(protocolFee_)
        Flashloan(flashloanFee_)
        Manageable(msg.sender)
    {
        
    }

    event PoolRegistered(address indexed poolAddress);
    /**
     * @inheritdoc IWeightedVault
     */
    function registerPool(
        address pool,
        address[] memory tokens
    ) 
        external 
        override
        onlyFactory
        returns (bool registerStatus)
    {
        emit PoolRegistered(pool);
        return _registerPoolBalance(pool, tokens.length);
    }


    event FactoryAddressUpdate(address indexed newFactoryAddress);
    /**
     * @notice Set new factory address
     * @dev This function can be called only once to set factory address after deploying vault
     * @param factoryAddress New factory address
     */
    function setFactoryAddress(
        address factoryAddress
    )
        external
        onlyManager
    {
        _require(
            address(weightedPoolFactory) == address(0),
            Errors.FACTORY_ADDRESS_MUST_BE_ZERO_ADDRESS
        );
        _setFactoryAddress(factoryAddress);
    }
    /**
     * @notice Set new factory address
     * @param factoryAddress New factory address
     */
    function _setFactoryAddress(
        address factoryAddress
    )
        internal
    {
        _require(
            factoryAddress != address(0),
            Errors.ZERO_ADDRESS
        );
        emit FactoryAddressUpdate(factoryAddress);
        weightedPoolFactory = IFactory(factoryAddress);
    }

    /**
     * @inheritdoc IFlashloanManager
     */
    function setFlashloanFees(
        uint256 flashloanFees_
    )
        external
        override
        onlyManager
    {
        _setFlashloanFees(flashloanFees_);
    }

    /**
     * @inheritdoc ProtocolFees
     */
    function setProtocolFee(
        uint256 protocolFee_
    )
        external
        virtual
        override
        onlyManager
    {
        _setProtocolFee(protocolFee_);
    }

    /**
     * @inheritdoc ProtocolFees
     */
    function withdrawCollectedFees(
        address[] memory tokens,
        uint256[] memory amounts,
        address[] memory to
    ) 
        external 
        virtual
        override
        onlyManager
    {
        _withdrawCollectedFees(tokens, amounts, to);
    }
}