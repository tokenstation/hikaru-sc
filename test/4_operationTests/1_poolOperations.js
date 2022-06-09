// Pool operation tests
// Here we will check following operations:
// 1. Pool initialization by all tokens
// 2. Providing some tokens to pool
// 3. Providing one token to pool
// 4. Swap in default direction
// 5. Swap in reverse direction
// 6. Exit in all tokens
// 7. Exit in single token

const { expectRevert } = require("@openzeppelin/test-helpers");
const { toBN } = require("web3-utils");

const WeightedFactory = artifacts.require('WeightedPoolFactory');
const WeightedVault = artifacts.require('WeightedVault');
const WeightedPool = artifacts.require('WeightedPool');

const ERC20Mock = artifacts.require('ERC20Mock');
const TestMath = artifacts.require('TestMath');

var chai = require('chai');
var expect = chai.expect;
var BN = require('bn.js');
var bnChai = require('bn-chai');

chai.use(bnChai(BN));

const UINT256_MAX = toBN(2).pow(toBN(256)).sub(toBN(1));

// TODO: check events
// TOOO: add dry-run functions checks

contract('WeightedPool', async(accounts) => {
    // Used to deploy contract
    const manager = accounts[0];
    // Initializes pool
    const initializer = accounts[1];
    // Joins and exits pool
    const joiner = accounts[2];
    // Swaps tokens in pool
    const swapper = accounts[3];


    let pool;
    let testMath;
    let weightedVault;
    let weightedFactory;

    before(async() => {
        testMath = await TestMath.deployed();
        weightedVault = await WeightedVault.deployed();
        weightedFactory = await WeightedFactory.deployed();
    })

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
    let poolName = 'Hikaru WP ';
    let poolSymbol = 'HWP ';

    const tokenWeights = [
        toBN(3.33e17),
        toBN(3.33e17),
        toBN(3.34e17)
    ];
    const swapFee = toBN(0.003e18);

    describe('Create weighted pool', async() => {
        const tokens = [];
        it('Deploy ERC20 token mocks', async() => {
            for (let tokenInfo of tokensConfig) {
                const tokenInstance = await ERC20Mock.new(
                    tokenInfo.name,
                    tokenInfo.symbol,
                    tokenInfo.decimals
                );

                tokenInfo.address = tokenInstance.address.toLowerCase();
            }

            tokensConfig = tokensConfig.sort((a, b) => (a.address > b.address) ? 1 : ((b.address > a.address) ? -1 : 0));
            for (let tokenInfo of tokensConfig) {
                poolName += tokenInfo.name + '-';
                poolSymbol += tokenInfo.symbol + '-';
                tokens.push(tokenInfo.address);
            }
        })
        
        it('Deploy weighted pool', async() => {
            let tx = await weightedFactory.createPool(
                tokens,
                tokenWeights,
                swapFee,
                poolName,
                poolSymbol,
                manager
            )
            pool = await WeightedPool.at(tx.logs[0].args.poolAddress);
        })
    })

    describe('Initialize pool', async() => {
        it('Mint tokens to user', async() => {
            const tokens = await pool.getTokens.call();
            const amounts = await generateEqualAmountsForTokens(tokens, toBN(1e6));
            await mintTokensToUser(initializer, tokens, amounts);
        })

        it('Set infinite approval to vault from user', async() => {
            const tokens = await pool.getTokens.call();
            await setInfApprovalsTo(initializer, weightedVault.address, tokens);
        })

        it('Initialize pool', async() => {
            const amount = toBN(1e3);
            const tokens = await pool.getTokens.call();
            const amounts = await generateEqualAmountsForTokens(tokens, amount);
            const deadline = getDeadline();
            const tx = await weightedVault.joinPool(
                pool.address,
                amounts,
                deadline,
                from(initializer)
            );
        })
    })

    describe('Enter pool', async() => {
        it('Mint tokens to user', async() => {
            const amount = toBN(1e5);
            const tokens = await pool.getTokens.call();
            const amounts = await generateEqualAmountsForTokens(tokens, amount);
            await mintTokensToUser(joiner, tokens, amounts);
        })

        it('Set infinite approval to vault from user', async() => {
            const tokens = await pool.getTokens.call();
            await setInfApprovalsTo(joiner, weightedVault.address, tokens);
        })

        it('Enter pool using all tokens', async() => {
            const amount = toBN(1e4);
            const tokens = await pool.getTokens.call();
            const amounts = await generateEqualAmountsForTokens(tokens, amount);
            const deadline = getDeadline();
            const tx = await weightedVault.joinPool(
                pool.address,
                amounts,
                deadline,
                from(joiner)
            );
        })

        it('Enter pool using some tokens', async() => {
            const amount = toBN(1e4);
            const tokens = await pool.getTokens.call();
            let amounts = await generateEqualAmountsForTokens(tokens, amount);
            amounts[getRandomId(amounts.length)] = toBN(0);
            const deadline = getDeadline();
            const tx = await weightedVault.joinPool(
                pool.address,
                amounts,
                deadline,
                from(joiner)
            );
        })

        it('Enter pool using one token', async() => {
            const amount = toBN(1e4);
            const tokens = await pool.getTokens.call();
            let amounts = await generateEqualAmountsForTokens(tokens, amount);
            const randomId = getRandomId(amounts.length);
            amounts = amounts.map((val, index) => index == randomId ? val : toBN(0));
            const deadline = getDeadline();
            const tx = await weightedVault.joinPool(
                pool.address,
                amounts,
                deadline,
                from(joiner)
            );
        })
    })

    describe('Swap tokens in pool', async() => {
        it('Mint tokens to user', async() => {
            const amount = toBN(1e5);
            const tokens = await pool.getTokens.call();
            const amounts = await generateEqualAmountsForTokens(tokens, amount);
            await mintTokensToUser(swapper, tokens, amounts);
        })

        it('Set infinite approval to vault from user', async() => {
            const tokens = await pool.getTokens.call();
            await setInfApprovalsTo(swapper, weightedVault.address, tokens);
        })

        it('Perform default swap', async() => {
            const amount = toBN(1e4);
            const tokens = await pool.getTokens.call();
            const [tokenInIndex, tokenOutIndex] = getTwoRandomNumbers(tokens.length);
            const [tokenIn, tokenOut] = [tokens[tokenInIndex], tokens[tokenOutIndex]];
            const swapAmount = await getTokenAmountWithMultiplier(pool.address, tokenIn, amount);
            const deadline = getDeadline();

            const tx = await weightedVault.swap(
                pool.address,
                tokenIn,
                tokenOut,
                swapAmount,
                toBN(1),
                deadline,
                from(swapper)
            );
        })

        it('Perfrom swap with calculating tokenIn amount', async() => {
            const amount = toBN(1e4);
            const tokens = await pool.getTokens.call();
            const [tokenInIndex, tokenOutIndex] = getTwoRandomNumbers(tokens.length);
            const [tokenIn, tokenOut] = [tokens[tokenInIndex], tokens[tokenOutIndex]];
            const swapAmount = await getTokenAmountWithMultiplier(pool.address, tokenOut, amount);
            const deadline = getDeadline();

            const tx = await weightedVault.swapExactOut(
                pool.address,
                tokenIn,
                tokenOut,
                swapAmount,
                UINT256_MAX,
                deadline,
                from(swapper)
            );
        })

        it('Perform default swap using vault', async() => {
            const amount = toBN(1e4);
            const tokens = await pool.getTokens.call();
            const [tokenInIndex, tokenOutIndex] = getTwoRandomNumbers(tokens.length);
            const [tokenIn, tokenOut] = [tokens[tokenInIndex], tokens[tokenOutIndex]];
            const swapAmount = await getTokenAmountWithMultiplier(pool.address, tokenIn, amount);
            const deadline = getDeadline();

            const tx = await weightedVault.swap(
                pool.address,
                tokenIn,
                tokenOut,
                swapAmount,
                toBN(1),
                deadline,
                from(swapper)
            );
        })
    })

    describe('Exit from pool', async() => {
        it('Exit using all tokens', async() => {
            const amount = toBN(1e4);
            const lpAmount = await getLPBalance(pool.address, joiner, toBN(2));
            const deadline = getDeadline();
            
            const tx = await weightedVault.exitPool(
                pool.address,
                lpAmount,
                deadline,
                from(joiner)
            );
        })

        it('Exit pool using one token', async() => {
            const amount = toBN(1e4);
            const lpAmount = await getLPBalance(pool.address, joiner, toBN(2));
            const tokens = await pool.getTokens.call();
            const randomId = getRandomId(tokens.length);
            const tokenOut = tokens[randomId];
            const deadline = getDeadline();

            const tx = await weightedVault.exitPoolSingleToken(
                pool.address,
                lpAmount,
                tokenOut,
                deadline,
                from(joiner)
            );
        })
    })

    /**
     * @param {String} poolAddress 
     * @param {String} tokenAddress 
     * @param {BN} amount 
     * @returns {Promise<BN>}
     */
    async function getTokenAmountWithMultiplier(poolAddress, tokenAddress, amount) {
        const poolInstance = await WeightedPool.at(poolAddress);
        const tokenMultiplier = await poolInstance.getMultiplier(tokenAddress);
        return amount.mul(toBN(tokenMultiplier));
    }

    /**
     * @param {String} poolAddress 
     * @param {BN} amount 
     * @returns {Promise<BN>}
     */
    async function getLPAmountWithMultiplier(poolAddress, amount) {
        const poolInstance = await ERC20Mock.at(poolAddress);
        const decimals = await poolInstance.decimals.call();
        return amount.mul(toBN(10).pow(toBN(decimals)));
    }

    /**
     * 
     * @param {String} pool 
     * @param {String} user 
     * @param {BN?} part 
     */
    async function getLPBalance(pool, user, part) {
        const poolInstance = await ERC20Mock.at(pool);
        const balance = toBN(await poolInstance.balanceOf.call(user));
        return part ? balance.div(part) : balance;
    }

    /**
     * @param {String[]} tokens
     * @param {BN} amount 
     * @returns {Promise<BN[]>}
     */
    async function generateEqualAmountsForTokens(tokens, amount) {
        amount = toBN(amount);
        const resultAmounts = [];
        for (let tokenAddress of tokens) {
            const tokenInstance = await ERC20Mock.at(tokenAddress);
            const decimals = await tokenInstance.decimals.call();
            resultAmounts.push(
                amount.mul(toBN(10).pow(toBN(decimals)))
            )
        }
        return resultAmounts;
    }

    /**
     * @param {String} user 
     * @param {String[]} tokens 
     * @param {BN[]} amounts 
     */
    async function mintTokensToUser(user, tokens, amounts) {
        for (let tokenId = 0; tokenId < tokens.length; tokenId++) {
            const tokenInstance = await ERC20Mock.at(tokens[tokenId]);
            await tokenInstance.mint(user, amounts[tokenId])
        }
    }

    /**
     * @param {String} user 
     * @param {String} to 
     * @param {String[]} tokens 
     */
    async function setInfApprovalsTo(user, to, tokens) {
        for (let tokenId = 0; tokenId < tokens.length; tokenId++) {
            const tokenInstance = await ERC20Mock.at(tokens[tokenId]);
            await tokenInstance.approve(to, UINT256_MAX, from(user));
        }
    }
})

/**
 * @param {String} address 
 * @returns 
 */
function from(address) {
    return {
        from: address
    }
}

/**
 * 
 * @returns {Number}
 */
function getDeadline() {
    return Math.floor((+ new Date())/1000) + 100;
}

/**
 * 
 * @param {Number} n 
 * @returns {Number}
 */
function getRandomId(n) {
    return (+ new Date()) % n;
}

/**
 * 
 * @param {Number} ceil 
 */
function getTwoRandomNumbers(ceil) {
    let array = new Array(ceil).fill(0);
    array = array.map((val, index) => index);
    for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]]
    }

    return array.slice(0, 2);
}