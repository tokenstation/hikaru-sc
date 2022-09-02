const { deploySystemWithDefaultParameters } = require("./settersTest");
const hre = require('hardhat');
const { loadFixture, takeSnapshot } = require("@nomicfoundation/hardhat-network-helpers");
const { FlashloanMock__factory } = require("../typechain");
const { expect } = require("chai");
const { generateEqualTokenAmounts, approveInfToAddress } = require("./helpers/utils");
const { BigNumber } = require("ethers");
const { provide } = require("./helpers/directOperations");

const initSnapshot = {
    /**@type {import("@nomicfoundation/hardhat-network-helpers").SnapshotRestorer} */
    snapshot: undefined,
    /**@type {import("./settersTest").DefaultSystemInfo} */
    snapshotData: undefined
}

/**@type {import("../typechain").FlashloanMock} */
let flashloanMock;

describe('Test flashloans', function () {

    it ('Deploy system and initialize default pool', async function() {
        const fixtureInfo = await loadFixture(deploySystemWithDefaultParameters);
        const {
            weightedPool,
            weightedVault,
            tokens,
            owner,
            deployer
        } = fixtureInfo;

        /**@type {FlashloanMock__factory} */
        const FlashloanMock = await hre.ethers.getContractFactory('FlashloanMock');
        FlashloanMock.connect(deployer);
        flashloanMock = await FlashloanMock.deploy()
        await generateEqualTokenAmounts(
            BigNumber.from(10).pow(9), 
            tokens, 
            flashloanMock.address
        );

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

        initSnapshot.snapshot = await takeSnapshot();
        initSnapshot.snapshotData = fixtureInfo;
    })

    it ('FlashloanMock -> invalid token order', async function () {
        const {
            tokens,
            weightedVault,
            owner
        } = initSnapshot.snapshotData;

        const flTokens = tokens.map((val) => val.address).reverse();

        await expect(
            flashloanMock.connect(owner).initiateFlashloan(
                weightedVault.address,
                flTokens,
                new Array(flTokens.length).fill(1),
                false,
                false,
                false
            )
        ).to.be.revertedWith(
            'HIKARU#101'
        )
    })

    it ('FlashloanMock -> reentrancy', async function() {
        const {
            tokens,
            weightedVault,
            owner
        } = initSnapshot.snapshotData;

        await expect(
            flashloanMock.connect(owner).initiateFlashloan(
                weightedVault.address,
                tokens.map((val) => val.address),
                new Array(4).fill(1),
                false,
                true,
                false
            )
        ).to.be.revertedWith(
            'HIKARU#204'
        )
    })

    it ('FlashloanMock -> do not return flashloan', async function() {
        const {
            tokens,
            weightedVault,
            owner
        } = initSnapshot.snapshotData;

        await expect(
            flashloanMock.connect(owner).initiateFlashloan(
                weightedVault.address,
                tokens.map((val) => val.address),
                new Array(4).fill(100),
                false,
                false,
                false
            )
        ).to.be.revertedWith(
            'HIKARU#703'
        )
    })

    it ('FlashloanMock -> try to steal tokens', async function() {
        const {
            tokens,
            weightedVault,
            owner
        } = initSnapshot.snapshotData;

        await expect(
            flashloanMock.connect(owner).initiateFlashloan(
                weightedVault.address,
                tokens.map((val) => val.address),
                new Array(4).fill(100),
                false,
                false,
                true
            )
        ).to.be.revertedWith(
            'HIKARU#703'
        )
    })

    it ('FlashloanMock -> try to steal tokens after transferring fees', async function () {
        const {
            tokens,
            weightedVault,
            owner
        } = initSnapshot.snapshotData;

        await expect(
            flashloanMock.connect(owner).initiateFlashloan(
                weightedVault.address,
                tokens.map((val) => val.address),
                new Array(4).fill(100),
                true,
                false,
                true
            )
        ).to.be.revertedWith(
            'HIKARU#703'
        )
    })

    it ('FlashloanMock -> default flashloan', async function () {
        const {
            tokens,
            weightedVault,
            owner,
            feeReceiver
        } = initSnapshot.snapshotData;

        const flAmounts = new Array(tokens.length).fill(100000)

        const tx = await flashloanMock.connect(owner).initiateFlashloan(
            weightedVault.address,
            tokens.map((val) => val.address),
            flAmounts,
            true,
            false,
            false
        )

        const fees = await Promise.all(
            tokens.map((val,index) => flashloanMock.receivedFees(index))
        );
        const receivedAmounts = await Promise.all(
            tokens.map((val,index) => flashloanMock.receivedAmounts(index))
        );
        const flTokens = await Promise.all(
            tokens.map((val,index) => flashloanMock.receivedTokens(index))
        );

        await expect(
            tx
        ).to.changeTokenBalances(
            tokens[0],
            [feeReceiver.address, flashloanMock.address],
            [fees[0], -fees[0]]
        ).and.to.changeTokenBalances(
            tokens[1],
            [feeReceiver.address, flashloanMock.address],
            [fees[1], -fees[1]]
        ).and.to.changeTokenBalances(
            tokens[2],
            [feeReceiver.address, flashloanMock.address],
            [fees[2], -fees[2]]
        ).and.to.changeTokenBalances(
            tokens[3],
            [feeReceiver.address, flashloanMock.address],
            [fees[3], -fees[3]]
        )

        for (const [id, token] of tokens.entries()) {
            expect(flTokens[id]).to.be.eq(token.address, 'Invalid token address flashloaned');
            expect(flAmounts[id]).to.be.eq(receivedAmounts[id], 'Invalid amount of tokens received for flashloan');
        }
    })

    it ('FeeReceiver -> withdraw fees', async function () {
        const {
            tokens,
            feeReceiver,
            owner
        } = initSnapshot.snapshotData;

        const balances = await Promise.all(tokens.map(async (val) => val.balanceOf(feeReceiver.address)));

        await expect(
            feeReceiver.connect(owner).withdrawFeesTo(
                tokens.map((val) => val.address),
                new Array(tokens.length).fill(owner.address),
                balances
            )
        ).to.changeTokenBalances(
            tokens[0],
            [feeReceiver.address, owner.address],
            [-balances[0], balances[0]]
        ).and.to.changeTokenBalances(
            tokens[1],
            [feeReceiver.address, owner.address],
            [-balances[1], balances[1]]
        ).and.to.changeTokenBalances(
            tokens[2],
            [feeReceiver.address, owner.address],
            [-balances[2], balances[2]]
        ).and.to.changeTokenBalances(
            tokens[3],
            [feeReceiver.address, owner.address],
            [-balances[3], balances[3]]
        )
    })
})