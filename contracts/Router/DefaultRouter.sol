// SPDX-License-Identifier: GPL-3.0-or-later
// @title Router for default interfaces defined in v0.6 for vaults
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { TokenUtils } from "../utils/libraries/TokenUtils.sol";
import "../Vaults/interfaces/IVaultPoolInfo.sol";
import "../Vaults/interfaces/IOperations.sol";
import "../utils/Errors/ErrorLib.sol";
import "../Vaults/BalanceManager/interfaces/IExternalBalanceManager.sol";

contract DefaultRouter {

    enum TokenAllowanceStatus {NO_ALLOWANCE, REQUIRES_ALLOWANCE_EVERY_TIME, INF_ALLOWANCE}
    
    using TokenUtils for IERC20;

    uint256 constant MAX_UINT256 = type(uint256).max;
    mapping(address => mapping(address => TokenAllowanceStatus)) public _tokenAllowances;

    function _checkContractInterface(
        address vault,
        bytes4 interfaceId
    ) 
        internal
        view
    {
        _require(
            IERC165(vault).supportsInterface(interfaceId),
            Errors.VAULT_DOES_NOT_IMPLEMENT_REQUIRED_INTERFACE
        );
    }

    /**
     * @dev Here we check token allowances to vaults before executing operations
     * There are three token allowance types:
     * 1. INF_ALLOWANCES -> if token allowes uint256 approve
     * 2. REQUIRES_APPROVE_EVERY_TIME -> if it's not possible to set uint256 allowance,
     * most likely token uses uint96, which is ~8e28 (10 billion tokens with 18 decimals), which may not be enough
     * so we perform approve on every operation
     * 3. NO_ALLOWANCE -> there was no attempt of setting allowance
     *
     * Generally it will save gas for users as it mostly will require only read from storage
     */
    function _checkTokenAllowance(
        address tokenAddress,
        uint256 amount,
        address vault
    )
        internal
    {
        TokenAllowanceStatus ts = _tokenAllowances[vault][tokenAddress];
        if (ts == TokenAllowanceStatus.INF_ALLOWANCE) return;

        IERC20 token = IERC20(tokenAddress);
        if (ts == TokenAllowanceStatus.REQUIRES_ALLOWANCE_EVERY_TIME) {
            token.approve(vault, amount);
            return;
        }

        if (ts == TokenAllowanceStatus.NO_ALLOWANCE) {
            token.approve(vault, MAX_UINT256);
            uint256 allowance = token.allowance(address(this), vault);
            _tokenAllowances[vault][tokenAddress] = allowance == MAX_UINT256 ?
                TokenAllowanceStatus.INF_ALLOWANCE :
                TokenAllowanceStatus.REQUIRES_ALLOWANCE_EVERY_TIME;
            return;
        }
    }

    function _checkAllowanceAndSetInf(
        address[] memory tokens,
        uint256[] memory amounts,
        address vault
    )
        internal
    {
        for (uint256 id = 0; id < tokens.length; id++) {
            _checkTokenAllowance(tokens[id], amounts[id], vault);
        }
    }

    function _transferTokenFromUser(
        address token,
        address user,
        uint256 amount
    ) 
        internal
        returns (uint256) 
    {
        return IERC20(token).transferFromUser(user, amount);
    }

    function _transferTokensFromUser(
        address[] memory tokens,
        address user,
        uint256[] memory amounts
    )
        internal
        returns (uint256[] memory amountsReceived)
    {
        amountsReceived = new uint256[](tokens.length);
        for (uint256 id = 0; id < tokens.length; id++) {
            amountsReceived[id] = _transferTokenFromUser(tokens[id], user, amounts[id]);
        }
    }

    function swap(
        address vault,
        SwapRoute[] calldata swapRoute,
        SwapType swapType,
        uint256 swapAmount,
        uint256 minMaxAmount,
        address receiver,
        uint64 deadline
    )
        external
        returns (uint256)
    {
        _checkContractInterface(
            vault, 
            type(ISwap).interfaceId
        );

        uint256 amountIn;
        if (swapType == SwapType.Sell) {
            amountIn = swapAmount;
        }

        if (swapType == SwapType.Buy) {
            amountIn = ISwap(vault).calculateSwap(swapRoute, swapType, swapAmount);
        }

        _checkTokenAllowance(swapRoute[0].tokenIn, amountIn, vault);
        _transferTokenFromUser(swapRoute[0].tokenIn, msg.sender, amountIn);

        return ISwap(vault).swap(swapRoute, swapType, swapAmount, minMaxAmount, receiver, deadline);
    }

    function calculateSwap(
        address vault,
        SwapRoute[] calldata swapRoute,
        SwapType swapType,
        uint256 swapAmount
    )
        external
        view
        returns (uint256)
    {
        _checkContractInterface(
            vault, 
            type(ISwap).interfaceId
        );
        return ISwap(vault).calculateSwap(swapRoute, swapType, swapAmount);
    }

    function fullJoin(
        address vault,
        address pool,
        uint256[] memory amounts,
        uint256 minLPAmount,
        uint64 deadline
    ) 
        external
        returns (uint256)
    {
        _checkContractInterface(
            vault, 
            type(IFullPoolJoin).interfaceId
        );
        address[] memory tokens = IVaultPoolInfo(vault).getPoolTokens(pool);
        _checkAllowanceAndSetInf(tokens, amounts, vault);
        amounts = _transferTokensFromUser(tokens, msg.sender, amounts);
        return IFullPoolJoin(vault).joinPool(pool, amounts, minLPAmount, msg.sender, deadline);
    }

    function calculateFullJoin(
        address vault,
        address pool,
        uint256[] memory amounts
    )
        external
        view
        returns (uint256)
    {
        _checkContractInterface(
            vault, 
            type(IFullPoolJoin).interfaceId
        );
        return IFullPoolJoin(vault).calculateJoinPool(pool, amounts);
    }

    function partialJoin(
        address vault,
        address pool,
        address[] memory tokens,
        uint256[] memory amounts,
        uint256 minLPAmount,
        uint64 deadline
    ) 
        external
        returns (uint256)
    {
        _checkContractInterface(
            vault, 
            type(IPartialPoolJoin).interfaceId
        );
        _checkAllowanceAndSetInf(tokens, amounts, vault);
        amounts = _transferTokensFromUser(tokens, msg.sender, amounts);
        return IPartialPoolJoin(vault).partialPoolJoin(pool, tokens, amounts, minLPAmount, msg.sender, deadline);
    }

    function calculatePartialJoin(
        address vault,
        address pool,
        address[] memory tokens,
        uint256[] memory amounts
    )
        external
        view
        returns (uint256)
    {
        _checkContractInterface(
            vault, 
            type(IPartialPoolJoin).interfaceId
        );
        return IPartialPoolJoin(vault).calculatePartialPoolJoin(pool, tokens, amounts);
    }

    function singleTokenJoin(
        address vault,
        address pool,
        address token,
        uint256 amount,
        uint256 minLPAmount,
        uint64 deadline
    ) 
        external
        returns (uint256)
    {
        _checkContractInterface(
            vault, 
            type(IJoinPoolSingleToken).interfaceId
        );
        _checkTokenAllowance(token, amount, vault);
        amount = _transferTokenFromUser(token, msg.sender, amount);
        return IJoinPoolSingleToken(vault).singleTokenPoolJoin(pool, token, amount, minLPAmount, msg.sender, deadline);
    }

    function calculateSingleTokenJoin(
        address vault,
        address pool,
        address token,
        uint256 amount
    )
        external
        view
        returns (uint256)
    {
        _checkContractInterface(
            vault, 
            type(IJoinPoolSingleToken).interfaceId
        );
        return IJoinPoolSingleToken(vault).calculateSingleTokenPoolJoin(pool, token, amount);
    }

    function exit(
        address vault,
        address pool,
        uint256 lpAmount,
        uint256[] memory minAmountsOut,
        uint64 deadline
    ) 
        external
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        _checkContractInterface(
            vault, 
            type(IFullPoolExit).interfaceId
        );
        _checkTokenAllowance(pool, lpAmount, vault);
        lpAmount = _transferTokenFromUser(pool, msg.sender, lpAmount);
        return IFullPoolExit(vault).exitPool(pool, lpAmount, minAmountsOut, msg.sender, deadline);
    }

    function calculateExit(
        address vault,
        address pool,
        uint256 lpAmount
    )
        external
        view    
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        _checkContractInterface(
            vault, 
            type(IFullPoolExit).interfaceId
        );
        return IFullPoolExit(vault).calculateExitPool(pool, lpAmount);
    }
    
    function partialExit(
        address vault,
        address pool,
        uint256 lpAmount,
        address[] memory tokens,
        uint256[] memory minAmountsOut,
        uint64 deadline
    ) 
        external
        returns (address[] memory tokens_, uint256[] memory amounts)
    {
        _checkContractInterface(
            vault, 
            type(IPartialPoolExit).interfaceId
        );
        _checkTokenAllowance(pool, lpAmount, vault);
        lpAmount = _transferTokenFromUser(pool, msg.sender, lpAmount);
        return IPartialPoolExit(vault).partialPoolExit(pool, lpAmount, tokens, minAmountsOut, msg.sender, deadline);
    }

    function calculatePartialExit(
        address vault,
        address pool,
        uint256 lpAmount,
        address[] memory tokens
    )
        external
        view
        returns (address[] memory tokens_, uint256[] memory amounts)
    {
        _checkContractInterface(
            vault, 
            type(IPartialPoolExit).interfaceId
        );
        return IPartialPoolExit(vault).calculatePartialPoolExit(pool, lpAmount, tokens);
    }

    function singleTokenExit(
        address vault,
        address pool,
        uint256 lpAmount,
        address token,
        uint256 minAmountOut,
        uint64 deadline
    ) 
        external
        returns (uint256 receivedAmount)
    {
        _checkContractInterface(
            vault, 
            type(IExitPoolSingleToken).interfaceId
        );
        _checkTokenAllowance(pool, lpAmount, vault);
        lpAmount = _transferTokenFromUser(pool, msg.sender, lpAmount);
        return IExitPoolSingleToken(vault).exitPoolSingleToken(pool, lpAmount, token, minAmountOut, msg.sender, deadline);
    }

    function calculateSingleTokenExit(
        address vault,
        address pool,
        uint256 lpAmount,
        address token
    )
        external
        view
        returns (uint256)
    {
        _checkContractInterface(
            vault, 
            type(IExitPoolSingleToken).interfaceId
        );
        return IExitPoolSingleToken(vault).calculateExitPoolSingleToken(pool, lpAmount, token);
    }

    function getPoolBalancesAndTokens(
        address vault,
        address pool
    )
        external
        view
        returns (address[] memory tokens, uint256[] memory balances)
    {
        _checkContractInterface(
            vault, 
            type(IExternalBalanceManager).interfaceId
        );
        _checkContractInterface(
            vault, 
            type(IVaultPoolInfo).interfaceId
        );

        balances = IExternalBalanceManager(vault).getPoolBalances(pool);
        tokens = IVaultPoolInfo(vault).getPoolTokens(pool);
    }
}