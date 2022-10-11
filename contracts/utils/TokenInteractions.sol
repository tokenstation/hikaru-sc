// SPDX-License-Identifier: GPL-3.0-or-later
// @title Contract for ERC20 token transfers
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { TokenUtils } from "./libraries/TokenUtils.sol";

contract TokenInteractions {
    using TokenUtils for IERC20;
    
    /**
     * @notice Transfer tokens from user and return balance deltas
     * @param tokens Token addresses
     * @param amounts Amounts of tokens to transfer
     * @param user Where to transfer tokens from
     * @return balanceDeltas Amount of tokens received from user
     */
    function _transferTokensFrom(
        address[] memory tokens,
        uint256[] memory amounts,
        address user
    ) 
        internal
        returns (uint256[] memory balanceDeltas)
    {
        balanceDeltas = new uint256[](tokens.length);
        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            balanceDeltas[tokenId] = _transferFrom(tokens[tokenId], user, amounts[tokenId]);
        }
    }

    /**
     * @notice Transfer tokens to user and return balance deltas
     * @param tokens Token addresses
     * @param amounts Amounts of tokens to transfer
     * @param user Who will receive tokens
     * @return balanceDeltas Amount of tokens transferred to user
     */
    function _transferTokensTo(
        address[] memory tokens,
        uint256[] memory amounts,
        address user
    ) 
        internal
        returns (uint256[] memory balanceDeltas)
    {
        balanceDeltas = new uint256[](tokens.length);
        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            balanceDeltas[tokenId] = _transferTo(tokens[tokenId], user, amounts[tokenId]);
        }
    }
    
    /**
     * @notice Utility function for transferFrom
     * @param token Token address
     * @param user Address to transfer from
     * @param amount Amount of tokens to transfer from
     * @return Amount of tokens received
     */
    function _transferFrom(
        address token,
        address user,
        uint256 amount
    ) 
        internal
        returns (uint256)
    {
        return IERC20(token).transferFromUser(user, amount);
    }

    /**
     * @notice Utility function for transfer
     * @param token Token address
     * @param user Address to transfer to
     * @param amount Amount of tokens to transfer
     * @return Amount of tokens transferred
     */
    function _transferTo(
        address token,
        address user,
        uint256 amount
    )
        internal
        returns (uint256)
    {
        return IERC20(token).transferToUser(user, amount);
    }
}