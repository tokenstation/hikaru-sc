const WeightedVault = artifacts.require('WeightedVault');
const FeeReceiver = artifacts.require('FeeReceiver');

const flashloanFee = 1e15;
const protocolFee = 1e15;
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

module.exports = async function(deployer, network) {
    if (network.indexOf('tron') > -1) return;
    const deployedFeeReceiver = await FeeReceiver.deployed();

    await deployer.deploy(
        WeightedVault,  
        ZERO_ADDRESS,
        flashloanFee,
        deployedFeeReceiver.address,
        protocolFee
    );
}