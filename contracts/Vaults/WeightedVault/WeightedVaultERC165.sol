// SPDX-License-Identifier: GPL-3.0-or-later
// @title Contract that implements ERC165 for Weighted Vault
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { ISwap } from "../interfaces/ISwap.sol";
import { IFullPoolJoin, IPartialPoolJoin, IJoinPoolSingleToken } from "../interfaces/IJoin.sol";
import { IFullPoolExit, IExitPoolSingleToken } from "../interfaces/IExit.sol";
import { IFlashloan } from "../Flashloan/interfaces/IFlashloan.sol";
import { IExternalBalanceManager } from "../BalanceManager/interfaces/IExternalBalanceManager.sol";
import { IWeightedVault } from "./interfaces/IWeightedVault.sol";
import { IVaultPoolInfo } from "../interfaces/IVaultPoolInfo.sol";


contract WeightedVaultERC165 is IERC165 {

    /**
     * @notice Check if vault implements interface
     * @param interfaceId Interface id
     * @return If interface is implemented
     */
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

            interfaceId == type(ISwap).interfaceId ||

            interfaceId == type(IFullPoolJoin).interfaceId ||
            interfaceId == type(IPartialPoolJoin).interfaceId ||
            interfaceId == type(IJoinPoolSingleToken).interfaceId ||

            interfaceId == type(IFullPoolExit).interfaceId ||
            interfaceId == type(IExitPoolSingleToken).interfaceId ||

            interfaceId == type(IFlashloan).interfaceId ||

            interfaceId == type(IExternalBalanceManager).interfaceId ||

            interfaceId == type(IWeightedVault).interfaceId ||
            
            interfaceId == type(IVaultPoolInfo).interfaceId;
    }
}