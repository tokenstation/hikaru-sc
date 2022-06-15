// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { ISellTokens, IBuyTokens, IFullPoolJoin, IPartialPoolJoin, IFullPoolExit, IExitPoolSingleToken } from "../interfaces/IOperations.sol";
import { IFlashloan } from "../Flashloan/interfaces/IFlashloan.sol";
import { IExternalBalanceManager } from "../BalanceManager/interfaces/IExternalBalanceManager.sol";
import { IWeightedVault } from "./interfaces/IWeightedVault.sol";


contract WeightedVaultERC165 is IERC165 {
    function supportsInterface(
        bytes4 interfaceId
    ) 
        external
        override
        pure
        returns (bool)
    {
        return 
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(ISellTokens).interfaceId ||
            interfaceId == type(IBuyTokens).interfaceId ||
            interfaceId == type(IFullPoolJoin).interfaceId ||
            interfaceId == type(IPartialPoolJoin).interfaceId ||
            interfaceId == type(IFullPoolExit).interfaceId ||
            interfaceId == type(IExitPoolSingleToken).interfaceId ||
            interfaceId == type(IFlashloan).interfaceId ||
            interfaceId == type(IExternalBalanceManager).interfaceId ||
            interfaceId == type(IWeightedVault).interfaceId;
    }
}