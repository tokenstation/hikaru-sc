// SPDX-License-Identifier: GPL-3.0-or-later
// @title Router for default interfaces defined in v0.6 for vaults
// @author tokenstation.dev

pragma solidity 0.8.6;

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../Vaults/interfaces/IVaultPoolInfo.sol";
import "../Vaults/interfaces/IOperations.sol";

contract DefaultRouter {

    uint256 constant MAX_UINT256 = type(uint256).max;

    function _checkContractInterface(
        address vault,
        bytes4 interfaceId
    ) 
        internal
        view
    {
        require(
            IERC165(vault).supportsInterface(interfaceId),
            "Provided vault does not support required interface"
        );
    }

    function _checkTokenAllowance(
        address tokenAddress,
        uint256 amount,
        address vault
    )
        internal
    {
        IERC20 token = IERC20(tokenAddress);
        if (
            token.allowance(address(this), vault) < amount
        ) {
            token.approve(vault, amount);
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

    function _createArraysForTokenAndAmount(
        address token,
        uint256 amount
    )
        internal
        pure
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        tokens = new address[](1); tokens[0] = token;
        amounts = new uint256[](1); amounts[0] = amount;
    }

    function sellTokens(
        address vault,
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint64 deadline
    ) 
        external
        returns (uint256)
    {
        _checkContractInterface(
            vault, 
            type(ISellTokens).interfaceId
        );
        _checkTokenAllowance(tokenIn, amountIn, vault);
        return ISellTokens(vault).sellTokens(pool, tokenIn, tokenOut, amountIn, minAmountOut, msg.sender, deadline);
    }

    function buyTokens(
        address vault,
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountToBuy,
        uint256 maxAmountIn,
        uint64 deadline
    ) 
        external
        returns (uint256)
    {   
        _checkContractInterface(
            vault, 
            type(IBuyTokens).interfaceId
        );
        _checkTokenAllowance(tokenIn, maxAmountIn, vault);
        return IBuyTokens(vault).buyTokens(pool, tokenIn, tokenOut, amountToBuy, maxAmountIn, msg.sender, deadline);
    }

    function virtualSwap(
        address vault,
        VirtualSwapInfo[] calldata swapRoute,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver,
        uint64 deadline
    ) 
        external
        returns (uint256)
    {
        _checkContractInterface(
            vault, 
            type(IVirtualSwap).interfaceId
        );
        _checkTokenAllowance(swapRoute[0].tokenIn, amountIn, vault);
        return IVirtualSwap(vault).virtualSwap(swapRoute, amountIn, minAmountOut, receiver, deadline);
    }

    function fullJoin(
        address vault,
        address pool,
        uint256[] memory amounts,
        address receiver,
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
        return IFullPoolJoin(vault).joinPool(pool, amounts, receiver, deadline);

    }

    function partialJoin(
        address vault,
        address pool,
        address[] memory tokens,
        uint256[] memory amounts,
        address receiver,
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
        return IFullPoolJoin(vault).joinPool(pool, amounts, receiver, deadline);
    }

    function singleTokenJoin(
        address vault,
        address pool,
        address token,
        uint256 amount,
        address receiver,
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
        return IJoinPoolSingleToken(vault).singleTokenPoolJoin(pool, token, amount, receiver, deadline);
    }

    function exit(
        address vault,
        address pool,
        uint256 lpAmount,
        address receiver,
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
        return IFullPoolExit(vault).exitPool(pool, lpAmount, receiver, deadline);
    }
    
    function partialExit(
        address vault,
        address pool,
        uint256 lpAmount,
        address[] memory tokens,
        address receiver,
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
        return IPartialPoolExit(vault).partialPoolExit(pool, lpAmount, tokens, receiver, deadline);
    }

    function singleTokenExit(
        address vault,
        address pool,
        uint256 lpAmount,
        address token,
        address receiver,
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
        return IExitPoolSingleToken(vault).exitPoolSingleToken(pool, lpAmount, token, receiver, deadline);
    }
}