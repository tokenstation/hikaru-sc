/**
 * Tests scenario:
 * 1. Deploy system
 * 2. Deploy pool
 * 3. Initialize pool
 * 4. Provide tokens to pool using all tokens / some of tokens / one token
 * 5. Swap tokens using sell / buy
 * 6. Withdraw all tokens / single token
 * 7. Deploy another pool
 * 8. Test virtual swaps for multiple pools
 */

const { takeSnapshot, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { SignerWithAddress } = require("@nomiclabs/hardhat-ethers/signers");
const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants");
const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { provide } = require("./helpers/directOperations");
const { getDeadline, generateEqualTokenAmounts, approveInfToAddress, getProtocolFees, getSwapTypeId } = require("./helpers/utils");
const { deploySystemWithDefaultParameters } = require("./settersTest");
const hre = require('hardhat');

const ONE = BigNumber.from(10).pow(18);
const LIMIT = BigNumber.from(10).pow(17).mul(3);
const INF = BigNumber.from(2).pow(256).sub(1);

const initSnapshot = {
    /** @type {import("@nomicfoundation/hardhat-network-helpers").SnapshotRestorer} */
    snapshot: {},
    /** @type {import("./settersTest").DefaultSystemInfo} */
    snapshotData: {}
};

describe('WeightedPool -> initialization', function() {
    it ('initialize with zero token amounts', async function () {
        const {
            weightedPool,
            weightedVault,
            tokens,
            owner
        } = await loadFixture(deploySystemWithDefaultParameters);
        await expect(
            weightedVault.connect(owner).joinPool(
                weightedPool.address,
                new Array(tokens.length).fill(0),
                0,
                owner.address,
                getDeadline()
            )
        ).to.be.revertedWith('HIKARU#405')
    })

    it ('Initialize with several zero token amounts', async function () {
        const {
            weightedPool,
            weightedVault,
            tokens,
            owner
        } = await loadFixture(deploySystemWithDefaultParameters);

        const amounts = await generateEqualTokenAmounts(1, tokens, owner.address);
        amounts[1] = 0;
        amounts[2] = 0;
        await approveInfToAddress(tokens, weightedVault.address, owner);

        await expect(
            weightedVault.connect(owner).joinPool(
                weightedPool.address,
                amounts,
                0,
                owner.address,
                getDeadline()
            )
        ).to.be.revertedWith('HIKARU#405')
    })

    it ('Initialize pool with invalid minLPAmount', async function () {
        const {
            weightedPool,
            weightedVault,
            tokens,
            owner
        } = await loadFixture(deploySystemWithDefaultParameters);
        const amounts = await generateEqualTokenAmounts(1, tokens, owner.address);
        await approveInfToAddress(tokens, weightedVault.address, owner);

        const expectedLpAmount = await weightedVault.calculateJoinPool(
            weightedPool.address,
            amounts
        )

        await expect(
            weightedVault.connect(owner).joinPool(
                weightedPool.address,
                amounts,
                expectedLpAmount.add(1),
                owner.address,
                getDeadline()
            )
        ).to.be.revertedWith(
            'HIKARU#413'
        )
    })

    it ('Initialize pool with specified amount of tokens', async function () {
        const fixtureInfo = await loadFixture(deploySystemWithDefaultParameters);
        const {
            weightedPool,
            weightedVault,
            tokens,
            owner
        } = fixtureInfo;

        const amounts = await generateEqualTokenAmounts(
            BigNumber.from(10).pow(9),
            tokens,
            owner.address
        );

        await approveInfToAddress(tokens, weightedVault.address, owner);

        const expectedLpAmount = await weightedVault.calculateJoinPool(
            weightedPool.address,
            amounts
        );
        
        const tx = await provide(
            weightedVault,
            weightedPool,
            tokens,
            owner,
            owner.address,
            amounts
        );

        const lpAmount = await weightedPool.balanceOf(owner.address);

        await expect(
            tx.transactionHash
        ).to.emit (
            weightedVault, 'Deposit'
        ).withArgs(
            weightedPool.address, 
            expectedLpAmount,
            amounts,
            owner.address
        ).and.emit (
            weightedPool, 'Transfer'
        ).withArgs(
            ZERO_ADDRESS,
            owner.address,
            expectedLpAmount
        )

        expect(
            lpAmount
        ).to.eq(expectedLpAmount, 'Invalid amount of LP tokens received');

        initSnapshot.snapshot = await takeSnapshot();
        initSnapshot.snapshotData = fixtureInfo;
    })
})

describe('WeightedPool -> provide tokens to pool', function() {
    it ('Load initialized state', async function () {
        await initSnapshot.snapshot.restore();
    })

    it ('WeightedPool -> joinPool (with invalid deadline)', async function () {
        const {
            weightedPool,
            weightedVault,
            tokens,
            owner
        } = initSnapshot.snapshotData;

        const amounts = await generateEqualTokenAmounts(1, tokens);
        const expectedLpAmount = await weightedVault.calculateJoinPool(weightedPool.address, amounts);

        await expect(
            weightedVault.connect(owner).joinPool(
                weightedPool.address,
                amounts,
                expectedLpAmount,
                owner.address,
                1
            )
        ).to.be.revertedWith(
            'HIKARU#505'
        )
    })

    it ('WeightedPool -> joinPool (with invalid expected LP amount)', async function () {
        const {
            weightedPool,
            weightedVault,
            tokens,
            owner
        } = initSnapshot.snapshotData;

        const amounts = await generateEqualTokenAmounts(1, tokens, owner.address);
        await approveInfToAddress(tokens, weightedVault.address, owner);
        const expectedLpAmount = await weightedVault.calculateJoinPool(
            weightedPool.address,
            amounts
        );

        await expect(
            weightedVault.connect(owner).joinPool(
                weightedPool.address,
                amounts,
                expectedLpAmount.add(1),
                owner.address,
                getDeadline()
            )
        ).to.be.revertedWith(
            'HIKARU#413'
        )
    })

    /// In this test nothing must change
    it ('WeightedPool -> joinPool (with zero token amount)', async function () {
        
        const {
            weightedPool,
            weightedVault,
            tokens,
            owner
        } = initSnapshot.snapshotData;
        
        const amounts = await generateEqualTokenAmounts(0, tokens);

        const initInfo = await getProvideInfo(weightedVault, weightedPool, tokens, owner);

        const tx = await provide(
            weightedVault,
            weightedPool,
            tokens,
            owner,
            owner.address,
            amounts
        );

        const finalInfo = await getProvideInfo(weightedVault, weightedPool, tokens, owner);

        expect(
            initInfo.poolBalances
        ).to.deep.eq(finalInfo.poolBalances, 'Pool balances changed, but must not');

        expect(
            initInfo.protocolFees
        ).to.deep.eq(finalInfo.protocolFees, 'Protocol fees changed, but must not');

        expect(
            initInfo.lpAmount
        ).to.deep.eq(finalInfo.lpAmount, `User's lp balances changed, but must not`);

        await expect(
            tx.transactionHash
        ).to.emit (
            weightedVault, 'Deposit'
        ).withArgs(
            weightedPool.address,
            0,
            amounts,
            owner.address
        )
    })

    it ('Weighted pool -> joinPool (with all tokens)', async function () {
        const {
            weightedPool,
            weightedVault,
            tokens,
            unknownUser
        } = initSnapshot.snapshotData;

        const amounts = await generateEqualTokenAmounts(1e7, tokens, unknownUser.address);
        await approveInfToAddress(tokens, weightedVault.address, unknownUser);
        
        const expectedLpAmount = await weightedVault.calculateJoinPool(weightedPool.address, amounts);
        const initInfo = await getProvideInfo(weightedVault, weightedPool, tokens, unknownUser);

        const tx = await provide(
            weightedVault,
            weightedPool,
            tokens,
            unknownUser,
            unknownUser.address,
            amounts
        );

        const finalInfo = await getProvideInfo(weightedVault, weightedPool, tokens, unknownUser);

        const balanceChange = finalInfo.poolBalances.map((val, index) => val.sub(initInfo.poolBalances[index]));
        const expectedProtocolFees = amounts.map((val, index) => val.sub(balanceChange[index]));

        expect(
            initInfo.lpAmount.add(expectedLpAmount)
        ).to.eq(finalInfo.lpAmount, 'Invalid amount of LP tokens minted to user');

        expect(
            initInfo.protocolFees.map((val, index) => val.add(expectedProtocolFees[index]))
        ).to.deep.eq(finalInfo.protocolFees, 'Invalid amount of protocol fee collected');

        // TODO: add strict check for pool balances
        for (const [id, val] of finalInfo.poolBalances.entries()) {
            expect(val).to.be.gt(initInfo.poolBalances[id], 'Unexpected pool balance change');
        }

        await expect(
            tx.transactionHash
        ).to.emit (
            weightedVault, 'Deposit'
        ).withArgs(
            weightedPool.address, 
            expectedLpAmount, 
            balanceChange, 
            unknownUser.address
        ).and.to.emit (
            weightedPool, 'Transfer'
        ).withArgs(
            ZERO_ADDRESS, unknownUser.address, expectedLpAmount
        )
    })

    it ('Weighted pool -> joinPool (some tokens)', async function () {
        const {
            weightedPool,
            weightedVault,
            tokens,
            unknownUser
        } = initSnapshot.snapshotData;

        const amounts = await generateEqualTokenAmounts(1e7, tokens, unknownUser.address);
        await approveInfToAddress(tokens, weightedVault.address, unknownUser);

        const indexes = [0, 2];
        const joinTokens = tokens.filter((val, index) => indexes.indexOf(index) >= 0 ? val : undefined);
        const joinAmounts = amounts.filter((val, index) => indexes.indexOf(index) >= 0 ? val : undefined);

        const expectedLpAmount = await weightedVault.calculatePartialPoolJoin(
            weightedPool.address,
            joinTokens.map((val) => val.address),
            joinAmounts
        )
        const initInfo = await getProvideInfo(weightedVault, weightedPool, tokens, unknownUser);

        const tx = await provide(
            weightedVault,
            weightedPool,
            joinTokens,
            unknownUser,
            unknownUser.address,
            joinAmounts
        );

        const finalInfo = await getProvideInfo(weightedVault, weightedPool, tokens, unknownUser);

        expect(
            initInfo.lpAmount.add(expectedLpAmount)
        ).to.eq(finalInfo.lpAmount, 'Invalid LP amount calculated/minted to user');

        await expect(
            tx.transactionHash
        ).to.emit (
            weightedPool, 'Transfer'
        ).withArgs(
            ZERO_ADDRESS,
            unknownUser.address,
            expectedLpAmount
        );
    })

    it ('Weighted pool -> joinPool (single token)', async function () {
        const {
            weightedPool,
            weightedVault,
            tokens,
            unknownUser
        } = initSnapshot.snapshotData;

        const amounts = await generateEqualTokenAmounts(1e7, tokens, unknownUser.address);
        await approveInfToAddress(tokens, weightedVault.address, unknownUser);

        const index = 1;
        const joinToken = tokens[index];
        const joinAmount = amounts[index];

        const expectedLpAmount = await weightedVault.calculateSingleTokenPoolJoin(
            weightedPool.address,
            joinToken.address,
            joinAmount
        )
        const initInfo = await getProvideInfo(weightedVault, weightedPool, tokens, unknownUser);

        const tx = await provide(
            weightedVault,
            weightedPool,
            [joinToken],
            unknownUser,
            unknownUser.address,
            [joinAmount]
        );

        const finalInfo = await getProvideInfo(weightedVault, weightedPool, tokens, unknownUser);

        expect(
            initInfo.lpAmount.add(expectedLpAmount)
        ).to.eq(finalInfo.lpAmount, 'Invalid LP amount calculated/minted to user');

        await expect(
            tx.transactionHash
        ).to.emit (
            weightedPool, 'Transfer'
        ).withArgs(
            ZERO_ADDRESS,
            unknownUser.address,
            expectedLpAmount
        );
    })

    /**
     * 
     * @param {import("../typechain").WeightedVault} weightedVault 
     * @param {import("../typechain").WeightedPool} weightedPool 
     * @param {import("../typechain").ERC20Mock[]} tokens 
     * @param {SignerWithAddress} user 
     */
    async function getProvideInfo(
        weightedVault, 
        weightedPool,
        tokens,
        user
    ) {
        return {
            lpAmount: await weightedPool.balanceOf(user.address),
            poolBalances: await weightedVault.getPoolBalances(weightedPool.address),
            protocolFees: await getProtocolFees(weightedVault, tokens)
        }
    }

})


describe('WeightedPool -> swap tokens in pool', function() {
    it ('Restore chain state and approve tokens', async function() {
        await initSnapshot.snapshot.restore();
        const {tokens, weightedVault, unknownUser} = initSnapshot.snapshotData;
        await approveInfToAddress(tokens, weightedVault.address, unknownUser);
    })

    it ('Try to swap in invalid pool', async function() {
        const {
            weightedVault,
            unknownUser,
            tokens
        } = initSnapshot.snapshotData;

        /**@type {import("../typechain/contracts/Router/DefaultRouter").SwapRouteStruct[]} */
        const swapRoute = [
            {pool: tokens[0].address, tokenIn: tokens[0].address, tokenOut: tokens[1].address}
        ]

        await expect(
            weightedVault.connect(unknownUser).swap(
                swapRoute,
                getSwapTypeId('Sell'),
                0,
                0,
                unknownUser.address,
                getDeadline()
            )
        ).to.be.revertedWith(
            'HIKARU#504'
        );
    })

    it ('Try to swap invalid tokens', async function() {
        const {
            weightedPool,
            weightedVault,
            unknownUser,
            tokens
        } = initSnapshot.snapshotData;

        /**@type {import("../typechain/contracts/Router/DefaultRouter").SwapRouteStruct[]} */
        const swapRoute = [
            {pool: weightedPool.address, tokenIn: weightedPool.address, tokenOut: weightedVault.address}
        ];

        await expect(
            weightedVault.connect(unknownUser).swap(
                swapRoute,
                getSwapTypeId('Sell'),
                0,
                0,
                unknownUser.address,
                getDeadline()
            )
        ).to.be.revertedWith(
            'HIKARU#404'
        );
    })

    it ('Try to swap token to itself', async function() {
        const {
            weightedPool,
            weightedVault,
            unknownUser,
            tokens
        } = initSnapshot.snapshotData;

        /**@type {import("../typechain/contracts/Router/DefaultRouter").SwapRouteStruct[]} */
        const swapRoute = [
            {pool: weightedPool.address, tokenIn: tokens[0].address, tokenOut: tokens[0].address}
        ];

        await generateEqualTokenAmounts(1, [tokens[0]], unknownUser.address);

        await expect(
            weightedVault.connect(unknownUser).swap(
                swapRoute,
                getSwapTypeId('Sell'),
                1,
                1,
                unknownUser.address,
                getDeadline()
            )
        ).to.be.revertedWith(
            'HIKARU#406'
        )
    })

    it ('Try to swap zero tokens with correct parameters', async function () {
        const {
            weightedPool,
            weightedVault,
            unknownUser,
            tokens
        } = initSnapshot.snapshotData;

        /** @type {import("../typechain/contracts/Router/DefaultRouter").SwapRouteStruct[]} */
        const swapRoute = [
            { pool: weightedPool.address, tokenIn: tokens[0].address, tokenOut: tokens[1].address }
        ];

        await expect( 
            weightedVault.connect(unknownUser).swap(
                swapRoute,
                getSwapTypeId('Sell'),
                0,
                0,
                unknownUser.address,
                getDeadline()
            )
        ).not.to.be.reverted;
    })

    it ('Try to swap with invalid deadline', async function () {
        const {
            weightedPool,
            weightedVault,
            unknownUser,
            tokens
        } = initSnapshot.snapshotData;

        /** @type {import("../typechain/contracts/Router/DefaultRouter").SwapRouteStruct[]} */
        const swapRoute = [
            { pool: weightedPool.address, tokenIn: tokens[0].address, tokenOut: tokens[1].address }
        ];

        await expect( 
            weightedVault.connect(unknownUser).swap(
                swapRoute,
                getSwapTypeId('Sell'),
                0,
                0,
                unknownUser.address,
                1
            )
        ).to.be.revertedWith(
            'HIKARU#505'
        );
    })

    it ('Try to swap more than 30% of pool balance', async function () {
        const {
            weightedPool,
            weightedVault,
            unknownUser,
            tokens
        } = initSnapshot.snapshotData;

        /** @type {import("../typechain/contracts/Router/DefaultRouter").SwapRouteStruct[]} */
        const swapRoute = [
            { pool: weightedPool.address, tokenIn: tokens[0].address, tokenOut: tokens[1].address }
        ];

        const poolBalances = await weightedVault.getPoolBalances(weightedPool.address);
        const poolSwapFee = await weightedPool.swapFee();
        // For sellLimit we use special formula: amountIn*(1 + swapFee)*limit
        // This is required because swapFee is deducted before swap and we won't be able to test swap limit
        const sellLimit = poolBalances[0].mul(ONE + poolSwapFee).mul(LIMIT).div(ONE).div(ONE);
        // For buyLimit - swap limit is checked for token out
        // Swap fees occure only in tokenIn token
        const buyLimit = poolBalances[1].mul(LIMIT).div(ONE);
        await tokens[0].connect(unknownUser).mint(unknownUser.address, sellLimit.add(1));
        await tokens[1].connect(unknownUser).mint(unknownUser.address, buyLimit.add(1));

        await expect(
            weightedVault.connect(unknownUser).swap(
                swapRoute,
                getSwapTypeId('Sell'),
                sellLimit.add(2),
                1,
                unknownUser.address,
                getDeadline()
            )
        ).to.be.revertedWith('HIKARU#409');

        await expect(
            weightedVault.connect(unknownUser).swap(
                swapRoute,
                getSwapTypeId('Buy'),
                buyLimit.add(1),
                INF,
                unknownUser.address,
                getDeadline()
            )
        ).to.be.revertedWith('HIKARU#410');
    })

    it ('Try to swap tokens with invalid minMaxAmount for sell and buy', async function () {
        const {
            weightedPool,
            weightedVault,
            unknownUser,
            tokens
        } = initSnapshot.snapshotData;

        /** @type {import("../typechain/contracts/Router/DefaultRouter").SwapRouteStruct[]} */
        const swapRoute = [
            { pool: weightedPool.address, tokenIn: tokens[0].address, tokenOut: tokens[1].address }
        ];

        const poolBalances = await weightedVault.getPoolBalances(weightedPool.address);
        const sellLimit = poolBalances[0].mul(LIMIT).div(ONE);
        const buyLimit = poolBalances[1].mul(LIMIT).div(ONE);
        await tokens[0].connect(unknownUser).mint(unknownUser.address, sellLimit);
        await tokens[1].connect(unknownUser).mint(unknownUser.address, buyLimit);

        await expect(
            weightedVault.connect(unknownUser).swap(
                swapRoute,
                getSwapTypeId('Sell'),
                sellLimit,
                INF,
                unknownUser.address,
                getDeadline()
            )
        ).to.be.revertedWith('HIKARU#407');

        await expect(
            weightedVault.connect(unknownUser).swap(
                swapRoute,
                getSwapTypeId('Buy'),
                buyLimit,
                1,
                unknownUser.address,
                getDeadline()
            )
        ).to.be.revertedWith('HIKARU#408');
    })

    it ('Single swap -> Sell: 0 -> 1', async function () {
        const {
            weightedPool,
            weightedVault,
            unknownUser,
            tokens
        } = initSnapshot.snapshotData;

        /** @type {import("../typechain/contracts/Router/DefaultRouter").SwapRouteStruct[]} */
        const swapRoute = [
            { pool: weightedPool.address, tokenIn: tokens[0].address, tokenOut: tokens[1].address }
        ];

        const swapAmount = (await generateEqualTokenAmounts(100, [tokens[0]], unknownUser.address))[0];
        const expectedAmountOut = await weightedVault.calculateSwap(
            swapRoute,
            getSwapTypeId('Sell'),
            swapAmount
        );

        await expect(
            weightedVault.connect(unknownUser).swap(
                swapRoute,
                getSwapTypeId('Sell'),
                swapAmount,
                expectedAmountOut,
                unknownUser.address,
                getDeadline()
            )
        ).to.emit(
            'WeightedVault', 'Swap'
        ).withArgs(
            weightedPool.address,
            tokens[0].address,
            tokens[1].address,
            swapAmount,
            expectedAmountOut,
            unknownUser.address
        ).and.changeTokenBalances(
            tokens[0],
            [unknownUser.address, weightedVault.address],
            [-swapAmount, swapAmount]
        ).and.changeTokenBalances(
            tokens[1],
            [unknownUser.address, weightedVault.address],
            [expectedAmountOut, -expectedAmountOut]
        );
    })

    it ('Single swap -> Buy: 1 -> 2', async function () {
        const {
            weightedPool,
            weightedVault,
            unknownUser,
            tokens
        } = initSnapshot.snapshotData;

        /** @type {import("../typechain/contracts/Router/DefaultRouter").SwapRouteStruct[]} */
        const swapRoute = [
            { pool: weightedPool.address, tokenIn: tokens[1].address, tokenOut: tokens[2].address }
        ];

        const swapAmount = (await generateEqualTokenAmounts(100, [tokens[2]]))[0];
        const expectedAmountIn = await weightedVault.calculateSwap(
            swapRoute,
            getSwapTypeId('Buy'),
            swapAmount
        );
        await tokens[1].connect(unknownUser).mint(unknownUser.address, expectedAmountIn)

        await expect(
            weightedVault.connect(unknownUser).swap(
                swapRoute,
                getSwapTypeId('Buy'),
                swapAmount,
                expectedAmountIn,
                unknownUser.address,
                getDeadline()
            )
        ).to.emit(
            'WeightedVault', 'Swap'
        ).withArgs(
            weightedPool.address,
            tokens[1].address,
            tokens[2].address,
            expectedAmountIn,
            swapAmount,
            unknownUser.address
        ).and.changeTokenBalances(
            tokens[2],
            [unknownUser.address, weightedVault.address],
            [swapAmount, -swapAmount]
        ).and.changeTokenBalances(
            tokens[1],
            [unknownUser.address, weightedVault.address],
            [-expectedAmountIn, expectedAmountIn]
        );
    })
})

describe('WeightedPool -> withdraw tokens from pool', function() {
    it ('Load fixture and set inf approve', async function () {
        await initSnapshot.snapshot.restore();
        const {weightedPool, weightedVault, owner} = initSnapshot.snapshotData;
        await approveInfToAddress([weightedPool], weightedVault.address, owner);
    })

    it ('Weighted pool -> exitPool (with invalid deadline)', async function () {
        const {
            weightedVault,
            weightedPool,
            owner
        } = initSnapshot.snapshotData;

        const expectedAmountOut = (await weightedVault.calculateExitPool(
            weightedPool.address,
            1
        )).amounts;

        await expect(
            weightedVault.connect(owner).exitPool(
                weightedPool.address,
                1,
                expectedAmountOut,
                owner.address,
                1
            )
        ).to.be.revertedWith(
            'HIKARU#505'
        )
    })

    it ('Weighted pool -> exitPool (with invalid expected amount out)', async function () {
        const {
            weightedPool,
            weightedVault,
            owner
        } = initSnapshot.snapshotData;

        const lpAmount = ONE;
        const expectedAmountOut = (await weightedVault.calculateExitPool(
            weightedPool.address,
            lpAmount
        )).amounts;

        await expect(
            weightedVault.connect(owner).exitPool(
                weightedPool.address,
                lpAmount,
                expectedAmountOut.map((val) => val.add(1)),
                owner.address,
                getDeadline()
            )
        ).to.be.revertedWith(
            'HIKARU#414'
        );
    })

    it ('Weighted pool -> exitPool (zero tokens)', async function () {
        const {
            weightedVault,
            weightedPool,
            owner,
            tokens
        } = initSnapshot.snapshotData;

        await expect(
            weightedVault.connect(owner).exitPool(
                weightedPool.address,
                0,
                tokens.map(() => 0),
                owner.address,
                getDeadline()
            )
        ).to.changeTokenBalances(
            tokens[0],
            [weightedVault.address, owner.address],
            [0, 0]
        ).and.to.changeTokenBalances(
            tokens[1],
            [weightedVault.address, owner.address],
            [0, 0]
        ).and.to.changeTokenBalances(
            tokens[2],
            [weightedVault.address, owner.address],
            [0, 0]
        ).and.to.changeTokenBalances(
            tokens[3],
            [weightedVault.address, owner.address],
            [0, 0]
        )
    })

    it ('Weighted pool -> exitPoolSingleToken (with invalid deadline)', async function () {
        const {
            weightedPool,
            weightedVault,
            owner,
            tokens
        } = initSnapshot.snapshotData;

        await expect(
            weightedVault.connect(owner).exitPoolSingleToken(
                weightedPool.address,
                1,
                tokens[0].address,
                1,
                owner.address,
                1
            )
        ).to.be.revertedWith(
            'HIKARU#505'
        );
    })

    it ('Weighted pool -> exitPoolSingleToken (invalid expected amount out)', async function() {
        const {
            weightedPool,
            weightedVault,
            owner,
            tokens
        } = initSnapshot.snapshotData;

        const lpAmount = ONE;
        const exptectedAmountOut = await weightedVault.calculateExitPoolSingleToken(
            weightedPool.address, 
            lpAmount,
            tokens[0].address
        );

        await expect(
            weightedVault.connect(owner).exitPoolSingleToken(
                weightedPool.address,
                lpAmount,
                tokens[0].address,
                exptectedAmountOut.add(1),
                owner.address,
                getDeadline()
            )
        ).to.be.revertedWith(
            'HIKARU#414'
        );
    })

    it ('Weighted pool -> exitPoolSingleToken (zero tokens)', async function () {
        const {
            weightedPool,
            weightedVault,
            owner,
            tokens
        } = initSnapshot.snapshotData;

        await expect(
            weightedVault.connect(owner).exitPoolSingleToken(
                weightedPool.address,
                0,
                tokens[0].address,
                0,
                owner.address,
                getDeadline()
            )
        ).to.changeTokenBalances(
            tokens[0],
            [weightedVault.address, owner.address],
            [0, 0]
        );
    })

    it ('Weighted pool -> exitPool', async function () {
        const {
            weightedPool,
            weightedVault,
            owner,
            tokens
        } = initSnapshot.snapshotData;

        const lpAmount = BigNumber.from(10).pow(18).mul(100);
        const initLPAmount = await weightedPool.balanceOf(owner.address);
        const initLPTS = await weightedPool.totalSupply();

        const calculatedTokenAmounts = (await weightedVault.calculateExitPool(
            weightedPool.address,
            lpAmount
        )).amounts;

        await expect(
            weightedVault.connect(owner).exitPool(
                weightedPool.address,
                lpAmount,
                calculatedTokenAmounts,
                owner.address,
                getDeadline()
            )
        ).to.emit(
            weightedVault, 'Withdraw'
        ).withArgs(
            weightedPool.address,
            lpAmount,
            calculatedTokenAmounts,
            owner.address
        ).and.changeTokenBalances(
            tokens[0],
            [weightedVault.address, owner.address],
            [-calculatedTokenAmounts[0], calculatedTokenAmounts[0]]
        ).and.changeTokenBalances(
            tokens[1],
            [weightedVault.address, owner.address],
            [-calculatedTokenAmounts[1], calculatedTokenAmounts[1]]
        ).and.changeTokenBalances(
            tokens[2],
            [weightedVault.address, owner.address],
            [-calculatedTokenAmounts[2], calculatedTokenAmounts[2]]
        ).and.changeTokenBalances(
            tokens[3],
            [weightedVault.address, owner.address],
            [-calculatedTokenAmounts[3], calculatedTokenAmounts[3]]
        )

        const finalLPAmount = await weightedPool.balanceOf(owner.address);
        const finalLPTS = await weightedPool.totalSupply();

        expect(
            finalLPAmount
        ).to.be.eq(initLPAmount.sub(lpAmount), 'Invalid amount of LP tokens burned from user account');
        expect(
            finalLPTS
        ).to.be.eq(initLPTS.sub(lpAmount), 'Invalid amount of LP tokens burned');
    })


    it ('Weighted pool -> exitPoolSingleToken', async function() {
        const {
            weightedPool,
            weightedVault,
            owner,
            tokens
        } = initSnapshot.snapshotData;

        const lpAmount = BigNumber.from(10).pow(18).mul(10);
        const initLPAmount = await weightedPool.balanceOf(owner.address);
        const initLPTS = await weightedPool.totalSupply();

        const calculatedTokenAmount = await weightedVault.calculateExitPoolSingleToken(
            weightedPool.address,
            lpAmount,
            tokens[0].address
        );

        await expect(
            weightedVault.connect(owner).exitPoolSingleToken(
                weightedPool.address,
                lpAmount,
                tokens[0].address,
                calculatedTokenAmount,
                owner.address,
                getDeadline()
            )
        ).to.emit(
            weightedVault, 'Withdraw'
        ).withArgs(
            weightedPool.address,
            lpAmount,
            calculatedTokenAmount,
            owner.address
        ).and.changeTokenBalances(
            tokens[0],
            [weightedVault.address, owner.address],
            [-calculatedTokenAmount, calculatedTokenAmount]
        )

        const finalLPAmount = await weightedPool.balanceOf(owner.address);
        const finalLPTS = await weightedPool.totalSupply();

        expect(
            finalLPAmount
        ).to.be.eq(initLPAmount.sub(lpAmount), 'Invalid amount of LP tokens burned from user account');
        expect(
            finalLPTS
        ).to.be.eq(initLPTS.sub(lpAmount), 'Invalid amount of LP tokens burned');
    })
})

describe('WeightedPool -> swaps with multiple pools', function() {
    /**@type {import("../typechain").WeightedPool} */
    let secondPool;
    it ('Load fixture and set inf approve', async function() {
        await initSnapshot.snapshot.restore();
        const {
            weightedVault,
            tokens,
            unknownUser
        } = initSnapshot.snapshotData;
        await approveInfToAddress(tokens, weightedVault.address, unknownUser);
    })

    it ('Create second pool and initialize it', async function() {
        const {
            weightedVault,
            weightedPoolFactory,
            tokens,
            unknownUser
        } = initSnapshot.snapshotData;

        await weightedPoolFactory.connect(unknownUser).createPool(
            tokens.map((val) => val.address),
            new Array(4).fill(BigNumber.from(10).pow(18).div(4)),
            BigNumber.from(10).pow(15).mul(3),
            'SecondTestPool',
            'STP',
            unknownUser.address
        )

        const totalPools = await weightedPoolFactory.totalPools();

        secondPool = (
            await hre.ethers.getContractFactory('WeightedPool')
        ).attach(
            weightedPoolFactory.pools(totalPools.sub(1))
        );

        const initialAmounts = await generateEqualTokenAmounts(1e10, tokens, unknownUser.address);

        await expect(
            weightedVault.connect(unknownUser).joinPool(
                secondPool.address,
                initialAmounts,
                tokens.map(() => 0),
                unknownUser.address,
                getDeadline()
            )
        ).to.not.be.reverted;
    })

    it ('Virtual swap -> Sell: 0 -> 1 -> 2', async function () {
        const {
            weightedPool,
            weightedVault,
            unknownUser,
            tokens
        } = initSnapshot.snapshotData;

        /** @type {import("../typechain/contracts/Router/DefaultRouter").SwapRouteStruct[]} */
        const swapRoute = [
            { pool: weightedPool.address, tokenIn: tokens[0].address, tokenOut: tokens[1].address },
            { pool: secondPool.address, tokenIn: tokens[1].address, tokenOut: tokens[2].address }
        ];

        const swapAmount = (await generateEqualTokenAmounts(100, [tokens[0]], unknownUser.address))[0];
        const expectedAmountOut = await weightedVault.calculateSwap(
            swapRoute,
            getSwapTypeId('Sell'),
            swapAmount
        );

        // TODO: add swap events parameters checks
        await expect(
            weightedVault.connect(unknownUser).swap(
                swapRoute,
                getSwapTypeId('Sell'),
                swapAmount,
                expectedAmountOut,
                unknownUser.address,
                getDeadline()
            )
        ).to.emit(
            'WeightedVault', 'Swap'
        ).and.changeTokenBalances(
            tokens[0],
            [unknownUser.address, weightedVault.address],
            [-swapAmount, swapAmount]
        ).and.changeTokenBalances(
            tokens[2],
            [unknownUser.address, weightedVault.address],
            [expectedAmountOut, -expectedAmountOut]
        );
    })

    it ('Virtual swap -> Buy: 1 -> 2 -> 3', async function () {
        const {
            weightedPool,
            weightedVault,
            unknownUser,
            tokens
        } = initSnapshot.snapshotData;

        /** @type {import("../typechain/contracts/Router/DefaultRouter").SwapRouteStruct[]} */
        const swapRoute = [
            { pool: weightedPool.address, tokenIn: tokens[1].address, tokenOut: tokens[2].address },
            { pool: secondPool.address, tokenIn: tokens[2].address, tokenOut: tokens[3].address }
        ];

        const swapAmount = (await generateEqualTokenAmounts(100, [tokens[3]]))[0];
        const expectedAmountIn = await weightedVault.calculateSwap(
            swapRoute,
            getSwapTypeId('Buy'),
            swapAmount
        );
        await tokens[1].connect(unknownUser).mint(unknownUser.address, expectedAmountIn)

        // TODO: add swap events parameters checks
        await expect(
            weightedVault.connect(unknownUser).swap(
                swapRoute,
                getSwapTypeId('Buy'),
                swapAmount,
                expectedAmountIn,
                unknownUser.address,
                getDeadline()
            )
        ).to.emit(
            'WeightedVault', 'Swap'
        ).and.changeTokenBalances(
            tokens[3],
            [unknownUser.address, weightedVault.address],
            [swapAmount, -swapAmount]
        ).and.changeTokenBalances(
            tokens[1],
            [unknownUser.address, weightedVault.address],
            [-expectedAmountIn, expectedAmountIn]
        );
    })
})