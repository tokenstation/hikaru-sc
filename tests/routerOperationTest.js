const { deploySystemWithDefaultParameters } = require("./settersTest");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { generateEqualTokenAmounts, getDeadline, approveInfToAddress, getSwapTypeId } = require("./helpers/utils");
const { expect } = require("chai");

/** @type {import("./settersTest").DefaultSystemInfo} */
let info;

describe('Router -> join functions', function() {
    it('Load default state and set infinite approve', async function() {
        info = await loadFixture(initializePool);
        const {tokens, owner, defaultRouter} = info;
        await approveInfToAddress(tokens, defaultRouter.address, owner);
    })

    it ('Router -> fullJoin', async function() {
        const {
            defaultRouter,
            weightedPool,
            weightedVault,
            tokens,
            owner
        } = info;

        const tokenAmounts = await generateEqualTokenAmounts(1e6, tokens, owner.address);
        const expectedLpAmount = await defaultRouter.calculateFullJoin(
            weightedVault.address, 
            weightedPool.address, 
            tokenAmounts
        );
        const initialTS = await weightedPool.totalSupply();

        await expect(
            defaultRouter.connect(owner).fullJoin(
                weightedVault.address,
                weightedPool.address,
                tokenAmounts,
                expectedLpAmount,
                getDeadline()
            )
        ).to.emit(
            weightedVault, 'Deposit'
        ).withArgs(
            weightedPool.address,
            expectedLpAmount,
            tokenAmounts,
            owner.address
        ).and.changeTokenBalances(
            tokens[0],
            [weightedVault.address, owner.address],
            [tokenAmounts[0], -tokenAmounts[0]]
        ).and.changeTokenBalances(
            tokens[1],
            [weightedVault.address, owner.address],
            [tokenAmounts[1], -tokenAmounts[1]]
        ).and.changeTokenBalances(
            tokens[2],
            [weightedVault.address, owner.address],
            [tokenAmounts[2], -tokenAmounts[2]]
        ).and.changeTokenBalances(
            tokens[3],
            [weightedVault.address, owner.address],
            [tokenAmounts[3], -tokenAmounts[3]]
        ).and.changeTokenBalance(
            weightedPool,
            owner.address,
            expectedLpAmount
        )

        const finalTS = await weightedPool.totalSupply();
        expect(
            finalTS
        ).to.be.eq(initialTS.add(expectedLpAmount), 'Invalid amount of LP tokens minted');
    })

    it ('Router -> partialJoin', async function() {
        const {
            weightedPool,
            weightedVault,
            defaultRouter,
            tokens,
            owner
        } = info;

        const tokenAmounts = await generateEqualTokenAmounts(1e5, tokens, owner.address, [1, 3]);
        const joinTokens = [tokens[0], tokens[2]];

        const expectedLpAmount = await defaultRouter.calculatePartialJoin(
            weightedVault.address,
            weightedPool.address,
            joinTokens.map((val) => val.address),
            tokenAmounts
        );
        const initialTS = await weightedPool.totalSupply();

        await expect(
            defaultRouter.connect(owner).partialJoin(
                weightedVault.address,
                weightedPool.address,
                joinTokens.map((val) => val.address),
                tokenAmounts,
                expectedLpAmount,
                getDeadline()
            )
        ).to.emit(
            weightedVault, 'Deposit'
        ).withArgs(
            weightedPool.address,
            expectedLpAmount,
            [tokenAmounts[0], 0, tokenAmounts[1], 0],
            owner.address
        ).and.changeTokenBalances(
            tokens[0],
            [weightedVault.address, owner.address],
            [tokenAmounts[0], -tokenAmounts[0]]
        ).and.changeTokenBalances(
            tokens[1],
            [weightedVault.address, owner.address],
            [0, 0]
        ).and.changeTokenBalances(
            tokens[2],
            [weightedVault.address, owner.address],
            [tokenAmounts[1], -tokenAmounts[1]]
        ).and.changeTokenBalances(
            tokens[3],
            [weightedVault.address, owner.address],
            [0, 0]
        ).and.changeTokenBalance(
            weightedPool,
            owner.address,
            expectedLpAmount
        )

        const finalTS = await weightedPool.totalSupply();
        expect(
            finalTS
        ).to.be.eq(initialTS.add(expectedLpAmount), 'Invalid amount of LP tokens minted');
    })

    it ('Router -> singleTokenJoin', async function() {
        const {
            weightedPool,
            weightedVault,
            defaultRouter,
            tokens,
            owner
        } = info;

        const tokenAmount = (await generateEqualTokenAmounts(1e5, [tokens[0]], owner.address))[0];
        const tokenToJoin = tokens[0];

        const expectedLpAmount = await defaultRouter.calculateSingleTokenJoin(
            weightedVault.address,
            weightedPool.address,
            tokenToJoin.address,
            tokenAmount
        );
        const initialTS = await weightedPool.totalSupply();

        await expect(
            defaultRouter.connect(owner).singleTokenJoin(
                weightedVault.address,
                weightedPool.address,
                tokenToJoin.address,
                tokenAmount,
                expectedLpAmount,
                getDeadline()
            )
        ).to.emit(
            weightedVault, 'Deposit'
        ).withArgs(
            weightedPool.address,
            expectedLpAmount,
            [tokenAmount, 0, 0, 0],
            owner.address
        ).and.changeTokenBalances(
            tokens[0],
            [weightedVault.address, owner.address],
            [tokenAmount, -tokenAmount]
        ).and.changeTokenBalances(
            tokens[1],
            [weightedVault.address, owner.address],
            [0, 0]
        ).and.changeTokenBalances(
            tokens[2],
            [weightedVault.address, owner.address],
            [0, 0]
        ).and.changeTokenBalances(
            tokens[3],
            [weightedVault.address, owner.address],
            [0, 0]
        ).and.changeTokenBalance(
            weightedPool,
            owner.address,
            expectedLpAmount
        )

        const finalTS = await weightedPool.totalSupply();
        expect(
            finalTS
        ).to.be.eq(initialTS.add(expectedLpAmount), 'Invalid amount of LP tokens minted');
    })
})

