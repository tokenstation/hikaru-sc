const Migrations = artifacts.require("Migrations");

module.exports = function(deployer, network, accounts) {
  if (network.indexOf('tron') < 0) return;
  deployer.deploy(Migrations);
};