// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

import { IERC20, IERC20Metadata, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { WeightedMath } from "./libraries/ConstantProductMath.sol";
import { FixedPoint } from "./utils/FixedPoint.sol";

contract WeightedPool is ERC20 {

    // TODO: Check other todo's
    // TODO: add functions to change pool parameters (swap fees)
    // TODO: hide weighted math usage + token transfers
    // TODO: add join/exit pool using one token
    // TODO: add unified interface for exchange (probably will be added to vault)
    // TODO: use same names for variables in contract
    // TODO: refactor contract
    // TODO: apply optimisations where possible and it does not obscure code
    // TODO: check difference between immutable and default variable cost
    // TODO: check real-world gas costs, must be around 100k or less (check how it may be achieved)

    event Swap(uint256 tokenIn, uint256 tokenOut, uint256 received, uint256 sent, address user);
    event Deposit(uint256 lpAmount, uint256[] received, address user);
    event Withdraw(uint256 lpAmount, uint256[] withdrawn, address user);


    using FixedPoint for uint256;

    uint256 internal constant ONE = 1e18;

    address public poolManager;

    address[] public tokens;
    uint256[] public balances;
    uint256[] public weights;
    uint256[] public multipliers;

    uint256 public swapFee;
    uint256 public depositFee;
    uint256 public immutable nTokens;

    event PoolManagerUpdate(address newPoolManager, address previousPoolManager);
    event FeesUpdate(uint256 newSwapFee, uint256 newDepositFee);

    function setNewFees(
        uint256 newSwapFee_,
        uint256 newDepositFee_
    )
        external
        onlyPoolManager(msg.sender)
    {
        swapFee = newSwapFee_;
        depositFee = newDepositFee_;
        emit FeesUpdate(newSwapFee_, newDepositFee_);
    }

    function setNewPoolManager(
        address newPoolManager_
    )
        external
        onlyPoolManager(msg.sender)
    {
        emit PoolManagerUpdate(newPoolManager_, poolManager);
        poolManager = newPoolManager_;
    }

    constructor(
        address poolManager_,
        address[] memory tokens_,
        uint256[] memory weights_,
        uint256 swapFee_,
        uint256 depositFee_,
        string memory name,
        string memory symbol
    ) 
        ERC20(name, symbol)
    {
        // TODO: check that there is no zero-address tokens
        require(
            tokens_.length == weights_.length,
            "Array length mismatch"
        );
        uint256 tokenAmount = tokens_.length;
        uint256 weightSum = 0;
        for(uint256 tokenId = 0; tokenId < tokenAmount; tokenId++) {
            weightSum += weights_[tokenId];
        }
        require(
            weightSum == ONE,
            "Weight sum is not equal to 1e18 (ONE)"
        );
        multipliers = new uint256[](tokens_.length);
        for (uint256 tokenId = 0; tokenId < tokenAmount; tokenId++) {
            multipliers[tokenId] = 10 ** (18 - IERC20Metadata(tokens_[tokenId]).decimals());
        }

        poolManager = poolManager_;
        nTokens = tokenAmount;
        tokens = tokens_;
        weights = weights_;
        swapFee = swapFee_;
        depositFee = depositFee_;
    }

    function getTokenId(address tokenAddress) 
        external 
        view 
        returns (uint256 tokenId) 
    {
        for (tokenId = 0; tokenId < tokens.length; tokenId++) {
            if (tokens[tokenId] == tokenAddress) return tokenId;
        }
        require(
            false,
            "There is no token with provided token address"
        );
    }

    modifier checkDeadline(uint64 deadline) {
        require(
            block.timestamp <= deadline,
            "Cannot swap, deadline passed"
        );
        _;
    }

    modifier checkTokenIds(uint256 firstTokenId, uint256 secondTokenId) {
        require(
            firstTokenId != secondTokenId &&
            firstTokenId < tokens.length &&
            secondTokenId < tokens.length,
            "There is no token with provided token id"
        );
        _;
    }

    modifier onlyPoolManager(address user) {
        require(
            msg.sender == user,
            "Only pool manager can call this function"
        );
        _;
    }

    // TODO: remove function
    function normalizeBalance(
        uint256 tokenId
    )
        internal
        view
        returns (uint256 normalizedBalance)
    {
        normalizedBalance = balances[tokenId] * multipliers[tokenId];
    }


    function swap(
        uint256 tokenIn,
        uint256 tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint64 deadline
    ) 
        external
        checkDeadline(deadline)
        checkTokenIds(tokenIn, tokenOut)
        returns (uint256 amountOut)
    {
        uint256 received = _transferAndCheckBalances(
            tokens[tokenIn],
            msg.sender,
            address(this),
            amountIn,
            true
        );

        uint256 swapResult = WeightedMath._calcOutGivenIn(
            balances[tokenIn], 
            weights[tokenIn], 
            balances[tokenOut],
            weights[tokenOut], 
            received
        );

        uint256 fee = swapResult.mulDown(swapFee);
        uint256 swapResultWithoutFee = swapResult - fee;

        require(
            swapResultWithoutFee >= minAmountOut,
            "Not enough tokens received"
        );

        uint256 sent = _transferAndCheckBalances(
            tokens[tokenOut], 
            address(this), 
            msg.sender, 
            swapResultWithoutFee, 
            false
        );

        _changeBalance(tokenIn, amountIn, true);
        _changeBalance(tokenOut, swapResultWithoutFee, false);
        
        emit Swap(tokenIn, tokenOut, received, sent, msg.sender);

        return swapResult;
    }

    function swapExactOut(
        uint256 tokenIn,
        uint256 tokenOut,
        uint256 amountOut,
        uint256 amountInMax,
        uint64 deadline
    )
        external
        checkDeadline(deadline)
        checkTokenIds(tokenIn, tokenOut)
        returns (uint256 amountIn)
    {
        uint256 amountInWithoutFee = WeightedMath._calcInGivenOut(
            balances[tokenIn], 
            weights[tokenIn], 
            balances[tokenOut], 
            weights[tokenOut], 
            amountOut
        );

        amountIn = amountInWithoutFee.divDown(ONE - swapFee);
        require(
            amountIn <= amountInMax,
            "Too much tokens is used for swap"
        );

        uint256 received = _transferAndCheckBalances(
            tokens[tokenIn],
            msg.sender,
            address(this),
            amountIn,
            true
        );

        uint256 sent = _transferAndCheckBalances(
            tokens[tokenOut],
            address(this),
            msg.sender,
            amountOut,
            false
        );

        _changeBalance(tokenIn, received, true);
        _changeBalance(tokenOut, sent, false);

        emit Swap(tokenIn, tokenOut, received, sent, msg.sender);
    }

    function joinPool(
        uint256[] memory amounts_,
        uint64 deadline
    )
        external
        checkDeadline(deadline)
        returns(uint256 lpAmount)
    {
        require(
            amounts_.length == tokens.length,
            "Invalid array size"
        );
        uint256[] memory swapFees;
        (lpAmount, swapFees) = WeightedMath._calcBptOutGivenExactTokensIn(
            balances, 
            multipliers, 
            amounts_,
            totalSupply(),
            swapFee
        );

        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            _transferAndCheckBalances(
                tokens[tokenId],
                msg.sender,
                address(this),
                amounts_[tokenId],
                true
            );
            _changeBalance(tokenId, amounts_[tokenId], false);
        }

        _mint(msg.sender, lpAmount);

        emit Deposit(lpAmount, amounts_, msg.sender);
    }

    function exitPool(
        uint256 lpAmount,
        uint64 deadline
    )
        external
        checkDeadline(deadline)
        returns (uint256[] memory tokensReceived)
    {
        tokensReceived = WeightedMath._calcTokensOutGivenExactBptIn(
            balances,
            lpAmount,
            totalSupply()
        );
        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            _transferAndCheckBalances(
                tokens[tokenId],
                address(this),
                msg.sender,
                tokensReceived[tokenId],
                false
            );
            _changeBalance(tokenId, tokensReceived[tokenId], true);
        }

        emit Withdraw(lpAmount, tokensReceived, msg.sender);
    }

    /*************************************************
                      Dry run functions
     *************************************************/

    function calculateSwap(
        uint256 tokenIn,
        uint256 tokenOut,
        uint256 swapAmount,
        bool exactIn
    )
        external
        view
        returns(uint256 swapResult, uint256 fee)
    {
        if (exactIn) {
            uint256 amountOut = WeightedMath._calcOutGivenIn(
                balances[tokenIn], 
                weights[tokenIn], 
                balances[tokenOut],
                weights[tokenOut], 
                swapAmount
            );
            fee = amountOut.mulDown(swapFee);
            swapResult -= fee;
        } else {
            uint256 amountIn = WeightedMath._calcInGivenOut(
                balances[tokenIn],
                weights[tokenIn],
                balances[tokenOut],
                weights[tokenOut],
                swapAmount
            );
            swapResult = amountIn.divDown(ONE - swapFee);
            fee = swapResult - swapAmount;
        }
        
    }

    function calculateJoin(
        uint256[] calldata amountsIn
    )
        external
        view
        returns (uint256 lpAmount)
    {
        (lpAmount, ) = WeightedMath._calcBptOutGivenExactTokensIn(
            balances, 
            multipliers, 
            amountsIn,
            totalSupply(),
            swapFee
        );
    }

    function calculateExit(
        uint256 lpAmount
    )
        external
        view
        returns (uint256[] memory tokensReceived)
    {
        tokensReceived = WeightedMath._calcTokensOutGivenExactBptIn(
            balances,
            lpAmount,
            totalSupply()
        );
    }

    /*************************************************
                      Move to Utils
     *************************************************/

    function _changeBalance(
        uint256 tokenId,
        uint256 amount,
        bool positive
    ) internal {
        balances[tokenId] = positive ? balances[tokenId] + amount : balances[tokenId] - amount;
    }

    function _transferAndCheckBalances(
        address token,
        address from,
        address to,
        uint256 amount,
        bool transferFrom_
    ) 
        internal  
        returns (uint256 transferred)
    {
        if (amount == 0) return 0;

        uint256 balanceIn = IERC20(token).balanceOf(to);
        if (transferFrom_) {
            IERC20(token).transfer(to, amount);
        } else {
            IERC20(token).transferFrom(from, to, amount);
        }
        uint256 balanceOut = IERC20(token).balanceOf(to);
        transferred = balanceOut - balanceIn;
        _checkTransferResult(amount, transferred);
    }

    function _checkTransferResult(
        uint256 expected,
        uint256 transferred
    )
        internal
        pure
    {
        require(
            expected == transferred,
            "Tokens with transfer fees are not supported in this pool"
        );
    }
}   