describe('DefaultRouter -> swap functions', function() {
    it('Load default state and set infinite approve', async function() {
        info = await loadFixture(initializePool);
        const {tokens, owner, defaultRouter} = info;
        await approveInfToAddress(tokens, defaultRouter.address, owner);
    })

    it ('DefaultRouter -> swap (Sell)', async function() {
        const {
            weightedPool,
            weightedVault,
            defaultRouter,
            tokens,
            owner
        } = info;

        /** @type {import("../typechain/contracts/Vaults/interfaces/ISwap").SwapRouteStruct[]} */
        const swapRoute = [
            {pool: weightedPool.address, tokenIn: tokens[0].address, tokenOut: tokens[1].address}
        ];

        const swapAmount = (await generateEqualTokenAmounts(1000, [tokens[0]], owner.address))[0];
        const expectedTokenAmount = await defaultRouter.calculateSwap(
            weightedVault.address,
            swapRoute,
            getSwapTypeId('Sell'),
            swapAmount
        )

        await expect(
            defaultRouter.connect(owner).swap(
                weightedVault.address,
                swapRoute,
                getSwapTypeId('Sell'),
                swapAmount,
                expectedTokenAmount,
                owner.address,
                getDeadline()
            )
        ).to.emit(
            weightedVault, 'Swap'
        ).withArgs(
            weightedPool.address,
            tokens[0].address,
            tokens[1].address,
            swapAmount,
            expectedTokenAmount,
            owner.address
        ).and.changeTokenBalances(
            tokens[0],
            [weightedVault.address, owner.address],
            [swapAmount, -swapAmount]
        ).and.changeTokenBalances(
            tokens[1],
            [weightedVault.address, owner.address],
            [-expectedTokenAmount, expectedTokenAmount]
        )
    })

    it ('DefaultRouter -> swap (Buy)', async function() {
        const {
            weightedPool,
            weightedVault,
            defaultRouter,
            tokens,
            owner
        } = info;

        /** @type {import("../typechain/contracts/Vaults/interfaces/ISwap").SwapRouteStruct[]} */
        const swapRoute = [
            {pool: weightedPool.address, tokenIn: tokens[0].address, tokenOut: tokens[1].address}
        ];

        const swapAmount = (await generateEqualTokenAmounts(1000, [tokens[1]]))[0];
        const expectedTokenAmount = await defaultRouter.calculateSwap(
            weightedVault.address,
            swapRoute,
            getSwapTypeId('Buy'),
            swapAmount
        )
        await tokens[0].connect(owner).mint(owner.address, expectedTokenAmount);

        await expect(
            defaultRouter.connect(owner).swap(
                weightedVault.address,
                swapRoute,
                getSwapTypeId('Buy'),
                swapAmount,
                expectedTokenAmount,
                owner.address,
                getDeadline()
            )
        ).to.emit(
            weightedVault, 'Swap'
        ).withArgs(
            weightedPool.address,
            tokens[0].address,
            tokens[1].address,
            swapAmount,
            expectedTokenAmount,
            owner.address
        ).and.changeTokenBalances(
            tokens[0],
            [weightedVault.address, owner.address],
            [expectedTokenAmount, -expectedTokenAmount]
        ).and.changeTokenBalances(
            tokens[1],
            [weightedVault.address, owner.address],
            [-swapAmount, swapAmount]
        )
    })
})

