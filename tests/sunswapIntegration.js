/**
 * Most invalid cases are handled by Sunswap itself, here we only need to check that connector
 * is working correctly with Sunswap and unwrapped TRX
 */


const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { SignerWithAddress } = require('@nomiclabs/hardhat-ethers/signers');
const { expect } = require('chai');
const { BigNumber } = require('ethers');
const hre = require('hardhat');
const { deployRouter, deploySunSwapExchange, deploySunSwapFactory, deploySunSwapVault, deployTokenContracts, deployWTRX } = require('./helpers/deployRoutines');
const { generateEqualTokenAmounts, approveInfToAddress, getDeadline, mintTokensTo, getSwapTypeId } = require('./helpers/utils');

const oneTRX = BigNumber.from(10**6);
const inf = BigNumber.from(2).pow(256).sub(1);

/**
 * Calculate amount of tokens to provide
 * @param {BigNumber} trxToProvide 
 * @param {BigNumber} trxBalance 
 * @param {BigNumber} tokenBalance 
 * @returns {BigNumber}
 */
function calculateTokenAmountForProviding(
    trxToProvide,
    trxBalance,
    tokenBalance
) {
    return trxToProvide.mul(tokenBalance).div(trxBalance).add(1);
}

async function createDefaultSunswapSystem() {
    /**
     * @type {import('./helpers/deployRoutines').TokenConfig[]}
     */
    const tokenParameters = [
        {
            name: 'T1',
            symbol: 'T1',
            decimals: 12
        },
        {
            name: 'T2',
            symbol: 'T2',
            decimals: 6
        }
    ];
    const [deployer, operator] = await hre.ethers.getSigners();
    const sunswapFactory = await deploySunSwapFactory(deployer);
    const wtrx = await deployWTRX(deployer);
    const tokens = (await deployTokenContracts(tokenParameters, deployer)).tokens;
    const exchanges = [];
    for (let id = 0; id < tokens.length; id++) {
        exchanges.push(
            await deploySunSwapExchange(
                sunswapFactory,
                tokens[id],
                deployer
            )
        )
    }

    const router = await deployRouter(deployer);
    const sunswapVault = await deploySunSwapVault(wtrx, deployer);
    return {
        deployer,
        operator,
        sunswapFactory,
        wtrx,
        tokens,
        exchanges,
        sunswapVault,
        router
    }
}

