const FeeReceiver = artifacts.require('FeeReceiver');

module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(
        FeeReceiver, 
        accounts[0]
    );
}