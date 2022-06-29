const FeeReceiver = artifacts.require('FeeReceiver');

module.exports = async function(deployer, network, accounts) {
    if (network.indexOf('tron') > -1) return;
    await deployer.deploy(
        FeeReceiver, 
        accounts[0]
    );
}