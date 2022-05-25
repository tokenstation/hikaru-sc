// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.6;

import { SingleManager } from "../utils/SingleManager.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../utils/libraries/SafeERC20.sol";

interface IFeeReceiver {
    function withdrawFeesTo(IERC20[] memory tokens, address[] memory to, uint256[] memory amounts) external;
}

// TODO: add dao? fee receiver or additional functional (i'm not sure if it's needed)

contract FeeReceiver is SingleManager, IFeeReceiver {

    using SafeERC20 for IERC20;
        
    constructor ()
        SingleManager(msg.sender)
    {

    }

    function withdrawFeesTo(
        IERC20[] memory tokens, 
        address[] memory to,
        uint256[] memory amounts
    )
        external
        override
        onlyManager
    {
        // TODO: add array length checks as separate library for contracts
        require(
            tokens.length == to.length &&
            to.length == amounts.length,
            "Array length mismatch"
        );
        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            if (address(tokens[tokenId]) == address(0)) {
                payable(to[tokenId]).transfer(amounts[tokenId]);
            } else {
                tokens[tokenId].safeTransfer(to[tokenId], amounts[tokenId]);
            }
        }
    }
}