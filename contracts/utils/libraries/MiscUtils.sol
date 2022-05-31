// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library MiscUtils {
    function checkUniqueness(uint256[] memory array) public pure returns (bool flag) {
        if (array.length == 1) return true;

        flag = true;
        uint256 val = array[0];
        for (uint256 valId = 1; valId < array.length; valId++) {
            flag = flag && (val < array[valId]);
            if (!flag) return flag;
            val = array[valId];
        }
    }

    function checkUniqueness(address[] memory array) public pure returns (bool flag) {
        if (array.length == 1) return true;

        flag = true;
        address val = array[0];
        for (uint256 valId = 1; valId < array.length; valId++) {
            flag = flag && (val < array[valId]);
            if (!flag) return flag;
            val = array[valId];
        }
    }

    function checkUniqueness(IERC20[] memory array) public pure returns (bool flag) {
        if (array.length == 1) return true;

        flag = true;
        IERC20 val = array[0];
        for (uint256 valId = 1; valId < array.length; valId++) {
            flag = flag && (val < array[valId]);
            if (!flag) return flag;
            val = array[valId];
        }
    }

    function checkArrayLength(uint256 l1, uint256 l2) public pure {
        require(
            l1 == l2,
            "Array length mismatch"
        );
    }

    function checkArrayLength(uint256[] memory array1, address[] memory array2) public pure {
        checkArrayLength(array1.length, array2.length);
    }

    function checkArrayLength(address[] memory array1, uint256[] memory array2) public pure {
        checkArrayLength(array1.length, array2.length);
    }

    function checkArrayLength(uint256[] memory array1, uint256[] memory array2) public pure {
        checkArrayLength(array1.length, array2.length);
    }

    function checkArrayLength(address[] memory array1, address[] memory array2) public pure {
        checkArrayLength(array1.length, array2.length);
    }

    function checkArrayLength(IERC20[] memory array1, address[] memory array2) public pure {
        checkArrayLength(array1.length, array2.length);
    }

    function checkArrayLength(IERC20[] memory array1, uint256[] memory array2) public pure {
        checkArrayLength(array1.length, array2.length);
    }
}