pragma solidity 0.8.6;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {

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
    {
        _mint(to, amount);
    }

    function burn(
        address from,
        uint256 amount
    )
        external
    {
        _burn(from, amount);
    }
}