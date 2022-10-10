const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { SignerWithAddress } = require('@nomiclabs/hardhat-ethers/signers');
const { ZERO_ADDRESS } = require('@openzeppelin/test-helpers/src/constants');
const { expect } = require('chai');
const { BigNumber } = require('ethers');
const hre = require('hardhat');
const { deployHikaruContracts, deployTokenContracts, deploySwapPool } = require('./helpers/deployRoutines');
const { sortContractsByAddress } = require('./helpers/utils');

describe('Test Manageable contract parts', function() {
    it ('Manageable -> changeManager (invalid caller)', async function() {
        const {
            owner,
            weightedPool,
            deployer,
            unknownUser
        } = await loadFixture(deploySystemWithDefaultParameters);

        await expect(
            weightedPool.connect(unknownUser).changeManager(
                unknownUser.address
            )
        ).to.be.revertedWith('Manageable: caller is not the manager')

        await expect(
            weightedPool.connect(owner).changeManager(
                unknownUser.address
            )
        ).not.to.be.reverted;
    })

    it ('Manageable -> changeManager (ZeroAddress)', async function() {
        const {
            weightedPool,
            owner
        } = await loadFixture(deploySystemWithDefaultParameters);

        await expect(
            weightedPool.connect(owner).changeManager(
                ZERO_ADDRESS
            )
        ).to.be.revertedWith('Manageable: new manager is the zero address')
    })
})

describe('Test weighted vault protected functions', function() {
    it('Weighted vault -> registerPool', async function() {
        const {
            weightedVault,
            unknownUser,
            owner,
            deployer,
            tokens
        } = await loadFixture(deploySystemWithDefaultParameters);

        for (const user of [unknownUser, deployer, owner]) {
            await expect(
                weightedVault.connect(user).registerPool(
                    user.address,
                    tokens.map((val) => val.address)
                )
            ).to.be.revertedWith('HIKARU#302');
        }
    })

    it('Weighted vault -> setFactoryAddress', async function() {
        const {
            weightedVault,
            unknownUser,
            owner,
            deployer
        } = await loadFixture(deploySystemWithDefaultParameters);

        for (const user of [unknownUser, deployer]) {
            await expect(
                weightedVault.connect(user).setFactoryAddress(user.address)
            ).to.be.revertedWith('Manageable: caller is not the manager');
        }

        await expect(
            weightedVault.connect(owner).setFactoryAddress(owner.address)
        ).to.be.revertedWith('HIKARU#501');
    })

    it('Weighted vault -> setFlashloanFees', async function() {
        const {
            weightedVault,
            unknownUser,
            owner,
            deployer
        } = await loadFixture(deploySystemWithDefaultParameters);

        for (const user of [unknownUser, deployer]) {
            await expect(
                weightedVault.connect(user).setFlashloanFees(1)
            ).to.be.revertedWith('Manageable: caller is not the manager')
        }

        await expect(
            weightedVault.connect(owner).setFlashloanFees(
                BigNumber.from(10).pow(18).add(1)
            )
        ).to.be.revertedWith('HIKARU#702');

        await expect(
            weightedVault.connect(owner).setFlashloanFees(1)
        ).to.emit(weightedVault, 'FlashloanFeesUpdate').withArgs(1);
    })

    it('Weighted vault -> setProtocolFee', async function() {
        const {
            weightedVault,
            unknownUser,
            owner,
            deployer
        } = await loadFixture(deploySystemWithDefaultParameters);

        for (const user of [unknownUser, deployer]) {
            await expect(
                weightedVault.connect(user).setProtocolFee(1)
            ).to.be.revertedWith('Manageable: caller is not the manager');
        }

        await expect(
            weightedVault.connect(owner).setProtocolFee(
                BigNumber.from(10).pow(18).add(1)
            )
        ).to.be.revertedWith('HIKARU#705')

        await expect(
            weightedVault.connect(owner).setProtocolFee(1)
        ).to.emit(weightedVault, 'ProtocolFeeUpdate').withArgs(1);
    })

    it('Weighted vault -> withdrawCollectedFees', async function() {
        const {
            weightedVault,
            unknownUser,
            owner,
            deployer,
            tokens
        } = await loadFixture(deploySystemWithDefaultParameters);

        for (const user of [unknownUser, deployer]) {
            await expect(
                weightedVault.connect(user).withdrawCollectedFees(
                    tokens.map((val) => val.address),
                    new Array(tokens.length).fill(0),
                    new Array(tokens.length).fill(ZERO_ADDRESS)
                )
            ).to.be.revertedWith('Manageable: caller is not the manager')
        }

        await expect(
            weightedVault.connect(owner).withdrawCollectedFees(
                tokens.map((val) => val.address),
                new Array(tokens.length).fill(1),
                new Array(tokens.length).fill(ZERO_ADDRESS)
            )
        ).to.be.revertedWith('HIKARU#704');

        await expect(
            weightedVault.connect(owner).withdrawCollectedFees(
                tokens.map((val) => val.address),
                new Array(tokens.length).fill(0),
                new Array(tokens.length).fill(owner.address)
            )
        ).not.to.be.reverted;
    })
})

