const FeeReceiver = artifacts.require('FeeReceiver');
const WeightedVault = artifacts.require('WeightedVault');
const WeightedPoolFactory = artifacts.require('WeightedPoolFactory');
const DefaultRouter = artifacts.require('DefaultRouter');

const flashloanFee = 1e15;
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const protocolFee = 1e15;

module.exports = async function(deployer, network, account) {
    if (network.indexOf('tron') < 0) return;
    await deployer.deploy(
        FeeReceiver, 
        tronWrap._accounts[0], 
        {save: true}
    );
    const deployedFeeReceiver = await FeeReceiver.deployed();
    console.log(`FeeReceiver: ${deployedFeeReceiver.address}`);

    await deployer.deploy(
        WeightedVault,  
        ZERO_ADDRESS,
        flashloanFee,
        deployedFeeReceiver.address,
        protocolFee
    );
    const deployedVault = await WeightedVault.deployed();
    console.log(`Vault: ${deployedVault.address}`);

    await deployer.deploy(
        WeightedPoolFactory,
        deployedVault.address
    );
    const deployedFactory = await WeightedPoolFactory.deployed();
    console.log(`Factory: ${WeightedPoolFactory.address}`);
    
    await deployedVault.setFactoryAddress(
        deployedFactory.address
    );

    await deployer.deploy(
        DefaultRouter
    )
    const deployedRouter = await DefaultRouter.deployed();
    console.log(`DefaultRouter: ${deployedRouter.address}`);
}