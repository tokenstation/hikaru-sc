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
const { expectRevert } = require("@openzeppelin/test-helpers");

chai.use(bnChai(BN));

const UINT256_MAX = toBN(2).pow(toBN(256)).sub(toBN(1));

// TODO: check events
// TOOO: add dry-run functions checks

contract('WeightedVault', async(accounts) => {
    // Used to deploy contract
    const manager = accounts[0];
    // Initializes pool
    const initializer = accounts[1];
    // Joins and exits pool
    const swapper = accounts[2];
    // This address will receive tokens after swap
    const receiver = accounts[3];


    let pools = [];
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
    let tokenAddresses = [];
    let poolAddresses = [];

    const swapFee = toBN(0.003e18);

    // Token A -> B
    const firstPoolInfo = {
        poolName: 'Hikaru WP ',
        poolSymbol: 'HWP ',
        weights: [
            toBN(0.1e18),
            toBN(0.9e18)
        ],
        swapFee: toBN(3e15),
        tokens: []
    }

    // Token B -> C
    const secondPoolInfo = {
        poolName: 'Hikaru WP ',
        poolSymbol: 'HWP ',
        weights: [
            toBN(0.4e18),
            toBN(0.6e18)
        ],
        swapFee: toBN(5e15),
        tokens: []
    }

    describe('Initialize tokens and pools', async() => {
        it('Deploy tokens', async() => {
            for (const tokenInfo of tokensConfig) {
                const tokenInstance = await ERC20Mock.new(tokenInfo.name, tokenInfo.symbol, tokenInfo.decimals);
                tokenInfo.address = tokenInstance.address.toLowerCase();
            }

            tokensConfig = tokensConfig.sort((a, b) => (a.address > b.address) ? 1 : ((b.address > a.address) ? -1 : 0));
            tokenAddresses = tokensConfig.map((val) => val.address);

            firstPoolInfo.poolName += tokensConfig[0].name + tokensConfig[1].name;
            firstPoolInfo.poolSymbol += tokensConfig[0].symbol + tokensConfig[1].symbol;
            secondPoolInfo.poolName += tokensConfig[1].name + tokensConfig[2].name;
            secondPoolInfo.poolName += tokensConfig[1].symbol + tokensConfig[2].symbol;

            firstPoolInfo.tokens = [tokensConfig[0].address, tokensConfig[1].address];
            secondPoolInfo.tokens = [tokensConfig[1].address, tokensConfig[2].address];
        })

        it('Deploy two pools', async() => {
            let tx = await weightedFactory.createPool(
                firstPoolInfo.tokens,
                firstPoolInfo.weights,
                firstPoolInfo.swapFee,
                firstPoolInfo.poolName,
                firstPoolInfo.poolSymbol,
                manager
            )

            tx = await weightedFactory.createPool(
                secondPoolInfo.tokens,
                secondPoolInfo.weights,
                secondPoolInfo.swapFee,
                secondPoolInfo.poolName,
                firstPoolInfo.poolSymbol,
                manager
            )

            pools = [
                await WeightedPool.at(await weightedFactory.pools.call(0)),
                await WeightedPool.at(await weightedFactory.pools.call(1))
            ]

            poolAddresses = [
                pools[0].address,
                pools[1].address
            ]
        })

        it('Set infinite token approvals', async() => {
            await setInfApprovalsTo(initializer, weightedVault.address, tokenAddresses);
            await setInfApprovalsTo(swapper, weightedVault.address, tokenAddresses);
        })

        it('Provide tokens to pools', async() => {
            const amount = toBN(1e5);
            for (const pool of pools) {
                await provideEqualTokensToPool(pool.address, amount);
            }
        })

        it('Mint tokens to swapper', async() => {
            const amount = toBN(1e5);
            const amounts = await generateEqualAmountsForTokens(tokenAddresses, amount);
            await mintTokensToUser(swapper, tokenAddresses, amounts);
        })
    })

    describe('Test virtual swaps', async() => {

        it('Create route with tokenOut != tokenIn', async() => {
            const amountIn = await getTokenAmountWithDecimals(tokenAddresses[0], toBN(1e4));
            const tokenPath = [
                [tokenAddresses[0], tokenAddresses[1]],
                [tokenAddresses[2], tokenAddresses[1]]
            ]
            const path = createRouteForTokens(poolAddresses, tokenPath);
            await expectRevert.unspecified(
                weightedVault.virtualSwap(
                    path,
                    amountIn,
                    1,
                    receiver,
                    getDeadline(),
                    from(swapper)
                ),
                "Route contains mismatched tokens"
            )
        })

        it('Check minimal received parameter', async() => {
            const amountIn = await getTokenAmountWithDecimals(tokenAddresses[0], toBN(1e4));
            const delta = await getTokenAmountWithDecimals(tokenAddresses[2], toBN(1));
            const tokenPath = [
                [tokenAddresses[0], tokenAddresses[1]],
                [tokenAddresses[1], tokenAddresses[2]]
            ];
            const path = createRouteForTokens(poolAddresses, tokenPath);
            const expectedAmount = await calculateResultForVirtualSwap(path, amountIn);
            await expectRevert.unspecified(
                weightedVault.virtualSwap(
                    path,
                    amountIn,
                    expectedAmount.add(delta),
                    receiver,
                    getDeadline(),
                    from(swapper)
                ),
                "Not enough tokens received"
            )
        })

        it('Create correct swap path with one swap', async() => {
            const amountIn = await getTokenAmountWithDecimals(tokenAddresses[0], toBN(1e4));
            const tokenPath = [
                [tokenAddresses[0], tokenAddresses[1]]
            ];
            const path = createRouteForTokens([poolAddresses[0]], tokenPath);
            const expectedAmount = await calculateResultForVirtualSwap(path, amountIn);
            await weightedVault.virtualSwap(
                path,
                amountIn,
                expectedAmount,
                receiver,
                getDeadline(),
                from(swapper)
            );
        })

        it('Create correct swap path', async() => {
            const amountIn = await getTokenAmountWithDecimals(tokenAddresses[0], toBN(1e4));
            const tokenPath = [
                [tokenAddresses[0], tokenAddresses[1]],
                [tokenAddresses[1], tokenAddresses[2]]
            ];
            const path = createRouteForTokens(poolAddresses, tokenPath);
            const expectedAmount = await calculateResultForVirtualSwap(path, amountIn);
            await weightedVault.virtualSwap(
                path,
                amountIn,
                expectedAmount,
                receiver,
                getDeadline(),
                from(swapper)
            );
        })

        it('Multiple swaps in one', async() => {
            const amountIn = await getTokenAmountWithDecimals(tokenAddresses[0], toBN(1e4));
            const tokenPath = [
                [tokenAddresses[0], tokenAddresses[1]],
                [tokenAddresses[1], tokenAddresses[2]],
                [tokenAddresses[2], tokenAddresses[1]],
                [tokenAddresses[1], tokenAddresses[0]],
            ];
            const poolsUsed = [poolAddresses[0], poolAddresses[1], poolAddresses[1], poolAddresses[0]]
            const path = createRouteForTokens(poolsUsed, tokenPath);
            await weightedVault.virtualSwap(
                path,
                amountIn,
                toBN(1),
                receiver,
                getDeadline(),
                from(swapper)
            );
        })
    })

    /**
     * 
     * @param {String[][]} tokens 
     * @param {BN} amountIn 
     * @returns {Path[]}
     */
    function createRouteForTokens(pools, tokensPath) {
        const path = [];
        pools.map((pool, index) => {
            const tokens = tokensPath[index];
            path.push({
                pool,
                tokenIn: tokens[0],
                tokenOut: tokens[1]
            })
        })
        return path;
    }

    /**
     * @typedef {Object} Path
     * @property {String} pool
     * @property {String} tokenIn
     * @property {String} tokenOut
     */

    /**
     * 
     * @param {Path[]} path
     * @param {BN} amountIn
     */
    async function calculateResultForVirtualSwap(path, amountIn) {
        const protocolFee = await weightedVault.protocolFee.call();
        let amountOut = amountIn.add(toBN(0));
        for (const way of path) {
            const poolInfo = await getPoolInfo(way.pool);
            const tokenInIndex = poolInfo.tokens.indexOf(way.tokenIn);
            const tokenOutIndex = poolInfo.tokens.indexOf(way.tokenOut);
            let amountIn = amountOut.mul(poolInfo.multipliers[tokenInIndex]);
            const balanceIn = poolInfo.balances[tokenInIndex].mul(poolInfo.multipliers[tokenInIndex]);
            const balanceOut = poolInfo.balances[tokenOutIndex].mul(poolInfo.multipliers[tokenOutIndex]);
            const res = await testMath.calcOutGivenIn(
                balanceIn,
                poolInfo.weights[tokenInIndex],
                balanceOut,
                poolInfo.weights[tokenOutIndex],
                amountIn,
                poolInfo.swapFee,
                protocolFee
            )
            amountOut = res.amountOut.div(poolInfo.multipliers[tokenOutIndex]);
        }
        return amountOut;
    }

    /**
     * @typedef {Object} PoolInfo
     * @property {String[]} tokens
     * @property {BN[]} weights
     * @property {BN[]} multipliers
     * @property {BN[]} balances
     * @property {BN} swapFee
     */

    /**
     * 
     * @param {String} pool 
     * @returns {Promise<PoolInfo>}
     */
    async function getPoolInfo(pool) {
        const poolInstance = await WeightedPool.at(pool);
        const tokens = (await poolInstance.getTokens.call()).map((val) => val.toLowerCase());
        const weights = await poolInstance.getWeights.call();
        const multipliers = await poolInstance.getMultipliers.call();
        const balances = await weightedVault.getPoolBalances.call(pool);
        const swapFee = await poolInstance.swapFee.call();
        return {
            tokens,
            weights,
            multipliers,
            balances,
            swapFee
        }
    }

    /**
     * @param {String} tokenAddress 
     * @param {BN} amount 
     */
    async function getTokenAmountWithDecimals(tokenAddress, amount) {
        const tokenInstance = await ERC20Mock.at(tokenAddress);
        const decimals = toBN(await tokenInstance.decimals.call());
        return amount.mul(toBN(10).pow(decimals));
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
            resultAmounts.push(
                await getTokenAmountWithDecimals(tokenAddress, amount)
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
    

    async function provideEqualTokensToPool(pool, amount, user) {
        user = user ? user : initializer;
        const poolInstance = await WeightedPool.at(pool);
        const tokens = await poolInstance.getTokens.call();
        const amounts = await generateEqualAmountsForTokens(tokens, amount);
        await mintTokensToUser(
            user,
            await poolInstance.getTokens.call(),
            amounts
        );
        await weightedVault.joinPool(
            pool,
            amounts,
            receiver,
            getDeadline(),
            from(user)
        );
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
 * @returns {Number}
 */
 function getDeadline() {
    return Math.floor((+ new Date())/1000) + 10000;
}