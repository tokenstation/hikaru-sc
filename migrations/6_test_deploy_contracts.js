const TestMath = artifacts.require('TestMath');

module.exports = async function(deployer, network, accounts) {
    if (
        network.indexOf('test') < 0 &&
        network.indexOf('dev') < 0
    ) return;

    await deployer.deploy(TestMath);
}