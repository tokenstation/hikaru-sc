// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.6;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BAL#" part is a known constant
        // (0x42414c23): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(176, add(0x48494B41525523000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 10)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Misc
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;
    uint256 internal constant ZERO_INVARIANT = 105;

    // Libs
    uint256 internal constant TOKEN_DUPLICATION = 200;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 201;
    uint256 internal constant ERC20_INVALID_TRANSFER_FROM_BALANCE_CHANGE = 202;
    uint256 internal constant ERC20_INVALID_TRANSFER_BALANCE_CHANGE = 203;
    uint256 internal constant REENTRANCY = 204;
    uint256 internal constant CODE_DEPLOYMENT_FAILED = 205;
    uint256 internal constant ZERO_ADDRESS = 206;
    uint256 internal constant ARRAY_LENGTH_MISMATCH = 207;

    // Access
    uint256 internal constant CALLER_IS_NOT_MANAGER = 300;
    uint256 internal constant CALLER_IS_NOT_VAULT = 301;
    uint256 internal constant CALLER_IS_NOT_FACTORY = 302;

    // Pools
    uint256 internal constant POOL_WEIGHTS_ARRAY_LENGTH_MISMATCH = 400;
    uint256 internal constant MAX_TOKENS = 401;
    uint256 internal constant MIN_WEIGHT = 402;
    uint256 internal constant INVALID_WEIGHTS_SUM = 403;
    uint256 internal constant INVALID_TOKEN = 404;
    uint256 internal constant INITIALIZATION_ZERO_AMOUNT = 405;
    uint256 internal constant SAME_TOKEN_SWAP = 406;
    uint256 internal constant SWAP_NOT_ENOUGH_RECEIVED = 407;
    uint256 internal constant SWAP_TOO_MUCH_PAID = 408;
    uint256 internal constant MAX_IN_RATIO = 409;
    uint256 internal constant MAX_OUT_RATIO = 410;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 411;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 412;

    // Vaults
    uint256 internal constant VAULT_DOES_NOT_IMPLEMENT_REQUIRED_INTERFACE = 500;
    uint256 internal constant FACTORY_ADDRESS_MUST_BE_ZERO_ADDRESS = 501;
    uint256 internal constant INVALID_VIRTUAL_SWAP_PATH = 502;
    uint256 internal constant EMPTY_SWAP_PATH = 503;
    uint256 internal constant UNKNOWN_POOL_ADDRESS = 504;
    uint256 internal constant DEADLINE = 505;

    // Factory
    uint256 internal constant POOL_WAS_NOT_REGISTERED_IN_VAULT = 600;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 701;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 702;
    uint256 internal constant NOT_ENOUGH_FEE_RECEIVED = 703;
    uint256 internal constant TOO_MUCH_FEE_WITHDRAWN = 704;
    uint256 internal constant PROTOCOL_FEE_TOO_HIGH = 705;

}
