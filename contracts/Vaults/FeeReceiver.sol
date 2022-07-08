// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { Manageable } from "../utils/Manageable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../utils/libraries/SafeERC20.sol";
import { ArrayUtils } from "../utils/libraries/ArrayUtils.sol";
import "../utils/Errors/ErrorLib.sol";

interface IFeeReceiver {
    /**
     * @notice Withdraw collected fees
     * @param tokens Token addresses to withdraw
     * @param to Who will receive tokens
     * @param amounts Amount of tokens to withdraw
     */
    function withdrawFeesTo(IERC20[] memory tokens, address[] memory to, uint256[] memory amounts) external;
}

contract FeeReceiver is Manageable, IFeeReceiver {

    using SafeERC20 for IERC20;
    using ArrayUtils for IERC20[];

    address constant internal ZERO_ADDRESS = address(0);
        
    constructor (
        address manager_
    )
        Manageable(manager_)
    {

    }

    /**
     * @inheritdoc IFeeReceiver
     */
    function withdrawFeesTo(
        IERC20[] memory tokens, 
        address[] memory to,
        uint256[] memory amounts
    )
        external
        override
        onlyManager
    {
        _require(
            ArrayUtils.checkArrayLength(tokens, to),
            Errors.ARRAY_LENGTH_MISMATCH
        );
        _require(
            ArrayUtils.checkArrayLength(tokens, amounts),
            Errors.ARRAY_LENGTH_MISMATCH
        );
        
        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            if (address(tokens[tokenId]) == ZERO_ADDRESS) {
                payable(to[tokenId]).transfer(amounts[tokenId]);
            } else {
                tokens[tokenId].safeTransfer(to[tokenId], amounts[tokenId]);
            }
        }
    }
}