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

    it ('FlashloanMock -> try to initiate flashloan with zero amounts', async function () {
        const {
            tokens,
            weightedVault,
            owner
        } = initSnapshot.snapshotData;

        const amounts = new Array(tokens.length).fill(100);
        amounts[0] = 0;

        await expect(
            flashloanMock.connect(owner).initiateFlashloan(
                weightedVault.address,
                tokens.map((val) => val.address),
                amounts,
                true,
                false,
                false
            )
        ).to.be.revertedWith(
            'HIKARU#106'
        );
    })

    it ('FlashloanMock -> default flashloan', async function () {
        const {
            tokens,
            weightedVault,
            owner
        } = initSnapshot.snapshotData;

        const flAmounts = new Array(tokens.length).fill(100000)

        const initProtocolFees = await Promise.all(
            tokens.map((val) => weightedVault.collectedFees(val.address))
        );

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
        ).to.changeTokenBalance(
            tokens[0],
            flashloanMock.address,
            -fees[0]
        ).and.to.changeTokenBalance(
            tokens[1],
            flashloanMock.address,
            -fees[1]
        ).and.to.changeTokenBalance(
            tokens[2],
            flashloanMock.address,
            -fees[2]
        ).and.to.changeTokenBalance(
            tokens[3],
            flashloanMock.address,
            -fees[3]
        )

        const finalProtocolFees = await Promise.all(
            tokens.map((val) => weightedVault.collectedFees(val.address))
        );

        for (const [id, token] of tokens.entries()) {
            expect(flTokens[id]).to.be.eq(token.address, 'Invalid token address flashloaned');
            expect(flAmounts[id]).to.be.eq(receivedAmounts[id], 'Invalid amount of tokens received for flashloan');
            expect(
                finalProtocolFees[id]
            ).to.be.eq(initProtocolFees[id].add(fees[id]), 'Invalid amount of fees added to procol fees');
        }
    })

    it ('WeightedVault -> withdraw fees', async function () {
        const {
            tokens,
            weightedVault,
            owner
        } = initSnapshot.snapshotData;

        const fees = await Promise.all(
            tokens.map((val) => weightedVault.collectedFees(val.address))
        );

        await expect(
            weightedVault.connect(owner).withdrawCollectedFees(
                tokens.map((val) => val.address),
                fees,
                new Array(tokens.length).fill(owner.address)
            )
        ).to.changeTokenBalances(
            tokens[0],
            [weightedVault.address, owner.address],
            [-fees[0], fees[0]]
        ).and.to.changeTokenBalances(
            tokens[1],
            [weightedVault.address, owner.address],
            [-fees[1], fees[1]]
        ).and.to.changeTokenBalances(
            tokens[2],
            [weightedVault.address, owner.address],
            [-fees[2], fees[2]]
        ).and.to.changeTokenBalances(
            tokens[3],
            [weightedVault.address, owner.address],
            [-fees[3], fees[3]]
        )

        const finalProtocolFees = await Promise.all(
            tokens.map((val) => weightedVault.collectedFees(val.address))
        );

        expect(
            finalProtocolFees
        ).to.deep.eq(new Array(finalProtocolFees.length).fill(0), 'Invalid remaining protocol fees');
    })
})