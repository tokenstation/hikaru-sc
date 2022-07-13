const ERC20Abi = require('./build/contracts/ERC20.json').abi;
const Router = require('./build/contracts/DefaultRouter.json').abi;
const Vault = require('./build/contracts/WeightedVault.json').abi;
const Pool = require('./build/contracts/WeightedPool.json').abi;
const fs = require('fs');

const directory = './abi/';

if (!fs.existsSync(directory)) {
    fs.mkdirSync(directory);
}

fs.writeFileSync(`${directory}/ERC20.abi.json`, JSON.stringify(ERC20Abi, null, '\t'));
fs.writeFileSync(`${directory}/Router.abi.json`, JSON.stringify(Router, null, '\t'));
fs.writeFileSync(`${directory}/WeightedVault.abi.json`, JSON.stringify(Vault, null, '\t'));
fs.writeFileSync(`${directory}/WeightedPool.abi.json`, JSON.stringify(Pool, null, '\t'));