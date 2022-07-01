const DefaultRouter = artifacts.require('DefaultRouter');

module.exports = async function(deployer, network) {
    if (network.indexOf('tron') > -1) return;
    await deployer.deploy(DefaultRouter);
}