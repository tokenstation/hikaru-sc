// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.6;

interface ISunSwapFactory {
    // Get token's exchange smart contract (ERC20 <-> TRX)
    function getExchange(address token) external view returns (address payable);
}