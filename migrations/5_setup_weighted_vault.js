const WeightedVault = artifacts.require('WeightedVault');
const WeightedPoolFactory = artifacts.require('WeightedPoolFactory');

module.exports = async function(deployer) {
    const deployedFactory = await WeightedPoolFactory.deployed();
    const deployedVault = await WeightedVault.deployed();
    await deployedVault.setFactoryAddress(
        deployedFactory.address
    );
}