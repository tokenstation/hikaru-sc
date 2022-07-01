const Migrations = artifacts.require("Migrations");

module.exports = function(deployer, network) {
  if (network.indexOf('tron') > -1) return;
  deployer.deploy(Migrations);
};