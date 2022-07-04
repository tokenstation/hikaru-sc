// SPDX-License-Identifier: GPL-3.0-or-later
// @title Contract for obtaining pool parameters
// @author tokenstation.dev

pragma solidity 0.8.6;

import { InternalStorage } from "./utils/InternalWeightedStorage.sol";
import { IWeightedStorage } from "./interfaces/IWeightedStorage.sol";
import "../../utils/Errors/ErrorLib.sol";

contract WeightedStorage is InternalStorage, IWeightedStorage {

    constructor(
        address factoryAddress_,
        address vaultAddress_,
        address[] memory tokens,
        uint256[] memory weights
    ) 
        InternalStorage(factoryAddress_, vaultAddress_, tokens, weights)
    {
        // Empty
    }

    function failAndRevert() internal pure {
        _require(
            false,
            Errors.INVALID_TOKEN
        );
    }

    /**
     * @inheritdoc IWeightedStorage
     */
    function getNTokens() external override view returns (uint256) {
        return N_TOKENS;
    }

    /**
     * @inheritdoc IWeightedStorage
     */
    function getTokenId(address token) external override view returns (uint256 tokenId) {
        return _getTokenId(token);
    }

    function _getTokenId(address token) internal view returns (uint256 tokenId) {
        if (token == token1 ) return 0 ;
        if (token == token2 ) return 1 ;
        if (token == token3 ) return 2 ;
        if (token == token4 ) return 3 ;
        if (token == token5 ) return 4 ;
        if (token == token6 ) return 5 ;
        if (token == token7 ) return 6 ;
        if (token == token8 ) return 7 ;
        if (token == token9 ) return 8 ;
        if (token == token10) return 9 ;
        failAndRevert();
    }

    /**
     * @inheritdoc IWeightedStorage
     */
    function getWeight(address token) external override view returns (uint256) {
        return _getWeight(token);
    }
    function _getWeight(address token) internal view returns (uint256 tokenWeight) {
        if (token == token1 ) return weight1 ;
        if (token == token2 ) return weight2 ;
        if (token == token3 ) return weight3 ;
        if (token == token4 ) return weight4 ;
        if (token == token5 ) return weight5 ;
        if (token == token6 ) return weight6 ;
        if (token == token7 ) return weight7 ;
        if (token == token8 ) return weight8 ;
        if (token == token9 ) return weight9 ;
        if (token == token10) return weight10;
        failAndRevert();
    }

    /**
     * @inheritdoc IWeightedStorage
     */
    function getMultiplier(address token) external override view returns (uint256) {
        return _getMultiplier(token);
    }
    function _getMultiplier(address token) internal view returns (uint256 tokenMultiplier) {
        if (token == token1 ) return multiplier1 ;
        if (token == token2 ) return multiplier2 ;
        if (token == token3 ) return multiplier3 ;
        if (token == token4 ) return multiplier4 ;
        if (token == token5 ) return multiplier5 ;
        if (token == token6 ) return multiplier6 ;
        if (token == token7 ) return multiplier7 ;
        if (token == token8 ) return multiplier8 ;
        if (token == token9 ) return multiplier9 ;
        if (token == token10) return multiplier10;
        failAndRevert();
    }

    /**
     * @inheritdoc IWeightedStorage
     */
    function getTokens() external override view returns (address[] memory tokens) {
        tokens = _getTokens();
    }
    function _getTokens() internal view returns (address[] memory tokens) {
        tokens = new address[](N_TOKENS);
        if (N_TOKENS >= 1 ) tokens[0 ] = token1 ;
        if (N_TOKENS >= 2 ) tokens[1 ] = token2 ;
        if (N_TOKENS >= 3 ) tokens[2 ] = token3 ;
        if (N_TOKENS >= 4 ) tokens[3 ] = token4 ;
        if (N_TOKENS >= 5 ) tokens[4 ] = token5 ;
        if (N_TOKENS >= 6 ) tokens[5 ] = token6 ;
        if (N_TOKENS >= 7 ) tokens[6 ] = token7 ;
        if (N_TOKENS >= 8 ) tokens[7 ] = token8 ;
        if (N_TOKENS >= 9 ) tokens[8 ] = token9 ;
        if (N_TOKENS >= 10) tokens[9 ] = token10;
    }

    /**
     * @inheritdoc IWeightedStorage
     */
    function getWeights() external override view returns (uint256[] memory weights) {
        weights = _getWeights();
    }
    function _getWeights() internal view returns (uint256[] memory weights) {
        weights = new uint256[](N_TOKENS);
        if (N_TOKENS >= 1 ) weights[0 ] = weight1 ;
        if (N_TOKENS >= 2 ) weights[1 ] = weight2 ;
        if (N_TOKENS >= 3 ) weights[2 ] = weight3 ;
        if (N_TOKENS >= 4 ) weights[3 ] = weight4 ;
        if (N_TOKENS >= 5 ) weights[4 ] = weight5 ;
        if (N_TOKENS >= 6 ) weights[5 ] = weight6 ;
        if (N_TOKENS >= 7 ) weights[6 ] = weight7 ;
        if (N_TOKENS >= 8 ) weights[7 ] = weight8 ;
        if (N_TOKENS >= 9 ) weights[8 ] = weight9 ;
        if (N_TOKENS >= 10) weights[9 ] = weight10;
    }

    /**
     * @inheritdoc IWeightedStorage
     */
    function getMultipliers() external override view returns (uint256[] memory multipliers) {
        multipliers = _getMultipliers();
    }
    function _getMultipliers() internal view returns (uint256[] memory multipliers) {
        multipliers = new uint256[](N_TOKENS);
        if (N_TOKENS >= 1 ) multipliers[0 ] = multiplier1 ;
        if (N_TOKENS >= 2 ) multipliers[1 ] = multiplier2 ;
        if (N_TOKENS >= 3 ) multipliers[2 ] = multiplier3 ;
        if (N_TOKENS >= 4 ) multipliers[3 ] = multiplier4 ;
        if (N_TOKENS >= 5 ) multipliers[4 ] = multiplier5 ;
        if (N_TOKENS >= 6 ) multipliers[5 ] = multiplier6 ;
        if (N_TOKENS >= 7 ) multipliers[6 ] = multiplier7 ;
        if (N_TOKENS >= 8 ) multipliers[7 ] = multiplier8 ;
        if (N_TOKENS >= 9 ) multipliers[8 ] = multiplier9 ;
        if (N_TOKENS >= 10) multipliers[9 ] = multiplier10;
    }

    function _onlyVault() 
        internal
        view
    {
        _require(
            msg.sender == vaultAddress,
            Errors.CALLER_IS_NOT_VAULT
        );
    }

    modifier onlyFactory(address caller) {
        _require(
            caller == factoryAddress,
            Errors.CALLER_IS_NOT_FACTORY
        );
        _;
    }
}