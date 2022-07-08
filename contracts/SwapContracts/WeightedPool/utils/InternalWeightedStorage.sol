// SPDX-License-Identifier: GPL-3.0-or-later
// @title Contract for storing pool parameters
// @author tokenstation.dev

pragma solidity 0.8.6;

import { WeightedMath } from "../libraries/WeightedMath.sol";
import { FixedPoint } from "../../../utils/Math/FixedPoint.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ArrayUtils } from "../../../utils/libraries/ArrayUtils.sol";
import "../../../utils/Errors/ErrorLib.sol";

contract InternalStorage {

    address constant internal ZERO_ADDRESS = address(0);
    uint256 constant internal MAX_TOKENS = 8;

    address public immutable factoryAddress;
    address public immutable vaultAddress; 

    uint256 immutable public N_TOKENS;

    address internal immutable token1;
    address internal immutable token2;
    address internal immutable token3;
    address internal immutable token4;
    address internal immutable token5;
    address internal immutable token6;
    address internal immutable token7;
    address internal immutable token8;
    address internal immutable token9;
    address internal immutable token10;
    // address internal immutable token11;
    // address internal immutable token12;
    // address internal immutable token13;
    // address internal immutable token14;
    // address internal immutable token15;
    // address internal immutable token16;
    // address internal immutable token17;
    // address internal immutable token18;
    // address internal immutable token19;
    // address internal immutable token20;

    uint256 internal immutable weight1;
    uint256 internal immutable weight2;
    uint256 internal immutable weight3;
    uint256 internal immutable weight4;
    uint256 internal immutable weight5;
    uint256 internal immutable weight6;
    uint256 internal immutable weight7;
    uint256 internal immutable weight8;
    uint256 internal immutable weight9;
    uint256 internal immutable weight10;
    // uint256 internal immutable weight11;
    // uint256 internal immutable weight12;
    // uint256 internal immutable weight13;
    // uint256 internal immutable weight14;
    // uint256 internal immutable weight15;
    // uint256 internal immutable weight16;
    // uint256 internal immutable weight17;
    // uint256 internal immutable weight18;
    // uint256 internal immutable weight19;
    // uint256 internal immutable weight20;

    uint256 internal immutable multiplier1;
    uint256 internal immutable multiplier2;
    uint256 internal immutable multiplier3;
    uint256 internal immutable multiplier4;
    uint256 internal immutable multiplier5;
    uint256 internal immutable multiplier6;
    uint256 internal immutable multiplier7;
    uint256 internal immutable multiplier8;
    uint256 internal immutable multiplier9;
    uint256 internal immutable multiplier10;
    // uint256 internal immutable multiplier11;
    // uint256 internal immutable multiplier12;
    // uint256 internal immutable multiplier13;
    // uint256 internal immutable multiplier14;
    // uint256 internal immutable multiplier15;
    // uint256 internal immutable multiplier16;
    // uint256 internal immutable multiplier17;
    // uint256 internal immutable multiplier18;
    // uint256 internal immutable multiplier19;
    // uint256 internal immutable multiplier20;

    /**
     * @param factoryAddress_ Address of factory that deployed pool
     * @param vaultAddress_ Address of weighted vault, only this contract has access to pool swap/join/exit functions
     * @param tokens Array of pool's tokens
     * @param weights Array of pool's token weights
     */
    constructor(
        address factoryAddress_,
        address vaultAddress_,
        address[] memory tokens,
        uint256[] memory weights
    ) {
        _require(
            ArrayUtils.checkArrayLength(tokens, weights),
            Errors.POOL_WEIGHTS_ARRAY_LENGTH_MISMATCH
        );
        _require(
            tokens.length <= MAX_TOKENS,
            Errors.MAX_TOKENS
        );

        ArrayUtils.checkUniqueness(tokens);

        uint256 weightsSum = 0;
        for (uint256 weightId = 0; weightId < weights.length; weightId++) {
            _require(
                WeightedMath._MIN_WEIGHT <= weights[weightId],
                Errors.MIN_WEIGHT
            );
            weightsSum += weights[weightId];
        }
        _require(
            weightsSum == FixedPoint.ONE,
            Errors.INVALID_WEIGHTS_SUM
        );

        factoryAddress = factoryAddress_;
        vaultAddress = vaultAddress_;
        
        N_TOKENS = tokens.length;
    
        token1  = tokens[0];
        token2  = tokens[1];
        token3  = tokens.length >= 3  ? tokens[2 ] : ZERO_ADDRESS;
        token4  = tokens.length >= 4  ? tokens[3 ] : ZERO_ADDRESS;
        token5  = tokens.length >= 5  ? tokens[4 ] : ZERO_ADDRESS;
        token6  = tokens.length >= 6  ? tokens[5 ] : ZERO_ADDRESS;
        token7  = tokens.length >= 7  ? tokens[6 ] : ZERO_ADDRESS;
        token8  = tokens.length >= 8  ? tokens[7 ] : ZERO_ADDRESS;
        token9  = tokens.length >= 9  ? tokens[8 ] : ZERO_ADDRESS;
        token10 = tokens.length >= 10 ? tokens[9 ] : ZERO_ADDRESS;

        weight1  = weights[0];
        weight2  = weights[1];
        weight3  = weights.length >= 3  ? weights[2 ] : 0;
        weight4  = weights.length >= 4  ? weights[3 ] : 0;
        weight5  = weights.length >= 5  ? weights[4 ] : 0;
        weight6  = weights.length >= 6  ? weights[5 ] : 0;
        weight7  = weights.length >= 7  ? weights[6 ] : 0;
        weight8  = weights.length >= 8  ? weights[7 ] : 0;
        weight9  = weights.length >= 9  ? weights[8 ] : 0;
        weight10 = weights.length >= 10 ? weights[9 ] : 0;


        // This section also checks that smart contracts with provided addresses exist
        // Also this means that tokens cannot have more than 18 decimals
        multiplier1  = 10**(18 - IERC20Metadata(tokens[0]).decimals());
        multiplier2  = 10**(18 - IERC20Metadata(tokens[1]).decimals());
        multiplier3  = tokens.length >= 3  ? 10**(18 - IERC20Metadata(tokens[2 ]).decimals()) : 0;
        multiplier4  = tokens.length >= 4  ? 10**(18 - IERC20Metadata(tokens[3 ]).decimals()) : 0;
        multiplier5  = tokens.length >= 5  ? 10**(18 - IERC20Metadata(tokens[4 ]).decimals()) : 0;
        multiplier6  = tokens.length >= 6  ? 10**(18 - IERC20Metadata(tokens[5 ]).decimals()) : 0;
        multiplier7  = tokens.length >= 7  ? 10**(18 - IERC20Metadata(tokens[6 ]).decimals()) : 0;
        multiplier8  = tokens.length >= 8  ? 10**(18 - IERC20Metadata(tokens[7 ]).decimals()) : 0;
        multiplier9  = tokens.length >= 9  ? 10**(18 - IERC20Metadata(tokens[8 ]).decimals()) : 0;
        multiplier10 = tokens.length >= 10 ? 10**(18 - IERC20Metadata(tokens[9 ]).decimals()) : 0;
    }
}