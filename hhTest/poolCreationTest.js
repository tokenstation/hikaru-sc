const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers")
const { expect } = require("chai")
const { deploySystemWithDefaultParameters } = require("./settersTest")

describe('Weighted Pool -> pool creation', function () {
    // TODO: add tests for initializtion parameters
})

describe('Factory -> Pool creation', function () {
    it ('Factory -> createPool', async function () {
        // TODO: add full routine for pool creation
        await expect(
            (await deploySystemWithDefaultParameters()).weightedPoolCreationTx
        ).not.to.be.reverted;
    })

    it ('Factory -> totalPools', async function () {
        const {
            weightedPoolFactory
        } = await loadFixture(deploySystemWithDefaultParameters);

        expect(
            await weightedPoolFactory.totalPools()
        ).to.be.eq(1);
    })

    it ('Factory -> checkPoolAddress', async function () {
        const {
            weightedPool,
            weightedPoolFactory
        } = await loadFixture(deploySystemWithDefaultParameters);

        expect(
            await weightedPoolFactory.checkPoolAddress(weightedPool.address)
        ).to.be.true;
    })

    it ('Factory -> PoolCreated', async function () {
        const {
            weightedPool,
            weightedPoolFactory,
            weightedPoolCreationTx
        } = await loadFixture(deploySystemWithDefaultParameters)

        await expect(
            weightedPoolCreationTx.transactionHash
        ).to.emit(
            weightedPoolFactory, 'PoolCreated'
        ).withArgs(weightedPool.address);
    })
})

describe('Vault -> Pool creation', function () {
    it ('Vault -> PoolRegistered', async function () {
        const {
            weightedVault,
            weightedPool,
            weightedPoolCreationTx
        } = await loadFixture(deploySystemWithDefaultParameters);

        await expect(
            weightedPoolCreationTx.transactionHash
        ).to.emit(
            weightedVault, 'PoolRegistered'
        ).withArgs(weightedPool.address);
    })

    it ('Vault -> getPoolBalances', async function() {
        const {
            weightedVault,
            weightedPool
        } = await loadFixture(deploySystemWithDefaultParameters);

        expect(
            await weightedVault.getPoolBalances(weightedPool.address)
        ).to.have.lengthOf(await weightedPool.N_TOKENS());
    })
})