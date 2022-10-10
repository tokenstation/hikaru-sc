// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface ISunSwapExchange {

    // TODO: add interfaces for swap result calculations

    /**
     * @notice Get factory address of exchange contract
     * @return Address of factory
     */
    function factory() external view returns (address);

    /**
     * @notice Buy ERC20 token using another ERC20 token
     * @param tokens_bought Amount of tokens to buy
     * @param max_tokens_sold ???
     * @param max_trx_sold ???
     * @param deadline TX deadline
     * @param recipient Who will receive tokens
     * @param token_addr ???
     * @return ???
     */
    function tokenToTokenTransferOutput(
        uint256 tokens_bought, 
        uint256 max_tokens_sold,
        uint256 max_trx_sold, 
        uint256 deadline, 
        address recipient, 
        address token_addr
    ) external returns (uint256);

    /**
     * @notice Sell ERC20 tokens and receive ERC20 token
     * @param tokens_sold Amount of tokens to sell
     * @param min_tokens_bought ???
     * @param min_trx_bought ???
     * @param deadline TX deadline
     * @param recipient Who will receive tokens
     * @param token_addr ???
     * @return ???
     */
    function tokenToTokenTransferInput(
        uint256 tokens_sold, 
        uint256 min_tokens_bought,
        uint256 min_trx_bought, 
        uint256 deadline, 
        address recipient, 
        address token_addr
    ) external returns (uint256);

    /**
     * @notice Buy TRX using ERC20
     * @param trx_bought Amount of TRX to buy
     * @param max_tokens Max amount of tokens to use for operation
     * @param deadline TX deadline
     * @param recipient Who will receive TRX
     * @return ???
     */
    function tokenToTrxTransferOutput(
        uint256 trx_bought, 
        uint256 max_tokens, 
        uint256 deadline, 
        address recipient
    ) external returns (uint256);

    /**
     * @notice Sell ERC20 to obtain TRX
     * @param tokens_sold Amount of tokens to sell
     * @param min_trx Min amount of TRX to receive
     * @param deadline TX deadline
     * @param recipient Who will receive TRX
     * @return ???
     */
    function tokenToTrxTransferInput(
        uint256 tokens_sold, 
        uint256 min_trx, 
        uint256 deadline,
        address recipient
    ) external returns (uint256);

    /**
     * @notice Buy tokens using TRX
     * @param tokens_bought Amount of tokens to buy
     * @param deadline TX deadline
     * @param recipient Who will receive tokens
     * @return ???
     */
    function trxToTokenTransferOutput(
        uint256 tokens_bought, 
        uint256 deadline, 
        address recipient
    ) external payable returns (uint256);

    /**
     * @notice Sell TRX to obtain ERC20
     * @param min_tokens Min amount of tokens to receive
     * @param deadline TX deadline
     * @param recipient Who will receive ERC20 tokens
     * @return ???
     */
    function trxToTokenTransferInput(
        uint256 min_tokens, 
        uint256 deadline, 
        address recipient
    ) external payable returns(uint256);
}