const FeeReceiver = artifacts.require('FeeReceiver');
const WeightedVault = artifacts.require('WeightedVault');
const WeightedPoolFactory = artifacts.require('WeightedPoolFactory');

const flashloanFee = 1e15;
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

module.exports = async function(deployer, network, account) {
    await deployer.deploy(
        FeeReceiver, 
        tronWrap._accounts[0], 
        {save: true}
    );
    const deployedFeeReceiver = await FeeReceiver.deployed();

    await deployer.deploy(
        WeightedVault,  
        ZERO_ADDRESS,
        flashloanFee,
        deployedFeeReceiver.address
    );
    const deployedVault = await WeightedVault.deployed();

    await deployer.deploy(
        WeightedPoolFactory,
        deployedVault.address
    );
    const deployedFactory = await WeightedPoolFactory.deployed();
    
    await deployedVault.setFactoryAddress(
        deployedFactory.address
    );
}