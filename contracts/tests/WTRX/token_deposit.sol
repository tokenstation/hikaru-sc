
pragma solidity ^0.4.24;
import "./trc20.sol";

contract ITokenDeposit is TRC20 {
    function deposit() public payable {}
    function withdraw(uint) public {}
}

