// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IERC20Mintable {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

contract ERC20Mock is ERC20, IERC20Mintable {

    uint8 _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) 
        ERC20(name, symbol)
    {
        _decimals = decimals_;
    }

    function decimals() 
        public 
        view 
        override 
        returns(uint8) 
    {
        return _decimals;
    }

    function mint(
        address to,
        uint256 amount
    )
        external
        override
    {
        _mint(to, amount);
    }

    function burn(
        address from,
        uint256 amount
    )
        external
        override
    {
        _burn(from, amount);
    }
}