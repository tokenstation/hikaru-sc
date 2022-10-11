// SPDX-License-Identifier: GPL-3.0-or-later
// @title ERC165 interface for SunSwap integration
// @author tokenstation.dev

pragma solidity 0.8.6;

import "../../../Vaults/interfaces/IOperations.sol";
import "../../../Vaults/interfaces/IVaultPoolInfo.sol";
import "../../../Vaults/BalanceManager/interfaces/IExternalBalanceManager.sol";

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

contract SunSwapERC165 is IERC165 {
    constructor() {}

    function supportsInterface(bytes4 interfaceId) external override pure returns (bool) {
        return 
            interfaceId == type(IERC165).interfaceId ||

            interfaceId == type(ISwap).interfaceId ||

            interfaceId == type(IFullPoolJoin).interfaceId ||

            interfaceId == type(IFullPoolExit).interfaceId ||

            interfaceId == type(IExternalBalanceManager).interfaceId ||
            
            interfaceId == type(IVaultPoolInfo).interfaceId;
    }
}