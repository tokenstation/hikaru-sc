// For pool we need to check following contracts:
// 1. SingleManager - check if only manager can change fee setter
// 2. WieghtedVault - check that swap functions can only be accessed through vault

const { expectRevert } = require("@openzeppelin/test-helpers");
const { toBN } = require("web3-utils");

const WeightedFactory = artifacts.require('WeightedPoolFactory');
const WeightedVault = artifacts.require('WeightedVault');
const WeightedPool = artifacts.require('WeightedPool');
const ERC20Mock = artifacts.require('ERC20Mock');

var chai = require('chai');
var expect = chai.expect;
var BN = require('bn.js');
var bnChai = require('bn-chai');
const expectEvent = require("@openzeppelin/test-helpers/src/expectEvent");

chai.use(bnChai(BN));

// TODO: check events
// TODO: check why on pool interactions no revert msg is returned (but it shows it in ganache cli)

contract('WeightedPool access tests', async(accounts) => {

    const manager = accounts[1];
    const maliciousUser = accounts[2];

    let pool;
    let weightedVault;
    let weightedFactory;

    before(async () => {
        weightedFactory = await WeightedFactory.deployed();
        weightedVault = await WeightedVault.deployed();
    })

    describe('Create pool', async () => {
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
        let tokenAddresses = [];

        const tokenWeights = [
            toBN(3.33e17),
            toBN(3.33e17),
            toBN(3.34e17)
        ];
        const swapFee = toBN(0.003e18);

        it('Deploy ERC20 token mocks', async() => {
            for (let tokenConfig of tokensConfig) {
                const deployedToken = await ERC20Mock.new(
                    tokenConfig.name,
                    tokenConfig.symbol,
                    tokenConfig.decimals
                );
                tokenConfig.address = deployedToken.address.toLowerCase();
            }
            tokensConfig = tokensConfig.sort((a, b) => (a.address > b.address) ? 1 : ((b.address > a.address) ? -1 : 0))

            poolName = 'Hikaru Weighted Pool V1 ';
            poolSymbol = 'HWP '
            for (let tokenConfig of tokensConfig) {
                poolName += tokenConfig.name + '-';
                poolSymbol += tokenConfig.symbol + '-';
            }
            for (let tokenInfo of tokensConfig) tokenAddresses.push(tokenInfo.address);
        })

        it('Deploy pool', async() => {
            const tx = await weightedFactory.createPool(
                tokenAddresses,
                tokenWeights,
                swapFee,
                poolName,
                poolSymbol,
                manager
            )
            pool = await WeightedPool.at(tx.logs[0].args.poolAddress);
        })
    })

    describe('Calling fee change, rever expected for invalid account', async() => {
        const swapFee = toBN(0.003e18);
        it('Changing fee from malisious account', async() => {
            await expectRevert.unspecified(
                pool.setSwapFee(swapFee.add(toBN(1)), from(maliciousUser)),
                "Only manager can execute this function."
            );
        })

        it('Change fee using manager account', async() => {
            const newSwapFee = swapFee.add(toBN(2));
            const tx = await pool.setSwapFee(newSwapFee, from(manager));
            const setSwapFee = toBN(await pool.swapFee.call());
            expect(setSwapFee).to.eq.BN(newSwapFee, 'Invalid swap fee set');
            expectEvent(tx, 'SwapFeeUpdate', {newSwapFee: newSwapFee});
        })
    })

    // This functions must always fail if caller is not vault
    describe('Calling swap and enter/exit functions, revert expected for all accounts', async() => {
        it('Try to join/initialize pool', async() => {

            // Both initialization and join function use the same
            // external function for interactions
            // behavior is determined by checking totalSupply of LP tokens
            // so to check initialization access and join access it's enough to 
            // check single function

            const balances = await weightedVault.getPoolBalances.call(pool.address);
            const users = [manager, maliciousUser];
            const amounts = [
                toBN(1e18),
                toBN(2e18),
                toBN(3e18)
            ];
            for (let user of users) {
                await expectRevert.unspecified(
                    pool.joinPool(balances, user, amounts, from(user)),
                    "This function can only be accessed via vault"
                );
            }
        })

        it('Try to exit pool by one token and multiple tokens', async() => {
            const balances = await weightedVault.getPoolBalances.call(pool.address);
            const users = [manager, maliciousUser];
            const lpAmount = toBN(1e20);
            const token = (await pool.getTokens.call())[0];

            for (let user of users) {
                await expectRevert.unspecified(
                    pool.exitPool(balances, user, lpAmount, from(user)),
                    "This function can only be accessed via vault"
                )

                await expectRevert.unspecified(
                    pool.exitPoolSingleToken(balances, user, lpAmount, token, from(user)),
                    "This function can only be accessed via vault"
                )
            }
        })

        it('Try to swap in both directions', async() => {
            const tokens = (await pool.getTokens.call());

            const balances = await weightedVault.getPoolBalances.call(pool.address);
            const users = [manager, maliciousUser];
            const tokenIn = tokens[0];
            const tokenOut = tokens[1];
            const amountIn = toBN(1e18);
            const minAmountIn = toBN(1);
            const maxAmountIn = toBN(1e19);

            for (let user of users) {
                await expectRevert(
                    pool.swap(balances, tokenIn, tokenOut, amountIn, minAmountIn, from(user)),
                    "HIKARU#301"
                )

                await expectRevert(
                    pool.swap(balances, tokenIn, tokenOut, amountIn, maxAmountIn, from(user)),
                    "HIKARU#301"
                )
            }
        })
    })
})

function from(address) {
    return {
        from: address
    }
}