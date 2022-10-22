import '@nomicfoundation/hardhat-toolbox';
import 'solidity-coverage';
import '@typechain/hardhat';
import '@typechain/ethers-v5';
import 'hardhat-deploy';
import 'hardhat-abi-exporter'
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
      hardfork: 'istanbul',
      gasPrice: 1
    },
    localhost: {
      url: 'http://127.0.0.1:8545/'
    }
  },
  solidity: {
    compilers: [ 
      {
        version: "0.8.6",
        settings: {
          optimizer: {
              enabled: true,
              runs: 200   // Optimize for how many times you intend to run the code
          },
        }
      },
      {
        version: "0.5.8",
        settings: {
          optimizer: {
              enabled: true,
              runs: 200   // Optimize for how many times you intend to run the code
          },
        }
      },
      {
        version: '0.4.25',
        settings: {
          optimizer: {
              enabled: true,
              runs: 200   // Optimize for how many times you intend to run the code
          },
        }
      }
    ],
    
  },
  paths: {
    tests: './tests',
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
  },
  abiExporter: {
    path: './exportedAbi',
    runOnCompile: true,
    clear: true,
    format: 'json'
  }
};

export default config