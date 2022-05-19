// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { IFlashloan, IFlashloanReceiver } from "./interfaces/IFlashloan.sol";

contract ReentrancyGuard {
    uint256 constant internal LOCK = 1;
    uint256 constant internal UNLOCK = 0;
    uint256 state;

    modifier reentrancyGuard() {
        require(
            state == UNLOCK,
            "Reentrancy attempt"
        );
        state = LOCK;
        _;
        state = UNLOCK;
    }
}

contract Flashloan is ReentrancyGuard, IFlashloan {

    // TODO: add fee receiver setters

    address feeReceiver;

    function flashloan(
        IFlashloanReceiver receiver,
        IERC20[] memory tokens, 
        uint256[] memory amounts, 
        bytes memory callbackData
    ) 
        external
        reentrancyGuard
    {
        uint256[] memory fees = new uint256[](tokens.length);
        uint256[] memory initBalances = new uint256[](tokens.length);
        address token = address(1);

        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            _checkTokens(token, address(tokens[tokenId]));
            token = address(tokens[tokenId]);
            initBalances[tokenId] = tokens[tokenId].balanceOf(address(this));
            fees[tokenId] = _getFees(amounts[tokenId]);
            IERC20(tokens[tokenId]).transfer(address(receiver), amounts[tokenId]);
        }

        receiver.receiveFlashLoan(tokens, amounts, fees, callbackData);

        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            uint256 balanceAfter = tokens[tokenId].balanceOf(address(this));
            require(
                balanceAfter >= initBalances[tokenId] + fees[tokenId],
                "Invalid amount repaid"
            );
            tokens[tokenId].transfer(feeReceiver, balanceAfter - initBalances[tokenId]);
        } 
    }

    function _checkTokens(
        address token1,
        address token2
    ) 
        internal 
        pure
    {
        require(
            token1 != address(0) &&
            token1 < token2,
            "Unsorted array or token duplication"
        );
    }

    function _getFees(
        uint256 amount
    )
        internal
        view
        returns(uint256 fee)
    {

    }
}