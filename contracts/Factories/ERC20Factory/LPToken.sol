// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

import { ILPERC20 } from "./interfaces/ILPToken.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LPVault {
    address public vaultAddress;

    constructor (
        address vaultAddress_
    ) {
        vaultAddress = vaultAddress_;
    }
    
    modifier onlyVault(address caller) {
        require(
            caller == vaultAddress,
            "Function can only be called by vault"
        );
        _;
    }
}

contract LPTokenERC20 is LPVault, ERC20, ILPERC20 {

    constructor(
        address vaultAddress_,
        string memory name_, 
        string memory symbol_
    )
        ERC20(name_, symbol_)
        LPVault(vaultAddress_)
    {

    }

    function mint(
        address to,
        uint256 amount
    )
        external
        onlyVault(msg.sender)
    {
        _mint(to, amount);
    }

    function burn(
        address from,
        uint256 amount
    )
        external
        onlyVault(msg.sender)
    {
        _burn(from, amount);
    }
}
