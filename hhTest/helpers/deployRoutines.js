const hre = require('hardhat');
const { SignerWithAddress } = require('@nomiclabs/hardhat-ethers/signers');
const { BigNumber } = require('ethers');
const { WeightedVault__factory, WeightedPoolFactory__factory, DefaultRouter__factory, ERC20Mock__factory, WeightedPool__factory } = require('../../typechain');
const { from } = require('./utils');


/**
 * @typedef SwapPoolConfig
 * @property {String[]} tokenAddresses
 * @property {BigNumber[]} weights
 * @property {BigNumber} swapFee
 * @property {String} poolName
 * @property {String} poolSymbol
 * @property {String} owner
 */

/**
 * @typedef CustomManagers
 * @property {String} weightedVault
 */

/**
 * 
 * @param {Number|BigNumber} flashloanFee 
 * @param {Number|BigNumber} protocolFee 
 * @param {String} defaultManager
 * @param {SignerWithAddress} deployer
 * @param {CustomManagers?} owners
 * @returns 
 */
async function deployHikaruContracts(
    flashloanFee,
    protocolFee,
    defaultManager,
    deployer,
    owners
) {
    const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

    /**
     * @type {WeightedVault__factory}
     */
    const WeightedVault = await hre.ethers.getContractFactory('WeightedVault');
    WeightedVault.connect(deployer);
    /**
     * @type {WeightedPoolFactory__factory}
     */
    const WeightedPoolFactory = await hre.ethers.getContractFactory('WeightedPoolFactory');
    WeightedPoolFactory.connect(deployer);
    /**
     * @type {DefaultRouter__factory}
     */
    const DefaultRouter = await hre.ethers.getContractFactory('DefaultRouter');
    DefaultRouter.connect(deployer);

    const weightedVault = await WeightedVault.deploy(
        ZERO_ADDRESS, 
        flashloanFee, 
        protocolFee
    );
    await weightedVault.deployed();
    const weightedPoolFactory = await WeightedPoolFactory.deploy(
        weightedVault.address
    );
    await weightedPoolFactory.deployed();
    const defaultRouter = await DefaultRouter.deploy();
    await defaultRouter.deployed();

    await weightedVault.setFactoryAddress(
        weightedPoolFactory.address,
        from(deployer.address)
    );
    await weightedVault.changeManager(
        defaultManager,
        from(deployer.address)
    );

    return {
        weightedVault,
        weightedPoolFactory,
        defaultRouter
    }
}

/**
 * @typedef TokenConfig
 * @property {String} name
 * @property {String} symbol
 * @property {Number|BigNumber} decimals
 */

/**
 * @typedef TokenDeployInfo
 * @property {import('@ethersproject/providers').TransactionReceipt[]} deployReceipts
 * @property {import('../../typechain').ERC20[]} tokens
 */

/**
 * @param {TokenConfig[]} tokenConfig
 * @param {SignerWithAddress} deployer
 * @returns {Promise<TokenDeployInfo>} 
 */
async function deployTokenContracts(
    tokenConfig,
    deployer
) {
    /**
     * @type {ERC20Mock__factory}
     */
    const ERC20Mock = await hre.ethers.getContractFactory('ERC20Mock');
    ERC20Mock.connect(deployer);

    /** @type {import('../../typechain').ERC20Mock[]} */
    const tokenContracts = [];

    /**@type {import('@ethersproject/providers').TransactionReceipt[]} */
    const deployTx = [];

    for (const tokenInfo of tokenConfig) {
        const token = await ERC20Mock.deploy(
            tokenInfo.name, 
            tokenInfo.symbol, 
            tokenInfo.decimals
        );
        await token.deployed();
        tokenContracts.push(token);
        /**
         * @type {import('@ethersproject/providers').TransactionResponse}
         */
        const tx = await token.deployTransaction.wait();
        deployTx.push(tx);
    }

    return {
        deployReceipts: deployTx,
        tokens: tokenContracts
    }
}

/**
 * @typedef SwapPoolDeployInfo
 * @property {import('@ethersproject/providers').TransactionReceipt} deployReceipt
 * @property {import('../../typechain').WeightedPool} pool
 */

/**
 * @param {SwapPoolConfig} poolParameters
 * @param {import('../../typechain').WeightedPoolFactory} weightedPoolFactory
 * @param {SignerWithAddress} deployer
 * @returns {Promise<SwapPoolDeployInfo>}
 */
async function deploySwapPool(
    poolParameters,
    weightedPoolFactory,
    deployer
) {
    const currentPoolCount = await weightedPoolFactory.totalPools();
    const deployTx = await weightedPoolFactory.createPool(
        poolParameters.tokenAddresses,
        poolParameters.weights,
        poolParameters.swapFee,
        poolParameters.poolName,
        poolParameters.poolSymbol,
        poolParameters.owner,
        from(deployer.address)
    );
    const poolDeployReceipt = await deployTx.wait();

    /**@type {WeightedPool__factory} */
    const WeightedPool = await hre.ethers.getContractFactory('WeightedPool');
    const weightedPool = await WeightedPool.attach(
        await weightedPoolFactory.pools(currentPoolCount)
    )

    return {
        deployReceipt: poolDeployReceipt,
        pool: weightedPool
    };
}

module.exports = {
    deployHikaruContracts,
    deployTokenContracts,
    deploySwapPool
}