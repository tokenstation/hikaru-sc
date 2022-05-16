// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

import { IFactory } from "../../Factories/interfaces/IFactory.sol";
import { ILPERC20 } from "../../Factories/ERC20Factory/interfaces/ILPToken.sol";

contract WeightedVaultStorage {
    address constant internal ZERO_ADDRESS = address(0);
    mapping (address => ILPERC20) lpTokens;
    mapping (address => uint256) balances;
    IFactory public weightedPoolFactory;

    function _registerLPToken(
        address pool,
        address lpToken
    ) 
        internal
    {
        require(
            address(lpTokens[pool]) == ZERO_ADDRESS,
            "Pool already has LP token assigned to it"
        );

        lpTokens[pool] = ILPERC20(lpToken);
    }

    function _mintTokensTo(
        address pool,
        address user,
        uint256 tokenAmount
    )
        internal
        _existingLPToken(pool)
    {
        lpTokens[pool].mint(user, tokenAmount);
    }

    function _burnTokensFrom(
        address pool,
        address user,
        uint256 tokenAmount
    )
        internal
        _existingLPToken(pool)
    {
        lpTokens[pool].burn(user, tokenAmount);
    }

    modifier _existingLPToken(
        address pool
    ) {
        require(
            address(lpTokens[pool]) != ZERO_ADDRESS,
            "Pool has no LP token assigned to it"
        );
        _;
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