describe('Test Sunswap integration -> join pool', async function() {
    /**@type {SignerWithAddress} */
    let operator;
    /**@type {import('../typechain').ERC20[]} */
    let tokens;
    /**@type {import('../typechain').SunSwapVault} */
    let sunswapVault;
    /**@type {import('../typechain').SunswapExchange[]} */
    let exchanges;
    /**@type {import('../typechain').WTRX} */
    let wtrx;

    it ('Initialize system', async function() {
        const info = await loadFixture(createDefaultSunswapSystem);
        operator = info.operator;
        tokens = info.tokens;
        sunswapVault = info.sunswapVault;
        exchanges = info.exchanges;
        wtrx = info.wtrx;
    })

    it ('Test providing tokens to empty pools', async function() {
        const tokenAmount = BigNumber.from(1e4);
        const tokenAmounts = await generateEqualTokenAmounts(tokenAmount, tokens, operator.address);
        // Amount of trx used
        const trxToDeposit = oneTRX.mul(100);
        await wtrx.connect(operator).deposit({value: trxToDeposit});

        // Providing to empty pool
        const provideToFirstPool = [
            trxToDeposit,
            tokenAmounts[0].div(2)
        ];

        // Approve tokens and wtrx to sunswapVault
        await approveInfToAddress(tokens, sunswapVault.address, operator);
        wtrx.connect(operator)['approve(address,uint256)'](sunswapVault.address, inf);
        
        let expectedLPAmount = await sunswapVault.calculateJoinPool(
            exchanges[0].address,
            provideToFirstPool
        );

        const firstTx = await sunswapVault.connect(operator).joinPool(
            exchanges[0].address,
            provideToFirstPool,
            expectedLPAmount,
            operator.address,
            getDeadline()
        )

        // Testing events and token movement
        await expect(
            firstTx
        ).to.changeTokenBalances( // Checking token balances
            tokens[0],
            [operator.address, exchanges[0].address, sunswapVault.address],
            [-provideToFirstPool[1], provideToFirstPool[1], 0]
        ).and.to.changeTokenBalances( // Checking wtrx balance, must change only for user
            wtrx,
            [operator.address, exchanges[0].address, sunswapVault.address],
            [-provideToFirstPool[0], 0, 0]
        ).and.to.changeTokenBalances( // Checking LP token balance, must change only for user
            exchanges[0],
            [operator.address, sunswapVault.address],
            [expectedLPAmount, 0]
        ).and.to.changeEtherBalances( // Checking ether balance, must change only for exchange
            [sunswapVault.address, exchanges[0].address],
            [0, provideToFirstPool[0]]
        ).and.to.emit(
            exchanges[0],
            'AddLiquidity'
        ).withArgs(
            sunswapVault.address, provideToFirstPool[0], provideToFirstPool[1]
        ).and.to.emit(
            sunswapVault,
            'Deposit'
        ).withArgs(
            exchanges[0].address, expectedLPAmount, provideToFirstPool, operator.address
        );

        const provideToSecondPool = [
            trxToDeposit,
            tokenAmounts[1].div(2)
        ];
        await wtrx.connect(operator).deposit({value: trxToDeposit});

        expectedLPAmount = await sunswapVault.calculateJoinPool(exchanges[1].address, provideToSecondPool);

        const secondTx = await sunswapVault.connect(operator).joinPool(
            exchanges[1].address,
            provideToSecondPool,
            expectedLPAmount,
            operator.address,
            getDeadline()
        );

        await expect(
            secondTx
        ).to.changeTokenBalances( // Checking token balances
            tokens[1],
            [operator.address, exchanges[1].address, sunswapVault.address],
            [-provideToSecondPool[1], provideToSecondPool[1], 0]
        ).and.to.changeTokenBalances( // Checking wtrx balance, must change only for user
            wtrx,
            [operator.address, exchanges[1].address, sunswapVault.address],
            [-provideToSecondPool[0], 0, 0]
        ).and.to.changeTokenBalances( // Checking LP token balance, must change only for user
            exchanges[0],
            [operator.address, sunswapVault.address],
            [expectedLPAmount, 0]
        ).and.to.changeEtherBalances( // Checking ether balance, must change only for exchange
            [sunswapVault.address, exchanges[1].address],
            [0, provideToSecondPool[0]]
        ).and.to.emit(
            exchanges[1],
            'AddLiquidity'
        ).withArgs(
            sunswapVault.address, provideToSecondPool[0], provideToSecondPool[1]
        ).and.to.emit(
            sunswapVault,
            'Deposit'
        ).withArgs(
            exchanges[1].address, expectedLPAmount, provideToSecondPool, operator.address
        );
    })

    it ('Providing tokens to non-empty pools', async function() {
        // Checking the case when user provides more tokens than required
        const trxToDeposit = oneTRX.mul(100);
        const firstPoolTRXBalance = await hre.ethers.provider.getBalance(exchanges[0].address);
        const firstPoolTokenBalance = await tokens[0].balanceOf(exchanges[0].address);
        const firstPoolTokenAmount = calculateTokenAmountForProviding(trxToDeposit, firstPoolTRXBalance, firstPoolTokenBalance)

        const provideToFirstPool = [
            trxToDeposit,
            firstPoolTokenAmount + 1000
        ]

        await mintTokensTo(tokens[0], provideToFirstPool[1], operator.address);
        await wtrx.connect(operator).deposit({value: provideToFirstPool[0]});

        let expectedLPAmount = await sunswapVault.calculateJoinPool(exchanges[0].address, provideToFirstPool);

        const tx = await sunswapVault.connect(operator).joinPool(
            exchanges[0].address,
            provideToFirstPool,
            expectedLPAmount,
            operator.address,
            getDeadline()
        );
        
        await expect(
            tx
        ).to.changeTokenBalances(
            tokens[0],
            [operator.address, exchanges[0].address, sunswapVault.address],
            [-firstPoolTokenAmount, firstPoolTokenAmount, 0]
        ).and.to.changeTokenBalances(
            exchanges[0],
            [operator.address, sunswapVault.address],
            [expectedLPAmount, 0]
        ).and.to.changeTokenBalances(
            wtrx,
            [operator.address, exchanges[0].address, sunswapVault.address],
            [-provideToFirstPool[0], 0, 0]
        ).and.to.changeEtherBalances(
            [sunswapVault.address, exchanges[0].address],
            [0, provideToFirstPool[0]]
        ).and.to.emit(
            exchanges[0],
            'AddLiquidity'
        ).withArgs(
            sunswapVault.address, trxToDeposit, firstPoolTokenAmount
        ).and.to.emit(
            sunswapVault,
            'Deposit'
        ).withArgs(
            exchanges[0].address, expectedLPAmount, [trxToDeposit, firstPoolTokenAmount], operator.address
        );
    })
})

