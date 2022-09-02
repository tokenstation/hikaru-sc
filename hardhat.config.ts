import '@nomicfoundation/hardhat-toolbox';
import 'solidity-coverage';
import '@typechain/hardhat';
import '@typechain/ethers-v5';
import 'hardhat-deploy';
import {HardhatUserConfig} from 'hardhat/types';

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      saveDeployments: true,
      tags: ['test'],
      deploy: ['./hhDeploy'],
      loggingEnabled: true,
      allowUnlimitedContractSize: true,
      hardfork: 'istanbul'
    },
    localhost: {
      url: 'http://127.0.0.1:8545/'
    }
  },
  solidity: {
    version: "0.8.6",
    settings: {
        optimizer: {
            enabled: true,
            runs: 200   // Optimize for how many times you intend to run the code
        },
    }
  },
  paths: {
    tests: './hhTest',
    deploy: './hhDeploy',
    deployments: './hhDeployments'
  },
  namedAccounts: {
    deployer: {
      default: 0
    },
    owner: {
      default: 0
    }
  },
  mocha: {
    timeout: 999999
  },
  typechain: {
    outDir: './typechain',
    target: 'ethers-v5',
    alwaysGenerateOverloads: true
  }
};

export default config