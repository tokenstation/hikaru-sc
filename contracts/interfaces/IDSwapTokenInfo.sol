// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

interface IDSwapTokenInfo {
    function getToken(uint8 tokenId) external returns(address);

    function getTokenId(address token) external returns(uint8);

    function getTokenBalance(uint8 tokenId) external returns(uint256);
}