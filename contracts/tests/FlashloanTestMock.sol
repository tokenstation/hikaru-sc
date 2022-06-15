// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import {IERC20Mintable, ERC20, IERC20} from "./ERC20Mock.sol";

import {IFlashloan, IFlashloanReceiver} from "../Vaults/Flashloan/interfaces/IFlashloan.sol";

contract FlashloanerMock is IFlashloanReceiver {
    bool public returnFlashloan;
    bool public tryReentrancy;
    bool public tryToStealTokens;
    address public vaultAddress;

    IERC20[] public receivedTokens;
    uint256[] public receivedAmounts;
    uint256[] public receivedFees;

    function initiateFlashloan(
        address vault, 
        IERC20[] memory tokens, 
        uint256[] memory amounts, 
        bool _returnFlashloan, 
        bool _tryReentrancy, 
        bool _tryToStealTokens
    )
        external
    {
        vaultAddress = vault;
        _initiateFlashloan(vault, tokens, amounts, _returnFlashloan, _tryReentrancy, _tryToStealTokens);
    }


    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory fees,
        bytes memory userData
    ) 
        external
        override
    {
        require(
            msg.sender == vaultAddress,
            "Function can only be called by vault"
        );
        receivedTokens = tokens;
        receivedAmounts = amounts;
        receivedFees = fees;
        _tryToDecodeData(userData);

        // We try not to return tokens to vault
        // Operation must revert
        if (returnFlashloan) {
            _mintTokens(tokens, _sumArrays(amounts, fees));
            _transferTokensToVault(tokens, _sumArrays(amounts, fees), vaultAddress);
        }

        // We try to reenter contract in order to get another flashloan
        if (tryReentrancy) {
            _initiateFlashloan(
                vaultAddress,
                tokens,
                _sumArrays(amounts, fees),
                returnFlashloan,
                tryReentrancy,
                tryToStealTokens
            );
        }

        // Here we try to manipulate tokens of pool
        // First we mint tokens to vault before flashloan and burn them after
        if(tryToStealTokens) {
            _burnTokensFromVault();
        }
    }

    function _burnTokensFromVault(
        IERC20[] memory tokens
    )
        internal
    {
        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            uint256 balance = tokens[tokenId].balanceOf(vaultAddress);
            IERC20Mintable token = IERC20Mintable(address(tokens[tokenId]));
            token.burn(vaultAddress, balance);
        }
    }

    function _mintTokens(
        IERC20[] memory tokens,
        uint256[] memory amounts
    ) 
        internal 
    {
        for(uint256 tokenId = 0; tokenId < tokens.length; tokenId++)  {
            uint256 balance = tokens[tokenId].balanceOf(address(this));
            if (balance < amounts[tokenId]) {
                IERC20Mintable token = IERC20Mintable(address(tokens[tokenId]));
                token.mint(address(this), amounts[tokenId]);
            }
        }
    }

    function _transferTokensToVault(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        address to
    )
        internal
    {
        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            tokens[tokenId].transfer(to, amounts[tokenId]);
        }
    }

    function _initiateFlashloan(
        address vault,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bool _returnFlashloan,
        bool _tryReentrancy,
        bool _tryToStealTokens
    ) 
        internal 
    {
        IFlashloan(vault).flashloan(
            IFlashloanReceiver(address(this)), 
            tokens, 
            amounts, 
            abi.encode(_returnFlashloan, _tryReentrancy, _tryToStealTokens)
        );
    }

    function _burnTokensFromVault() internal {}

    function _sumArrays(
        uint256[] memory a, 
        uint256[] memory b
    ) 
        internal 
        pure
        returns (uint256[] memory resArray)
    {
        resArray = new uint256[](a.length);
        for(uint256 tokenId = 0; tokenId < a.length; tokenId++) {
            resArray[tokenId] = a[tokenId] + b[tokenId];
        }
    }

    function _tryToDecodeData(
        bytes memory data
    ) 
        internal
    {
        if (data.length == 0) return;
        (returnFlashloan, tryReentrancy, tryToStealTokens) = abi.decode(data, (bool, bool, bool));
    }
}