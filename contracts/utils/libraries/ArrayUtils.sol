// SPDX-License-Identifier: GPL-3.0-or-later
// @title Utils for checking arrays
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library ArrayUtils {
    /**
     * @notice Check that there are only unique values in array
     * @param array Array with values
     * @return flag True - array contains unique elements, False - there are possible duplications
     */
    function checkUniqueness(uint256[] memory array) internal pure returns (bool flag) {
        if (array.length == 1) return true;

        flag = true;
        uint256 val = array[0];
        for (uint256 valId = 1; valId < array.length; valId++) {
            flag = flag && (val < array[valId]);
            if (!flag) return flag;
            val = array[valId];
        }
    }

    /**
     * @notice Check that there are only unique values in array
     * @param array Array with values
     * @return flag True - array contains unique elements, False - there are possible duplications
     */
    function checkUniqueness(address[] memory array) internal pure returns (bool flag) {
        if (array.length == 1) return true;

        flag = true;
        address val = array[0];
        for (uint256 valId = 1; valId < array.length; valId++) {
            flag = flag && (val < array[valId]);
            if (!flag) return flag;
            val = array[valId];
        }
    }

    /**
     * @notice Check that there are only unique values in array
     * @param array Array with values
     * @return flag True - array contains unique elements, False - there are possible duplications
     */
    function checkUniqueness(IERC20[] memory array) internal pure returns (bool flag) {
        if (array.length == 1) return true;

        flag = true;
        IERC20 val = array[0];
        for (uint256 valId = 1; valId < array.length; valId++) {
            flag = flag && (val < array[valId]);
            if (!flag) return flag;
            val = array[valId];
        }
    }

    /**
     * @notice Check if two arrays have the same length
     * @dev Fails with require() if arrays have different legnths
     * @param l1 Length of first array
     * @param l2 Lenght of second array
     */
    function checkArrayLength(uint256 l1, uint256 l2) internal pure {
        require(
            l1 == l2,
            "Array length mismatch"
        );
    }

    /**
     * @notice Check if two arrays have the same length
     * @dev Fails with require() if arrays have different legnths
     * @param array1 Length of first array
     * @param array2 Lenght of second array
     */
    function checkArrayLength(uint256[] memory array1, address[] memory array2) internal pure {
        checkArrayLength(array1.length, array2.length);
    }

    /**
     * @notice Check if two arrays have the same length
     * @dev Fails with require() if arrays have different legnths
     * @param array1 Length of first array
     * @param array2 Lenght of second array
     */
    function checkArrayLength(address[] memory array1, uint256[] memory array2) internal pure {
        checkArrayLength(array1.length, array2.length);
    }

    /**
     * @notice Check if two arrays have the same length
     * @dev Fails with require() if arrays have different legnths
     * @param array1 Length of first array
     * @param array2 Lenght of second array
     */
    function checkArrayLength(uint256[] memory array1, uint256[] memory array2) internal pure {
        checkArrayLength(array1.length, array2.length);
    }

    /**
     * @notice Check if two arrays have the same length
     * @dev Fails with require() if arrays have different legnths
     * @param array1 Length of first array
     * @param array2 Lenght of second array
     */
    function checkArrayLength(address[] memory array1, address[] memory array2) internal pure {
        checkArrayLength(array1.length, array2.length);
    }

    /**
     * @notice Check if two arrays have the same length
     * @dev Fails with require() if arrays have different legnths
     * @param array1 Length of first array
     * @param array2 Lenght of second array
     */
    function checkArrayLength(IERC20[] memory array1, address[] memory array2) internal pure {
        checkArrayLength(array1.length, array2.length);
    }

    /**
     * @notice Check if two arrays have the same length
     * @dev Fails with require() if arrays have different legnths
     * @param array1 Length of first array
     * @param array2 Lenght of second array
     */
    function checkArrayLength(IERC20[] memory array1, uint256[] memory array2) internal pure {
        checkArrayLength(array1.length, array2.length);
    }
}