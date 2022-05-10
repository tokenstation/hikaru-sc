// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract InternalStorage {
    address constant ZERO_ADDRESS = address(0);

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
    address internal immutable token11;
    address internal immutable token12;
    address internal immutable token13;
    address internal immutable token14;
    address internal immutable token15;
    address internal immutable token16;
    address internal immutable token17;
    address internal immutable token18;
    address internal immutable token19;
    address internal immutable token20;

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
    uint256 internal immutable weight11;
    uint256 internal immutable weight12;
    uint256 internal immutable weight13;
    uint256 internal immutable weight14;
    uint256 internal immutable weight15;
    uint256 internal immutable weight16;
    uint256 internal immutable weight17;
    uint256 internal immutable weight18;
    uint256 internal immutable weight19;
    uint256 internal immutable weight20;

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
    uint256 internal immutable multiplier11;
    uint256 internal immutable multiplier12;
    uint256 internal immutable multiplier13;
    uint256 internal immutable multiplier14;
    uint256 internal immutable multiplier15;
    uint256 internal immutable multiplier16;
    uint256 internal immutable multiplier17;
    uint256 internal immutable multiplier18;
    uint256 internal immutable multiplier19;
    uint256 internal immutable multiplier20;

    constructor(
        address[] memory tokens,
        uint256[] memory weights
    ) {
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
        token11 = tokens.length >= 11 ? tokens[10] : ZERO_ADDRESS;
        token12 = tokens.length >= 12 ? tokens[11] : ZERO_ADDRESS;
        token13 = tokens.length >= 13 ? tokens[12] : ZERO_ADDRESS;
        token14 = tokens.length >= 14 ? tokens[13] : ZERO_ADDRESS;
        token15 = tokens.length >= 15 ? tokens[14] : ZERO_ADDRESS;
        token16 = tokens.length >= 16 ? tokens[15] : ZERO_ADDRESS;
        token17 = tokens.length >= 17 ? tokens[16] : ZERO_ADDRESS;
        token18 = tokens.length >= 18 ? tokens[17] : ZERO_ADDRESS;
        token19 = tokens.length >= 19 ? tokens[18] : ZERO_ADDRESS;
        token20 = tokens.length >= 20 ? tokens[19] : ZERO_ADDRESS;

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
        weight11 = weights.length >= 11 ? weights[10] : 0;
        weight12 = weights.length >= 12 ? weights[11] : 0;
        weight13 = weights.length >= 13 ? weights[12] : 0;
        weight14 = weights.length >= 14 ? weights[13] : 0;
        weight15 = weights.length >= 15 ? weights[14] : 0;
        weight16 = weights.length >= 16 ? weights[15] : 0;
        weight17 = weights.length >= 17 ? weights[16] : 0;
        weight18 = weights.length >= 18 ? weights[17] : 0;
        weight19 = weights.length >= 19 ? weights[18] : 0;
        weight20 = weights.length >= 20 ? weights[19] : 0;

        multiplier1  = 10**(18 - IERC20Metadata(tokens[0]).decimals());
        multiplier2  = 10**(18 - IERC20Metadata(tokens[0]).decimals());
        multiplier3  = tokens.length >= 3  ? 10**(18 - IERC20Metadata(tokens[2 ]).decimals()) : 0;
        multiplier4  = tokens.length >= 4  ? 10**(18 - IERC20Metadata(tokens[3 ]).decimals()) : 0;
        multiplier5  = tokens.length >= 5  ? 10**(18 - IERC20Metadata(tokens[4 ]).decimals()) : 0;
        multiplier6  = tokens.length >= 6  ? 10**(18 - IERC20Metadata(tokens[5 ]).decimals()) : 0;
        multiplier7  = tokens.length >= 7  ? 10**(18 - IERC20Metadata(tokens[6 ]).decimals()) : 0;
        multiplier8  = tokens.length >= 8  ? 10**(18 - IERC20Metadata(tokens[7 ]).decimals()) : 0;
        multiplier9  = tokens.length >= 9  ? 10**(18 - IERC20Metadata(tokens[8 ]).decimals()) : 0;
        multiplier10 = tokens.length >= 10 ? 10**(18 - IERC20Metadata(tokens[9 ]).decimals()) : 0;
        multiplier11 = tokens.length >= 11 ? 10**(18 - IERC20Metadata(tokens[10]).decimals()) : 0;
        multiplier12 = tokens.length >= 12 ? 10**(18 - IERC20Metadata(tokens[11]).decimals()) : 0;
        multiplier13 = tokens.length >= 13 ? 10**(18 - IERC20Metadata(tokens[12]).decimals()) : 0;
        multiplier14 = tokens.length >= 14 ? 10**(18 - IERC20Metadata(tokens[13]).decimals()) : 0;
        multiplier15 = tokens.length >= 15 ? 10**(18 - IERC20Metadata(tokens[14]).decimals()) : 0;
        multiplier16 = tokens.length >= 16 ? 10**(18 - IERC20Metadata(tokens[15]).decimals()) : 0;
        multiplier17 = tokens.length >= 17 ? 10**(18 - IERC20Metadata(tokens[16]).decimals()) : 0;
        multiplier18 = tokens.length >= 18 ? 10**(18 - IERC20Metadata(tokens[17]).decimals()) : 0;
        multiplier19 = tokens.length >= 19 ? 10**(18 - IERC20Metadata(tokens[18]).decimals()) : 0;
        multiplier20 = tokens.length >= 20 ? 10**(18 - IERC20Metadata(tokens[19]).decimals()) : 0;
    }
}