// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining pool parameters
// @author tokenstation.dev

pragma solidity 0.8.6;

interface IWeightedStorage {
    /**
     * @notice Get id of token in pool
     * @dev Fails with require() if token is not presented in pool
     * @param token Address of token
     * @return tokenId Id of token in pool which can be used to access paramters for token in array
     */
    function getTokenId(address token) external view returns (uint256 tokenId);

    /**
     * @notice Obtain weight of token in pool
     * @param token Address of token
     * @return Weight of token
     */
    function getWeight(address token) external view returns (uint256);

    /**
     * @notice Get multiplier of token
     * @dev TokenMultiplier = (10 ^ (18 - tokenDecimals))
     * @param token Address of token
     * @return Token multiplier
     */
    function getMultiplier(address token) external view returns (uint256);

    /**
     * @notice Get array of all tokens presented in pool
     * @return tokens Token array
     */
    function getTokens() external view returns (address[] memory tokens);

    /**
     * @notice Get array of token weights
     * @return weights Token weights
     */
    function getWeights() external view returns (uint256[] memory weights);

    /**
     * @notice Get array of token multipliers
     * @dev It may be cheaper to get multipliers from pool for on-chain calculations, because there are no calls to external contracts inside
     * @return multipliers Token multipliers
     */
    function getMultipliers() external view returns (uint256[] memory multipliers);

    /**
     * @notice Get amount of tokens in pool
     * @return Amount of tokens in pool
     */
    function getNTokens() external view returns (uint256);
}