describe('Test sunswap integration -> swap in pools', async function() {
    /**@type {SignerWithAddress} */
    let operator;
    /**@type {import('../typechain').ERC20[]} */
    let tokens;
    /**@type {import('../typechain').SunSwapVault} */
    let sunswapVault;
    /**@type {import('../typechain').SunswapExchange[]} */
    let exchanges;
    /**@type {import('../typechain').WTRX} */
    let wtrx;
    /**@type {import('../typechain').SunswapFactory} */
    let sunswapFactory;

    it ('Initialize system', async function() {
        const info = await loadFixture(createDefaultSunswapSystem);
        operator = info.operator;
        tokens = info.tokens;
        sunswapVault = info.sunswapVault;
        exchanges = info.exchanges;
        sunswapFactory = info.sunswapFactory;
        wtrx = info.wtrx;
    })

    it ('Provide tokens to the pools', async function() {
        const tokensToProvide = 1000;
        const tokenAmounts = await generateEqualTokenAmounts(tokensToProvide, tokens, operator.address);
        const trxToDeposit = oneTRX.mul(100);

        const provideToFirstPool = [trxToDeposit, tokenAmounts[0]];
        const provideToSecondPool = [trxToDeposit, tokenAmounts[1]];

        await approveInfToAddress(tokens, sunswapVault.address, operator);
        await wtrx.connect(operator)['approve(address,uint256)'](sunswapVault.address, inf);
        await wtrx.connect(operator).deposit({value: trxToDeposit.mul(2)});

        await sunswapVault.connect(operator).joinPool(
            exchanges[0].address,
            provideToFirstPool,
            1,
            operator.address,
            getDeadline()
        );

        await sunswapVault.connect(operator).joinPool(
            exchanges[1].address,
            provideToSecondPool,
            1,
            operator.address,
            getDeadline()
        );
    })

    it ('Swap: token1 -> wtrx (Sell)', async function() {
        const amountToSell = (await generateEqualTokenAmounts(10, [tokens[0]], operator.address))[0];
        const trxToReceive = await sunswapVault.calculateSwap(
            [{
                pool: exchanges[0].address,
                tokenIn: tokens[0].address,
                tokenOut: wtrx.address
            }],
            getSwapTypeId('Sell'),
            amountToSell
        );

        const tx = await sunswapVault.connect(operator).swap(
            [{
                pool: exchanges[0].address,
                tokenIn: tokens[0].address,
                tokenOut: wtrx.address
            }],
            getSwapTypeId('Sell'),
            amountToSell,
            trxToReceive,
            operator.address,
            getDeadline()
        );

        await expect(
            tx
        ).to.changeTokenBalances(
            tokens[0],
            [operator.address, sunswapVault.address, exchanges[0].address],
            [-amountToSell, 0, amountToSell]
        ).and.to.changeTokenBalances(
            wtrx,
            [operator.address, sunswapVault.address, exchanges[0].address],
            [trxToReceive, 0, 0]
        ).and.to.changeEtherBalances(
            [sunswapVault.address, exchanges[0].address],
            [0, -trxToReceive]
        ).and.to.emit(
            exchanges[0],
            'TrxPurchase'
        ).withArgs(
            sunswapVault.address, amountToSell, trxToReceive
        ).and.to.emit(
            sunswapVault,
            'Swap'
        ).withArgs(
            exchanges[0].address,
            tokens[0].address,
            wtrx.address,
            amountToSell,
            trxToReceive,
            operator.address
        );
    })

    it ('Swap: token1 -> wtrx (Buy)', async function() {
        const trxToBuy = oneTRX.mul(10);
        const tokensToUse = await sunswapVault.calculateSwap(
            [{
                pool: exchanges[0].address,
                tokenIn: tokens[0].address,
                tokenOut: wtrx.address
            }],
            getSwapTypeId('Buy'),
            trxToBuy
        );

        await mintTokensTo(tokens[0], tokensToUse, operator.address);
        const tx = await sunswapVault.connect(operator).swap(
            [{
                pool: exchanges[0].address,
                tokenIn: tokens[0].address,
                tokenOut: wtrx.address
            }],
            getSwapTypeId('Buy'),
            trxToBuy,
            tokensToUse,
            operator.address,
            getDeadline()
        );

        await expect(
            tx
        ).to.changeTokenBalances(
            tokens[0],
            [operator.address, sunswapVault.address, exchanges[0].address],
            [-tokensToUse, 0, tokensToUse]
        ).and.to.changeTokenBalances(
            wtrx,
            [operator.address, sunswapVault.address, exchanges[0].address],
            [trxToBuy, 0, 0]
        ).and.to.changeEtherBalances(
            [sunswapVault.address, exchanges[0].address],
            [0, -trxToBuy]
        ).and.to.emit(
            exchanges[0],
            'TrxPurchase'
        ).withArgs(
            sunswapVault.address, tokensToUse, trxToBuy
        ).and.to.emit(
            sunswapVault,
            'Swap'
        ).withArgs(
            exchanges[0].address,
            tokens[0].address,
            wtrx.address,
            tokensToUse,
            trxToBuy,
            operator.address
        );
    })

    it ('Swap: wtrx -> token1 (Sell)', async function() {
        const trxToSell = oneTRX.mul(10);
        const tokensToReceive = await sunswapVault.calculateSwap(
            [{
                pool: exchanges[0].address,
                tokenIn: wtrx.address,
                tokenOut: tokens[0].address
            }],
            getSwapTypeId('Sell'),
            trxToSell
        );

        await wtrx.connect(operator).deposit({value: trxToSell});
        const tx = await sunswapVault.connect(operator).swap(
            [{
                pool: exchanges[0].address,
                tokenIn: wtrx.address,
                tokenOut: tokens[0].address
            }],
            getSwapTypeId('Sell'),
            trxToSell,
            tokensToReceive,
            operator.address,
            getDeadline()
        );

        expect(
            tx
        ).to.changeTokenBalances(
            tokens[0],
            [operator.address, sunswapVault.address, exchanges[0].address],
            [tokensToReceive, 0, -tokensToReceive]
        ).and.to.changeTokenBalances(
            wtrx,
            [operator.address, sunswapVault.address, exchanges[0].address],
            [-trxToSell, 0, 0]
        ).and.to.changeEtherBalances(
            [sunswapVault.address, exchanges[0].address],
            [0, trxToSell]
        ).and.to.emit(
            exchanges[0],
            'TokenPurchase'
        ).withArgs(
            sunswapVault.address, trxToSell, tokensToReceive
        ).and.to.emit(
            sunswapVault,
            'Swap'
        ).withArgs(
            exchanges[0].address,
            wtrx.address,
            tokens[0].address,
            trxToSell,
            tokensToReceive,
            operator.address
        );
    })

    it ('Swap: wtrx -> token1 (Buy)', async function() {
        const tokensToBuy = (await generateEqualTokenAmounts(10, [tokens[0]]))[0];
        const trxToUse = await sunswapVault.calculateSwap(
            [{
                pool: exchanges[0].address,
                tokenIn: wtrx.address,
                tokenOut: tokens[0].address
            }],
            getSwapTypeId('Buy'),
            tokensToBuy
        );

        await wtrx.connect(operator).deposit({value: trxToUse});
        const tx = await sunswapVault.connect(operator).swap(
            [{
                pool: exchanges[0].address,
                tokenIn: wtrx.address,
                tokenOut: tokens[0].address
            }],
            getSwapTypeId('Buy'),
            tokensToBuy,
            trxToUse,
            operator.address,
            getDeadline()
        );

        expect(
            tx
        ).to.changeTokenBalances(
            tokens[0],
            [operator.address, sunswapVault.address, exchanges[0].address],
            [tokensToBuy, 0, -tokensToBuy]
        ).and.to.changeTokenBalances(
            wtrx,
            [operator.address, sunswapVault.address, exchanges[0].address],
            [-trxToUse, 0, 0]
        ).and.to.changeEtherBalances(
            [sunswapVault.address, exchanges[0].address],
            [0, trxToUse]
        ).and.to.emit(
            exchanges[0],
            'TokenPurchase'
        ).withArgs(
            sunswapVault.address, trxToUse, tokensToBuy
        ).and.to.emit(
            sunswapVault,
            'Swap'
        ).withArgs(
            exchanges[0].address,
            wtrx.address,
            tokens[0].address,
            trxToUse,
            tokensToBuy,
            operator.address
        );
    })

    it ('Swap: token1 -> token2 (Sell)', async function() {
        const tokensToUse = (await generateEqualTokenAmounts(10, [tokens[0]], operator.address))[0];
        const tokensToReceive = await sunswapVault.calculateSwap(
            [{
                pool: exchanges[0].address,
                tokenIn: tokens[0].address,
                tokenOut: tokens[1].address
            }],
            getSwapTypeId('Sell'),
            tokensToUse
        );

        const tx = await sunswapVault.connect(operator).swap(
            [{
                pool: exchanges[0].address,
                tokenIn: tokens[0].address,
                tokenOut: tokens[1].address
            }],
            getSwapTypeId('Sell'),
            tokensToUse,
            tokensToReceive,
            operator.address,
            getDeadline()
        );

        expect(
            tx
        ).to.changeTokenBalances(
            tokens[0],
            [operator.address, sunswapVault.address, exchanges[0].address],
            [-tokensToUse, 0, tokensToUse]
        ).and.to.changeTokenBalances(
            wtrx,
            [operator.address, sunswapVault.address, exchanges[0].address, exchanges[1].address],
            [0, 0, 0, 0]
        ).and.to.changeTokenBalances(
            tokens[1],
            [operator.address, sunswapVault.address, exchanges[1].address],
            [tokensToReceive, 0, -tokensToReceive]
        ).and.to.changeEtherBalance(
            sunswapVault.address,
            0
        ).and.to.emit(
            exchanges[0],
            'TokenToToken'
        ).withArgs(
            sunswapVault.address, exchanges[0].address, exchanges[1].address, tokensToUse, tokensToReceive
        ).and.to.emit(
            sunswapVault,
            'Swap'
        ).withArgs(
            exchanges[0].address,
            tokens[0].address,
            tokens[1].address,
            tokensToUse,
            tokensToReceive,
            operator.address
        );
    })

    it ('Swap: token1 -> token2 (Buy)', async function() {
        const tokensToBuy = (await generateEqualTokenAmounts(10, [tokens[1]]))[0];
        const tokensToUse = await sunswapVault.calculateSwap(
            [{
                pool: exchanges[0].address,
                tokenIn: tokens[0].address,
                tokenOut: tokens[1].address
            }],
            getSwapTypeId('Buy'),
            tokensToBuy
        );

        await mintTokensTo(tokens[1], tokensToUse, operator.address);
        const tx = await sunswapVault.connect(operator).swap(
            [{
                pool: exchanges[0].address,
                tokenIn: tokens[0].address,
                tokenOut: tokens[1].address
            }],
            getSwapTypeId('Buy'),
            tokensToBuy,
            tokensToUse,
            operator.address,
            getDeadline()
        );

        expect(
            tx
        ).to.changeTokenBalances(
            tokens[0],
            [operator.address, sunswapVault.address, exchanges[0].address],
            [-tokensToUse, 0, tokensToUse]
        ).and.to.changeTokenBalances(
            wtrx,
            [operator.address, sunswapVault.address, exchanges[0].address, exchanges[1].address],
            [0, 0, 0, 0]
        ).and.to.changeTokenBalances(
            tokens[1],
            [operator.address, sunswapVault.address, exchanges[1].address],
            [tokensToBuy, 0, -tokensToBuy]
        ).and.to.changeEtherBalance(
            sunswapVault.address,
            0
        ).and.to.emit(
            exchanges[0],
            'TokenToToken'
        ).withArgs(
            sunswapVault.address, exchanges[0].address, exchanges[1].address, tokensToUse, tokensToBuy
        ).and.to.emit(
            sunswapVault,
            'Swap'
        ).withArgs(
            exchanges[0].address,
            tokens[0].address,
            tokens[1].address,
            tokensToUse,
            tokensToBuy,
            operator.address
        );
    })
})

