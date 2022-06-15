const WeightedFactory = artifacts.require('WeightedPoolFactory');
const WeightedVault = artifacts.require('WeightedVault');
const WeightedPool = artifacts.require('WeightedPool');
const ERC20Mock = artifacts.require('ERC20Mock');

const { toBN } = require('web3-utils');

//bn-chai SETUP
var chai = require('chai');
var expect = chai.expect;
var BN = require('bn.js');
var bnChai = require('bn-chai');

chai.use(bnChai(BN));

// TODO: add events check
// TODO: add invalid initialization checks

contract('WeightedFactory', async(accounts) => {

    let tokensConfig = [
        {
            name: 'tokenA',
            symbol: 'TA',
            decimals: 6,
            address: ''
        },
        {
            name: 'tokenB',
            symbol: 'TB',
            decimals: 12,
            address: ''
        },
        {
            name: 'tokenC',
            symbol: 'TC',
            decimals: 18,
            address: ''
        }
    ];
    let poolName = '';
    let poolSymbol = '';

    let weightedFactory;
    let weightedVault;
    let pool;

    before(async() => {
        weightedFactory = await WeightedFactory.deployed();
        weightedVault = await WeightedVault.deployed();
    })

    describe('Prepare parameters', async() => {
        it ('Deploy ERC20 tokens', async() => {
            for (let tokenConfig of tokensConfig) {
                const deployedToken = await ERC20Mock.new(
                    tokenConfig.name,
                    tokenConfig.symbol,
                    tokenConfig.decimals
                );
                tokenConfig.address = deployedToken.address.toLowerCase();
            }
            tokensConfig = tokensConfig.sort((a, b) => (a.address > b.address) ? 1 : ((b.address > a.address) ? -1 : 0))
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
        it ('Initialize pool and load it', async() => {
            const tokenAddresses = [];
            for (let tokenInfo of tokensConfig) tokenAddresses.push(tokenInfo.address);
            
            const expectedPoolAmount = toBN(await weightedFactory.totalPools.call()).add(toBN(1));
            let tx = await weightedFactory.createPool(
                tokenAddresses,
                tokenWeights,
                swapFee,
                poolName,
                poolSymbol,
                accounts[0]
            );
            expect(tx.receipt.status, 'Transaction failed');
            const poolAddress = await weightedFactory.pools.call(0);
            pool = await WeightedPool.at(poolAddress);
            expect(pool !== undefined, 'Did not load pool');
            const poolAmount = toBN(await weightedFactory.totalPools.call());
            expect(expectedPoolAmount).to.eq.BN(poolAmount, `Invalid amount of pools registered in factory`);
        })
    })

    describe('Check pool parameters', async() => {
        it('Check manager address', async() => {
            const expectedManager = accounts[0].toLowerCase();
            const manager = (await pool.manager.call());
            expect(
                expectedManager == manager,
                `Invalid manager address`
            );
        })
        
        it('Check factory and vault addresses', async() => {
            const factoryAddress = (await pool.factoryAddress.call()).toLowerCase();
            const expectedFactoryAddress = weightedFactory.address.toLowerCase();
            const vaultAddress = (await pool.vaultAddress.call()).toLowerCase();
            const expectedVaultAddress = weightedVault.address.toLowerCase();
            expect(
                factoryAddress == expectedFactoryAddress,
                `Invalid factory address set`
            );
            expect(
                vaultAddress == expectedVaultAddress,
                `Invalid vault address set`
            );
        })

        it('Check tokens and weights', async() => {
            let tokens = (await pool.getTokens.call()); 
            let weights = (await pool.getWeights.call());
            let multipliers = (await pool.getMultipliers.call());
            tokens = tokens.map((val) => val.toLowerCase());
            weights = weights.map((val) => toBN(val));
            multipliers = multipliers.map((val) => toBN(val));

            const expectedTokens = [];
            for (let tokenInfo of tokensConfig) expectedTokens.push(tokenInfo.address.toLowerCase);

            const expectedWeights = [];
            for (let tokenInfo of tokensConfig) expectedWeights.push(toBN(tokenInfo.decimals));

            const expectedMultipliers = [];
            for (let tokenInfo of tokensConfig) expectedMultipliers.push(getMultiplier(tokenInfo.decimals));

            for (let tokenId = 0; tokenId < tokens.length; tokenId++) {
                expect(
                    tokens[tokenId] == expectedTokens[tokenId],
                    `Invalid token address at position ${tokenId}`
                );
                expect(
                    weights[tokenId] == expectedWeights[tokenId],
                    `Invalid weight at position ${tokenId}`
                );
                expect(
                    multipliers[tokenId] == expectedMultipliers[tokenId],
                    `Invalid multiplier at position ${tokenId}`
                );
            }
        })

        it(`Check if pool is registered`, async() => {
            const poolRegistered = await weightedFactory.checkPoolAddress(pool.address);
            expect(
                poolRegistered,
                `Pool ${pool.address} was not registered in factory`
            );
        })

        it(`Check token balances`, async() => {
            const expectedBalanes = new Array(tokensConfig.length).fill(toBN(0));
            const realBalances = await weightedVault.getPoolBalances.call(pool.address);

            const realBalancesOneByOne = [];
            for (let tokenInfo of tokensConfig) {
                realBalancesOneByOne.push(
                    toBN(
                        await weightedVault.getPoolTokenBalance(
                            pool.address,
                            tokenInfo.address
                        )
                    )
                );
            }

            for (let tokenId = 0; tokenId < tokensConfig.length; tokenId++) {
                expect(expectedBalanes[tokenId]).to.eq.BN(realBalances[tokenId], `Invalid balance in all balances at position ${tokenId}`);
                expect(expectedBalanes[tokenId]).to.eq.BN(realBalancesOneByOne[tokenId], `Invalid balance in single balance at position ${tokenId}`);
            }
        })
    })
})

/**
 * @param {Number} decimals 
 * @returns {BN}
 */
function getMultiplier(decimals) {
    return toBN(10).pow(toBN(18 - decimals));
}