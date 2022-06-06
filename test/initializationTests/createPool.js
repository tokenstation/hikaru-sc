const WeightedFactory = artifacts.require('WeightedPoolFactory');
const WeightedPool = artifacts.require('WeightedPool');
const ERC20Mock = artifacts.require('ERC20Mock');

const { toBN } = require('web3-utils');

//bn-chai SETUP
var chai = require('chai');
var expect = chai.expect;
var BN = require('bn.js');
var bnChai = require('bn-chai');

chai.use(bnChai(BN));

contract('WeightedFactory', async(accounts) => {

    const tokensConfig = [
        {
            name: 'tokenA',
            symbol: 'TA',
            decimals: 6
        },
        {
            name: 'tokenB',
            symbol: 'TB',
            decimals: 12
        },
        {
            name: 'tokenC',
            symbol: 'TC',
            decimals: 18
        }
    ];
    let tokenAddresses = [];
    let poolName = '';
    let poolSymbol = '';

    let weightedFactory;

    before(async() => {
        weightedFactory = await WeightedFactory.deployed();
    })

    describe('Prepare parameters', async() => {
        it ('Deploy ERC20 tokens', async() => {
            for (let tokenConfig of tokensConfig) {
                const deployedToken = await ERC20Mock.new(
                    tokenConfig.name,
                    tokenConfig.symbol,
                    tokenConfig.decimals
                );
                tokenAddresses.push(deployedToken.address);
            }
            tokenAddresses = tokenAddresses.sort();
        })

        it ('Create pool name and symbol', async() => {
            poolName = 'Hikaru Weighted Pool V1 ';
            poolSymbol = 'HWP '
            for (let tokenConfig of tokensConfig) {
                poolName += tokenConfig.name + '-';
                poolSymbol += tokenConfig.symbol + '-';
            }
        })
    })

    const tokenWeights = [
        toBN(3.33e17),
        toBN(3.33e17),
        toBN(3.34e17)
    ];
    const swapFee = toBN(0.003e18);

    describe('Initialize pool', async() => {
        it ('Initialize pool', async() => {
            console.log(
                tokenAddresses
            );
            console.log(
                await weightedFactory.version.call()
            );
            console.log(
                await weightedFactory.getCreationCode.sendTransaction()
            )
            let tx = await weightedFactory.createPool(
                tokenAddresses,
                tokenWeights,
                swapFee,
                poolName,
                poolSymbol,
                accounts[0]
            );
        })
    })
})