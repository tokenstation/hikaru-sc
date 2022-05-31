// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

interface IWeightedStorage {
    function getTokenId(address token) external view returns (uint256 tokenId);
    function getWeight(address token) external view returns (uint256);
    function getMultiplier(address token) external view returns (uint256);
    function getTokens() external view returns (address[] memory tokens);
    function getWeights() external view returns (uint256[] memory weights);
    function getMultipliers() external view returns (uint256[] memory multipliers);
}