describe('Test weighted pool protected functions', function() {
    it ('Weighted pool -> setSwapFee', async function() {
        const {
            owner,
            deployer,
            unknownUser,
            weightedPool
        } = await loadFixture(deploySystemWithDefaultParameters);

        for (const user of [unknownUser, deployer]) {
            await expect(
                weightedPool.connect(user).setSwapFee(1)
            ).to.be.revertedWith('Manageable: caller is not the manager');
        }

        await expect(
            weightedPool.connect(owner).setSwapFee(
                BigNumber.from(10).pow(15).mul(5).add(1)
            )
        ).to.be.revertedWith('HIKARU#701')

        await expect(
            weightedPool.connect(owner).setSwapFee(1)
        ).to.emit(weightedPool, 'SwapFeeUpdate').withArgs(1);
    })

})

async function deploySystemWithDefaultParameters() {
    const [deployer, owner, unknownUser] = await hre.ethers.getSigners();

    const defaultParameters = {
        flashloanFee: BigNumber.from(10).pow(15),
        protocolFee: BigNumber.from(10).pow(15),
        deployer: deployer,
        defaultManager: owner
    }

    const baseContracts = await deployHikaruContracts(
        defaultParameters.flashloanFee,
        defaultParameters.protocolFee,
        defaultParameters.defaultManager.address,
        defaultParameters.deployer
    )

    /**@type {import('./helpers/deployRoutines').TokenConfig[]} */
    const defaultTokenParameters = [
        {
            name: 'TokenA',
            symbol: 'TA',
            decimals: 12
        },
        {
            name: 'TokenA',
            symbol: 'TA',
            decimals: 12
        },
        {
            name: 'TokenA',
            symbol: 'TA',
            decimals: 12
        },
        {
            name: 'TokenA',
            symbol: 'TA',
            decimals: 12
        }
    ]

    const { 
        tokens
    } = await deployTokenContracts(
        defaultTokenParameters, 
        defaultParameters.deployer
    );
    sortContractsByAddress(tokens);

    /**@type {import('./helpers/deployRoutines').SwapPoolConfig} */
    const defaultPoolParameters = {
        tokenAddresses: tokens.map((val) => val.address),
        weights: new Array(4).fill(BigNumber.from(10).pow(18).div(4)),
        swapFee: BigNumber.from(10).pow(15),
        poolName: 'TestPool',
        poolSymbol: 'TP',
        owner: defaultParameters.defaultManager.address
    }

    const weightedPoolInfo = await deploySwapPool(
        defaultPoolParameters,
        baseContracts.weightedPoolFactory,
        defaultParameters.deployer
    )

    return {
        deployer,
        owner,
        unknownUser,
        ...baseContracts,
        tokens,
        weightedPool: weightedPoolInfo.pool,
        weightedPoolCreationTx: weightedPoolInfo.deployReceipt,
        weightedPoolParameters: defaultPoolParameters
    }
}

/**
 * @typedef DefaultSystemInfo
 * @property {SignerWithAddress} deployer
 * @property {SignerWithAddress} owner
 * @property {SignerWithAddress} unknownUser
 * @property {import('../typechain').WeightedVault} weightedVault
 * @property {import('../typechain').WeightedPoolFactory} weightedPoolFactory
 * @property {import('../typechain').DefaultRouter} defaultRouter
 * @property {import('../typechain').ERC20Mock[]} tokens
 * @property {import('../typechain').WeightedPool} weightedPool
 * @property {import('@ethersproject/providers').TransactionReceipt} weightedPoolCreationTx
 * @property {import('./helpers/deployRoutines').SwapPoolConfig} weightedPoolParameters
 */

module.exports = {
    deploySystemWithDefaultParameters
}