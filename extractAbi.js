const ERC20Abi = require(`./artifacts/@openzeppelin/contracts/token/ERC20/ERC20.sol/ERC20.json`).abi;
const Router = require(`./artifacts/contracts/Router/DefaultRouter.sol/DefaultRouter.json`).abi;
const Vault = require(`./artifacts/contracts/Vaults/WeightedVault/WeightedVault.sol/WeightedVault.json`).abi;
const Pool = require(`./artifacts/contracts/SwapContracts/WeightedPool/WeightedPool.sol/WeightedPool.json`).abi;
const fs = require('fs');

const abiDirectory = './abi/';

if (!fs.existsSync(abiDirectory)) {
    fs.mkdirSync(abiDirectory);
}

fs.writeFileSync(`${abiDirectory}/ERC20.abi.json`, JSON.stringify(ERC20Abi, null, '\t'));
fs.writeFileSync(`${abiDirectory}/Router.abi.json`, JSON.stringify(Router, null, '\t'));
fs.writeFileSync(`${abiDirectory}/WeightedVault.abi.json`, JSON.stringify(Vault, null, '\t'));
fs.writeFileSync(`${abiDirectory}/WeightedPool.abi.json`, JSON.stringify(Pool, null, '\t'));