describe('DefaultRouter -> exit functions', function() {
    it('Load default state and set infinite approve', async function() {
        info = await loadFixture(initializePool);
        const {weightedPool, owner, defaultRouter} = info;
        await approveInfToAddress([weightedPool], defaultRouter.address, owner);
    })

    it ('DefaultRouter -> exit', async function() {
        const {
            weightedPool,
            weightedVault,
            defaultRouter,
            tokens,
            owner
        } = info;

        const lpAmount = (
            await weightedPool.balanceOf(owner.address)
        ).div(100);
        const initialTS = await weightedPool.totalSupply();
        const initialLPBalance = await weightedPool.balanceOf(owner.address);
        const expectedTokenAmounts = (await defaultRouter.calculateExit(
            weightedVault.address,
            weightedPool.address,
            lpAmount
        )).amounts;

        await expect(
            defaultRouter.connect(owner).exit(
                weightedVault.address,
                weightedPool.address,
                lpAmount,
                expectedTokenAmounts,
                getDeadline()
            )
        ).to.emit(
            weightedVault, 'Withdraw'
        ).withArgs(
            weightedPool.address,
            lpAmount,
            expectedTokenAmounts,
            owner.address
        );

        const finalTS = await weightedPool.totalSupply();
        const finalLPBalance = await weightedPool.balanceOf(owner.address);

        expect(
            finalTS
        ).to.be.eq(initialTS.sub(lpAmount), 'Invalid amount of LP tokens burned');
        expect(
            finalLPBalance
        ).to.be.eq(initialLPBalance.sub(lpAmount), 'Invalid amount of LP tokens burned from user account');
    })

    it ('DefaultRouter -> partialExit', async function() {
        // This function is not implemented in weightedVault, so we expect function to fail
        const {
            weightedPool,
            weightedVault,
            defaultRouter,
            tokens,
            owner
        } = info;

        await expect(
            defaultRouter.calculatePartialExit(
                weightedVault.address,
                weightedPool.address,
                1,
                tokens.map((val) => val.address)
            )
        ).to.be.revertedWith(
            'HIKARU#500'
        );

        await expect(
            defaultRouter.connect(owner).partialExit(
                weightedVault.address,
                weightedPool.address,
                1,
                tokens.map((val) => val.address),
                tokens.map((val) => 0),
                getDeadline()
            )
        ).to.be.revertedWith(
            'HIKARU#500'
        );
    })

    it ('DefaultRouter -> singleTokenExit', async function() {
        const {
            weightedPool,
            weightedVault,
            defaultRouter,
            tokens,
            owner
        } = info;

        const exitToken = tokens[3];
        const lpAmount = (await weightedPool.balanceOf(owner.address)).div(100);
        const initialTS = await weightedPool.totalSupply();
        const initialLPBalance = await weightedPool.balanceOf(owner.address);
        const expectedAmountOut = await defaultRouter.calculateSingleTokenExit(
            weightedVault.address,
            weightedPool.address,
            lpAmount,
            exitToken.address
        );

        await expect(
            defaultRouter.connect(owner).singleTokenExit(
                weightedVault.address,
                weightedPool.address,
                lpAmount,
                exitToken.address,
                expectedAmountOut,
                getDeadline()
            )
        ).to.emit(
            weightedVault, 'Withdraw'
        );
        
        const finalTS = await weightedPool.totalSupply();
        const finalLPBalance = await weightedPool.balanceOf(owner.address);

        expect(
            finalTS
        ).to.be.eq(
            initialTS.sub(lpAmount),
            'Invalid amount of LP tokens burned'
        )
        expect(
            finalLPBalance
        ).to.be.eq(
            initialLPBalance.sub(lpAmount), 
            'Invalid amount of LP tokens burned from user account'
        );
    })
})

describe('DefaultRouter -> check getters', function() {
    it('Load default state', async function() {
        info = await loadFixture(initializePool);
    })

    it('DefaultRouter -> getPoolBalancesAndTokens', async function() {
        const {
            defaultRouter,
            weightedVault,
            weightedPool
        } = info;

        const routerInfo = await defaultRouter.getPoolBalancesAndTokens(
            weightedVault.address,
            weightedPool.address
        );

        const tokens = await weightedVault.getPoolTokens(weightedPool.address);
        const balances = await weightedVault.getPoolBalances(weightedPool.address);

        for (const [id, token] of routerInfo.tokens.entries()) {
            expect(
                token
            ).to.be.eq(tokens[id], 'Invalid token');
        }

        for (const [id, balance] of routerInfo.balances.entries()) {
            expect(
                balance
            ).to.be.eq(balances[id], 'Invalid balance');
        }
    })
})

async function initializePool() {
    const info = await loadFixture(deploySystemWithDefaultParameters);
    const {
        owner,
        weightedPool,
        weightedVault,
        tokens
    } = info;

    await approveInfToAddress(tokens, weightedVault.address, owner);
    const tokenAmounts = await generateEqualTokenAmounts(1e10, tokens, owner.address);

    await expect(
        weightedVault.connect(owner).joinPool(
            weightedPool.address,
            tokenAmounts,
            tokens.map(() => 0),
            owner.address,
            getDeadline()
        )
    ).not.to.be.reverted;

    return info;
}