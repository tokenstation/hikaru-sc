// SPDX-License-Identifier: GPL-3.0-or-later
// @title Utils for checking arrays
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Errors/ErrorLib.sol";

library ArrayUtils {
    /**
     * @notice Check that there are only unique values in array
     * @dev If array is not sorted - fails either with token duplication or unsorted array error
     * @param array Array with values
     */
    function checkUniqueness(address[] memory array) internal pure {
        if (array.length == 1) return;
        
        address val = array[0];
        for (uint256 valId = 1; valId < array.length; valId++) {
             _require(
                val != array[valId],
                Errors.TOKEN_DUPLICATION
            );
            _require(
                val < array[valId],
                Errors.UNSORTED_ARRAY
            );
            val = array[valId];
        }
    }

    /**
     * @notice Check that there are only unique values in array
     * @dev If array is not sorted - fails either with token duplication or unsorted array error
     * @param array Array with values
     */
    function checkUniqueness(IERC20[] memory array) internal pure {
        if (array.length == 1) return;

        IERC20 val = array[0];
        for (uint256 valId = 1; valId < array.length; valId++) {
             _require(
                val != array[valId],
                Errors.TOKEN_DUPLICATION
            );
            _require(
                val < array[valId],
                Errors.UNSORTED_ARRAY
            );
            val = array[valId];
        }
    }

    /**
     * @notice Check if two arrays have the same length
     * @dev Fails with require() if arrays have different legnths
     * @param l1 Length of first array
     * @param l2 Lenght of second array
     */
    function checkArrayLength(uint256 l1, uint256 l2) internal pure returns (bool) {
        return l1 == l2;
    }

    /**
     * @notice Check if two arrays have the same length
     * @dev Fails with require() if arrays have different legnths
     * @param array1 Length of first array
     * @param array2 Lenght of second array
     */
    function checkArrayLength(uint256[] memory array1, address[] memory array2) internal pure returns (bool) {
        return checkArrayLength(array1.length, array2.length);
    }

    /**
     * @notice Check if two arrays have the same length
     * @dev Fails with require() if arrays have different legnths
     * @param array1 Length of first array
     * @param array2 Lenght of second array
     */
    function checkArrayLength(address[] memory array1, uint256[] memory array2) internal pure returns (bool) {
        return checkArrayLength(array1.length, array2.length);
    }

    /**
     * @notice Check if two arrays have the same length
     * @dev Fails with require() if arrays have different legnths
     * @param array1 Length of first array
     * @param array2 Lenght of second array
     */
    function checkArrayLength(uint256[] memory array1, uint256[] memory array2) internal pure returns (bool) {
        return checkArrayLength(array1.length, array2.length);
    }

    /**
     * @notice Check if two arrays have the same length
     * @dev Fails with require() if arrays have different legnths
     * @param array1 Length of first array
     * @param array2 Lenght of second array
     */
    function checkArrayLength(address[] memory array1, address[] memory array2) internal pure returns (bool) {
        return checkArrayLength(array1.length, array2.length);
    }

    /**
     * @notice Check if two arrays have the same length
     * @dev Fails with require() if arrays have different legnths
     * @param array1 Length of first array
     * @param array2 Lenght of second array
     */
    function checkArrayLength(IERC20[] memory array1, address[] memory array2) internal pure returns (bool) {
        return checkArrayLength(array1.length, array2.length);
    }

    /**
     * @notice Check if two arrays have the same length
     * @dev Fails with require() if arrays have different legnths
     * @param array1 Length of first array
     * @param array2 Lenght of second array
     */
    function checkArrayLength(IERC20[] memory array1, uint256[] memory array2) internal pure returns (bool) {
        return checkArrayLength(array1.length, array2.length);
    }
}
