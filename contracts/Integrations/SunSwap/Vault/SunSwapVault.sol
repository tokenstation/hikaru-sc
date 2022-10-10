// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "../../../Vaults/interfaces/IOperations.sol";
import "../../../Vaults/interfaces/IVaultPoolInfo.sol";
import "../../../Vaults/BalanceManager/interfaces/IExternalBalanceManager.sol";

import "../interfaces/ISunSwapExchange.sol";
import "../interfaces/ISunSwapFactory.sol";
import "../interfaces/ITRXWrapper.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

contract SunSwapERC165 is IERC165 {
    constructor() {}

    function supportsInterface(bytes4 interfaceId) external override pure returns (bool) {
        return 
            interfaceId == type(IERC165).interfaceId ||

            interfaceId == type(ISwap).interfaceId ||

            interfaceId == type(IFullPoolJoin).interfaceId ||
            interfaceId == type(IPartialPoolJoin).interfaceId ||
            interfaceId == type(IJoinPoolSingleToken).interfaceId ||

            interfaceId == type(IFullPoolExit).interfaceId ||
            interfaceId == type(IPartialPoolExit).interfaceId ||
            interfaceId == type(IExitPoolSingleToken).interfaceId ||

            interfaceId == type(IExternalBalanceManager).interfaceId ||
            
            interfaceId == type(IVaultPoolInfo).interfaceId;
    }
}


contract SunSwapTRXUtils {
    using Address for address payable;

    // Contract for wrapping/unwrapping TRX
    ITRXWrapper immutable public trxWrapper;


    constructor(
        ITRXWrapper trxWrapper_
    ) {
        trxWrapper = trxWrapper_;
    }

    function isWTRX(address token) internal view returns (bool) {
        return token == address(trxWrapper);
    } 

    function wrapAmount(
        uint256 amount
    ) 
        internal 
        returns (uint256)
    {
        payable(address(trxWrapper)).sendValue(amount);
        return amount;
    } 

    function unwrapAmount(
        uint256 amount
    )
        internal
        returns (uint256)
    {
        trxWrapper.withdraw(amount);
        return amount;
    }
}


abstract contract SunSwapVault is 
    SunSwapTRXUtils,
    SunSwapERC165,
    ISwap,
    IFullPoolJoin,
    IPartialPoolJoin,
    IJoinPoolSingleToken,
    IFullPoolExit,
    IPartialPoolExit,
    IExitPoolSingleToken,
    IExternalBalanceManager,
    IVaultPoolInfo
{

    constructor(
        ITRXWrapper trxWrapContract_
    )
        SunSwapTRXUtils(trxWrapContract_) 
    {}

    /**
     * @notice Checks wether there is only one swap in route
     * @param swapRoute Swaps to perform
     * @return Does swap route contains only one element
     */
    function isSingleSwap(
        SwapRoute[] calldata swapRoute
    ) 
        internal
        pure
        returns (bool)
    {
        return swapRoute.length == 1;
    }

    /**
     * @notice This function checks wether any of tokens is WTRX
     * @param swapRoute Swap to perform
     * @return If token is WTRX
     */
    function findWTRXInSwap(
        SwapRoute calldata swapRoute
    ) 
        internal
        view
        returns (bool, bool)
    {
        return (isWTRX(swapRoute.tokenIn), isWTRX(swapRoute.tokenOut));
    }

    /**
     * @notice Check amount of swaps to perform and revert if more than one detected
     * @dev Only single swap is allowed in SunSwap integration 
     *      virtual swap between tokens is handled by SunSwap system
     * @param swapRoute Swaps to perform
     */
    function requireSingleSwap(
        SwapRoute[] calldata swapRoute
    )
        internal
        pure
    {
        require(
            isSingleSwap(swapRoute),
            "Error msg"
        );
    }

    /**
     * @inheritdoc ISwap
     */
    function swap(
        SwapRoute[] calldata swapRoute,
        SwapType swapType,
        uint256 swapAmount,
        uint256 minMaxAmount,
        address receiver,
        uint64 deadline
    ) external override returns (uint256 swapResult) {

        requireSingleSwap(swapRoute);
        SwapRoute calldata _swap = swapRoute[0];

        bool wtrxFirst; bool wtrxSecond;
        (wtrxFirst, wtrxSecond) = findWTRXInSwap(_swap);

        if (wtrxFirst) {
            // TODO
        }

        if (wtrxSecond) {
            // TODO
        }

        // TODO
    }

    /**
     * @inheritdoc ISwap
     */
    function calculateSwap(
        SwapRoute[] calldata swapRoute,
        SwapType swapType,
        uint256 swapAmount
    ) external override view returns (uint256 swapResult) {
        requireSingleSwap(swapRoute);
        SwapRoute calldata _swap = swapRoute[0];

        bool wtrxFirst; bool wtrxSecond;
        (wtrxFirst, wtrxSecond) = findWTRXInSwap(_swap);

        if (wtrxFirst) {
            // TODO
        }

        if (wtrxSecond) {
            // TODO
        }

        ISunSwapExchange firstPool = ISunSwapExchange(_swap.pool);
        ISunSwapExchange secondPool = ISunSwapExchange(ISunSwapFactory(firstPool.factory()).getExchange(_swap.tokenOut));

        uint256 firstSwapAmount = swapType == SwapType.Sell ?
            0 : 0;

        swapResult = swapType == SwapType.Sell ?
            1 : 1;

        // TODO
    }
}