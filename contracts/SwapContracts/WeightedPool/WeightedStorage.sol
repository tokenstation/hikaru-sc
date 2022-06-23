// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { InternalStorage } from "./utils/InternalWeightedStorage.sol";
import { IWeightedStorage } from "./interfaces/IWeightedStorage.sol";

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
        revert("Unknown token");
    }

    function getNTokens() external override view returns (uint256) {
        return N_TOKENS;
    }

    function getTokenId(address token) external override view returns (uint256 tokenId) {
        return _getTokenId(token);
    }

    function _getTokenId(address token) internal view returns (uint256) {
        if (token == token1 ) return 0 ;
        if (token == token2 ) return 1 ;
        if (token == token3 ) return 2 ;
        if (token == token4 ) return 3 ;
        if (token == token5 ) return 4 ;
        if (token == token6 ) return 5 ;
        if (token == token7 ) return 6 ;
        if (token == token8 ) return 7 ;
        // if (token == token9 ) return 8 ;
        // if (token == token10) return 9 ;
        // if (token == token11) return 10;
        // if (token == token12) return 11;
        // if (token == token13) return 12;
        // if (token == token14) return 13;
        // if (token == token15) return 14;
        // if (token == token16) return 15;
        // if (token == token17) return 16;
        // if (token == token18) return 17;
        // if (token == token19) return 18;
        // if (token == token20) return 19;
        failAndRevert();
    }

    function getWeight(address token) external override view returns (uint256) {
        return _getWeight(token);
    }
    function _getWeight(address token) internal view returns (uint256) {
        if (token == token1 ) return weight1 ;
        if (token == token2 ) return weight2 ;
        if (token == token3 ) return weight3 ;
        if (token == token4 ) return weight4 ;
        if (token == token5 ) return weight5 ;
        if (token == token6 ) return weight6 ;
        if (token == token7 ) return weight7 ;
        if (token == token8 ) return weight8 ;
        // if (token == token9 ) return weight9 ;
        // if (token == token10) return weight10;
        // if (token == token11) return weight11;
        // if (token == token12) return weight12;
        // if (token == token13) return weight13;
        // if (token == token14) return weight14;
        // if (token == token15) return weight15;
        // if (token == token16) return weight16;
        // if (token == token17) return weight17;
        // if (token == token18) return weight18;
        // if (token == token19) return weight19;
        // if (token == token20) return weight20;
        failAndRevert();
    }

    function getMultiplier(address token) external override view returns (uint256) {
        return _getMultiplier(token);
    }
    function _getMultiplier(address token) internal view returns (uint256) {
        if (token == token1 ) return multiplier1 ;
        if (token == token2 ) return multiplier2 ;
        if (token == token3 ) return multiplier3 ;
        if (token == token4 ) return multiplier4 ;
        if (token == token5 ) return multiplier5 ;
        if (token == token6 ) return multiplier6 ;
        if (token == token7 ) return multiplier7 ;
        if (token == token8 ) return multiplier8 ;
        // if (token == token9 ) return multiplier9 ;
        // if (token == token10) return multiplier10;
        // if (token == token11) return multiplier11;
        // if (token == token12) return multiplier12;
        // if (token == token13) return multiplier13;
        // if (token == token14) return multiplier14;
        // if (token == token15) return multiplier15;
        // if (token == token16) return multiplier16;
        // if (token == token17) return multiplier17;
        // if (token == token18) return multiplier18;
        // if (token == token19) return multiplier19;
        // if (token == token20) return multiplier20;
        failAndRevert();
    }

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
        // if (N_TOKENS >= 9 ) tokens[8 ] = token9 ;
        // if (N_TOKENS >= 10) tokens[9 ] = token10;
        // if (N_TOKENS >= 11) tokens[10] = token11;
        // if (N_TOKENS >= 12) tokens[11] = token12;
        // if (N_TOKENS >= 13) tokens[12] = token13;
        // if (N_TOKENS >= 14) tokens[13] = token14;
        // if (N_TOKENS >= 15) tokens[14] = token15;
        // if (N_TOKENS >= 16) tokens[15] = token16;
        // if (N_TOKENS >= 17) tokens[16] = token17;
        // if (N_TOKENS >= 18) tokens[17] = token18;
        // if (N_TOKENS >= 19) tokens[18] = token19;
        // if (N_TOKENS >= 20) tokens[19] = token20;
    }

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
        // if (N_TOKENS >= 9 ) weights[8 ] = weight9 ;
        // if (N_TOKENS >= 10) weights[9 ] = weight10;
        // if (N_TOKENS >= 11) weights[10] = weight11;
        // if (N_TOKENS >= 12) weights[11] = weight12;
        // if (N_TOKENS >= 13) weights[12] = weight13;
        // if (N_TOKENS >= 14) weights[13] = weight14;
        // if (N_TOKENS >= 15) weights[14] = weight15;
        // if (N_TOKENS >= 16) weights[15] = weight16;
        // if (N_TOKENS >= 17) weights[16] = weight17;
        // if (N_TOKENS >= 18) weights[17] = weight18;
        // if (N_TOKENS >= 19) weights[18] = weight19;
        // if (N_TOKENS >= 20) weights[19] = weight20;
    }

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
        // if (N_TOKENS >= 9 ) multipliers[8 ] = multiplier9 ;
        // if (N_TOKENS >= 10) multipliers[9 ] = multiplier10;
        // if (N_TOKENS >= 11) multipliers[10] = multiplier11;
        // if (N_TOKENS >= 12) multipliers[11] = multiplier12;
        // if (N_TOKENS >= 13) multipliers[12] = multiplier13;
        // if (N_TOKENS >= 14) multipliers[13] = multiplier14;
        // if (N_TOKENS >= 15) multipliers[14] = multiplier15;
        // if (N_TOKENS >= 16) multipliers[15] = multiplier16;
        // if (N_TOKENS >= 17) multipliers[16] = multiplier17;
        // if (N_TOKENS >= 18) multipliers[17] = multiplier18;
        // if (N_TOKENS >= 19) multipliers[18] = multiplier19;
        // if (N_TOKENS >= 20) multipliers[19] = multiplier20;
    }

    function _onlyVault() 
        internal
        view
    {
        require(
            msg.sender == vaultAddress,
            "This function can only be accessed via vault"
        );
    }

    modifier onlyFactory(address caller) {
        require(
            caller == factoryAddress,
            "This function can only be accessed via factory"
        );
        _;
    }
}