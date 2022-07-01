const WeightedVault = artifacts.require('WeightedVault');
const WeightedPoolFactory = artifacts.require('WeightedPoolFactory');

module.exports = async function(deployer, network) {
    if (network.indexOf('tron') > -1) return;
    const deployedFactory = await WeightedPoolFactory.deployed();
    const deployedVault = await WeightedVault.deployed();
    await deployedVault.setFactoryAddress(
        deployedFactory.address
    );
}