describe('Test sunswap integration -> exit from pool', async function() {
    /**@type {SignerWithAddress} */
    let operator;
    /**@type {import('../typechain').ERC20[]} */
    let tokens;
    /**@type {import('../typechain').SunSwapVault} */
    let sunswapVault;
    /**@type {import('../typechain').SunswapExchange[]} */
    let exchanges;
    /**@type {import('../typechain').WTRX} */
    let wtrx;
    /**@type {import('../typechain').SunswapFactory} */
    let sunswapFactory;

    it ('Initialize system', async function() {
        const info = await loadFixture(createDefaultSunswapSystem);
        operator = info.operator;
        tokens = info.tokens;
        sunswapVault = info.sunswapVault;
        exchanges = info.exchanges;
        sunswapFactory = info.sunswapFactory;
        wtrx = info.wtrx;
    })

    it ('Provide tokens to the system', async function() {
        const trxToProvide = oneTRX.mul(100);
        const tokensToProvide = (await generateEqualTokenAmounts(100, [tokens[0]], operator.address))[0];
        
        await wtrx.connect(operator).deposit({value: trxToProvide});
        await wtrx.connect(operator)['approve(address,uint256)'](sunswapVault.address, inf);
        await approveInfToAddress([tokens[0]], sunswapVault.address, operator);

        const lpAmount = await sunswapVault.calculateJoinPool(exchanges[0].address, [trxToProvide, tokensToProvide]);

        await sunswapVault.connect(operator).joinPool(
            exchanges[0].address,
            [trxToProvide, tokensToProvide],
            lpAmount,
            operator.address,
            getDeadline()
        );
    })

    it ('Exit pool', async function() {
        const lpAmount = (await exchanges[0].balanceOf(operator.address));

        const expectedAmountsOut = (await sunswapVault.calculateExitPool(
            exchanges[0].address,
            lpAmount
        )).amounts;

        await approveInfToAddress([exchanges[0]], sunswapVault.address, operator);

        const tx = await sunswapVault.connect(operator).exitPool(
            exchanges[0].address,
            lpAmount,
            expectedAmountsOut,
            operator.address,
            getDeadline()
        );

        await expect(
            tx
        ).to.changeTokenBalances(
            tokens[0],
            [operator.address, sunswapVault.address, exchanges[0].address],
            [expectedAmountsOut[1], 0, -expectedAmountsOut[1]]
        ).and.to.changeTokenBalances(
            wtrx,
            [operator.address, sunswapVault.address, exchanges[0].address],
            [expectedAmountsOut[0], 0, 0]
        ).and.to.changeEtherBalances(
            [sunswapVault, exchanges[0].address],
            [0, -expectedAmountsOut[0]]
        ).and.to.emit(
            exchanges[0],
            'RemoveLiquidity'
        ).withArgs(
            sunswapVault.address, expectedAmountsOut[0], expectedAmountsOut[1]
        ).and.to.emit(
            sunswapVault,
            'Withdraw'
        ).withArgs(
            exchanges[0].address, lpAmount, expectedAmountsOut, operator.address
        );
    })
})