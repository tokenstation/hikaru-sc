const hre = require('hardhat');
const { SignerWithAddress } = require('@nomiclabs/hardhat-ethers/signers');
const { BigNumber, Signer } = require('ethers');
const { WeightedVault__factory, WeightedPoolFactory__factory, DefaultRouter__factory, ERC20Mock__factory, WeightedPool__factory, SunSwapVault__factory, SunswapFactory__factory, SunswapExchange__factory, WTRX__factory } = require('../../typechain');
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
 * @param {String} factoryAddress
 * @param {Number|String|BigNumber} flashloanFee
 * @param {Number|String|BigNumber} protocolFee
 * @param {SignerWithAddress} deployer
 * @returns {Promise<import('../../typechain').WeightedVault>}
 */
async function deployWeightedVault(
    factoryAddress,
    flashloanFee,
    protocolFee,
    deployer
) {
    /**
     * @type {WeightedVault__factory}
     */
    const WeightedVault = await hre.ethers.getContractFactory('WeightedVault');
    const weightedVault = await WeightedVault.connect(deployer).deploy(factoryAddress, flashloanFee, protocolFee);
    await weightedVault.deployed();
    return weightedVault;
}

/**
 * @param {import('../../typechain').WeightedVault} weightedVault
 * @param {SignerWithAddress} deployer
 * @returns {Promise<import('../../typechain').WeightedPoolFactory>}
 */
async function deployWeightedFactory(
    weightedVault,
    deployer
) {
    /**
     * @type {WeightedPoolFactory__factory}
     */
    const WeightedFactory = await hre.ethers.getContractFactory('WeightedPoolFactory');
    const weightedFactory = await WeightedFactory.connect(deployer).deploy(weightedVault.address);
    await weightedFactory.deployed();
    return weightedFactory;
}

/**
 * @param {SignerWithAddress} deployer 
 * @returns {Promise<import('../../typechain').DefaultRouter>}
 */
async function deployRouter(
    deployer
) {
    /**
     * @type {DefaultRouter__factory}
     */
    const DefaultRouter = await hre.ethers.getContractFactory('DefaultRouter');
    const defaultRouter = await DefaultRouter.connect(deployer).deploy();
    await defaultRouter.deployed();
    return defaultRouter;
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

    /** @type {import('../../typechain').ERC20Mock[]} */
    const tokenContracts = [];

    /**@type {import('@ethersproject/providers').TransactionReceipt[]} */
    const deployTx = [];

    for (const tokenInfo of tokenConfig) {
        const token = await ERC20Mock.connect(deployer).deploy(
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
    const deployTx = await weightedPoolFactory.connect(deployer).createPool(
        poolParameters.tokenAddresses,
        poolParameters.weights,
        poolParameters.swapFee,
        poolParameters.poolName,
        poolParameters.poolSymbol,
        poolParameters.owner
    );
    const poolDeployReceipt = await deployTx.wait();

    /**@type {WeightedPool__factory} */
    const WeightedPool = await hre.ethers.getContractFactory('WeightedPool');
    const weightedPool = WeightedPool.attach(
        await weightedPoolFactory.pools(currentPoolCount)
    )

    return {
        deployReceipt: poolDeployReceipt,
        pool: weightedPool
    };
}

/**
 * Deploy sunswap factory and perform initial setup
 * @param {SignerWithAddress} deployer 
 * @returns {Promise<import('../../typechain').SunswapFactory>}
 */
async function deploySunSwapFactory(
    deployer
) {
    /**
     * @type {SunswapFactory__factory}
     */
    const SunSwapFactory = await hre.ethers.getContractFactory('SunswapFactory');
    const sunSwapFactory = await SunSwapFactory.connect(deployer).deploy();
    await sunSwapFactory.deployed()
    
    /**
     * @type {SunswapExchange__factory}
     */
    const SunSwapExchange = await hre.ethers.getContractFactory('SunswapExchange')
    const sunSwapExchangeTemplate = await SunSwapExchange.connect(deployer).deploy();
    await sunSwapExchangeTemplate.deployed();

    await sunSwapFactory.initializeFactory(sunSwapExchangeTemplate.address);

    return sunSwapFactory;
}

/**
 * Deploy sunswap exchange contract using existing factory
 * @param {import('../../typechain').SunswapFactory} sunSwapFactory 
 * @param {import('../../typechain').ERC20} token 
 * @param {SignerWithAddress} deployer 
 */
async function deploySunSwapExchange(
    sunSwapFactory,
    token,
    deployer
) {
    await sunSwapFactory.connect(deployer).createExchange(
        token.address
    );

    /**
     * @type {SunswapExchange__factory}
     */
    const SunSwapExchange = await hre.ethers.getContractFactory('SunswapExchange');
    const exchange = SunSwapExchange.attach(
        await sunSwapFactory.getExchange(token.address)
    );
    return exchange;  
}

/**
 * Deploy sunswap vault
 * @param {import('../../typechain').WTRX} trxWrapper 
 * @param {SignerWithAddress} deployer
 * @returns {Promise<import('../../typechain').SunSwapVault>}
 */
async function deploySunSwapVault(
    trxWrapper,
    deployer
) {
    /**
     * @type {SunSwapVault__factory}
     */
    const SunSwapVault = await hre.ethers.getContractFactory('SunSwapVault');
    const sunSwapVault = await SunSwapVault.connect(deployer).deploy(trxWrapper.address);
    await sunSwapVault.deployed();
    return sunSwapVault;
}

/**
 * Deploy WTRX contract
 * @param {SignerWithAddress} deployer 
 * @returns {Promise<import('../../typechain').WTRX>}
 */
async function deployWTRX(
    deployer
) {
    /**
     * @type {WTRX__factory}
     */
    const WTRX_factory = await hre.ethers.getContractFactory('WTRX');
    const wtrx = await WTRX_factory.connect(deployer).deploy();
    await wtrx.deployed();
    return wtrx;
}

/**
 * Deploy default hikaru contract system
 * @param {Number|BigNumber} flashloanFee 
 * @param {Number|BigNumber} protocolFee 
 * @param {String} defaultManager
 * @param {SignerWithAddress} deployer
 */
async function deployHikaruContracts(
    flashloanFee,
    protocolFee,
    defaultManager,
    deployer
) {
    const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

    const weightedVault = await deployWeightedVault(ZERO_ADDRESS, flashloanFee, protocolFee, deployer);
    const weightedPoolFactory = await deployWeightedFactory(weightedVault, deployer);
    const defaultRouter = await deployRouter(deployer);

    await weightedVault.connect(deployer).setFactoryAddress(
        weightedPoolFactory.address
    );
    await weightedVault.connect(deployer).changeManager(
        defaultManager
    );

    return {
        weightedVault,
        weightedPoolFactory,
        defaultRouter
    }
}

module.exports = {
    deployHikaruContracts,
    deployTokenContracts,
    deploySwapPool,
    deployWeightedVault,
    deployWeightedFactory,
    deployRouter,
    deploySunSwapFactory,
    deploySunSwapExchange,
    deploySunSwapVault,
    deployWTRX
}