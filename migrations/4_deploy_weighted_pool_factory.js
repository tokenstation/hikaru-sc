const WeightedVault = artifacts.require('WeightedVault');
const WeightedPoolFactory = artifacts.require('WeightedPoolFactory');

module.exports = async function(deployer, network) {
    if (network.indexOf('tron') > -1) return;
    const deployedVault = await WeightedVault.deployed();
    await deployer.deploy(
        WeightedPoolFactory,
        deployedVault.address
    );
}