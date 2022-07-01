// Pool operation tests
// Here we will check following operations:
// 1. Pool initialization by all tokens
// 2. Providing some tokens to pool
// 3. Providing one token to pool
// 4. Swap in default direction
// 5. Swap in reverse direction
// 6. Exit in all tokens
// 7. Exit in single token

const { toBN } = require("web3-utils");

const WeightedFactory = artifacts.require('WeightedPoolFactory');
const WeightedVault = artifacts.require('WeightedVault');
const WeightedPool = artifacts.require('WeightedPool');
const DefaultRouter = artifacts.require('DefaultRouter');

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
    let router;

    before(async() => {
        testMath = await TestMath.deployed();
        weightedVault = await WeightedVault.deployed();
        weightedFactory = await WeightedFactory.deployed();
        router = await DefaultRouter.deployed();
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
            await setInfApprovalsTo(initializer, router.address, tokens)
        })

        it('Initialize pool', async() => {
            const amount = toBN(1e6);
            const tokens = await pool.getTokens.call();
            const amounts = await generateEqualAmountsForTokens(tokens, amount);
            const initiazlizerDeltas = amounts.map((val) => val.mul(toBN(-1)));
            const addresses = [initializer, weightedVault.address];
            const deltas = [initiazlizerDeltas, amounts];
            const deadline = getDeadline();

            const weights = await pool.getWeights.call();
            const normalizedAmounts = await getTokenAmountsWithMultipliers(pool.address, amounts);
            const expectedLPAmount = toBN(
                await testMath.calcInitialization(
                    normalizedAmounts,
                    weights
                )
            );

            const initialBalances = await getBalancesForAddresses(addresses, tokens);

            const poolLPToken = await ERC20Mock.at(pool.address);
            const initialLPTS = toBN(await poolLPToken.totalSupply.call());
            const initialUserLPBalance = toBN(await poolLPToken.balanceOf.call(initializer));
            
            const txRes = await weightedVault.joinPool(
                pool.address,
                amounts,
                initializer,
                deadline,
                from(initializer)
            );

            const finalBalances = await getBalancesForAddresses(addresses, tokens);
            checkBNDeltas(initialBalances, finalBalances, deltas)
            

            const finalLPTS = toBN(await poolLPToken.totalSupply.call());
            const finalUserLPBalance = toBN(await poolLPToken.balanceOf.call(initializer));

            expect(finalLPTS).to.eq.BN(initialLPTS.add(expectedLPAmount), 'Invalid total supply');
            expect(finalUserLPBalance).to.eq.BN(initialUserLPBalance.add(expectedLPAmount), 'Invalid amount minted to user');;
        })
    })

    describe('Enter pool', async() => {
        it('Mint tokens to user', async() => {
            const amount = toBN(1e6);
            const tokens = await pool.getTokens.call();
            const amounts = await generateEqualAmountsForTokens(tokens, amount);
            await mintTokensToUser(joiner, tokens, amounts);
        })

        it('Set infinite approval to vault from user', async() => {
            const tokens = await pool.getTokens.call();
            await setInfApprovalsTo(joiner, weightedVault.address, tokens);
            await setInfApprovalsTo(joiner, router.address, tokens);
        })

        it('Enter pool using all tokens', async() => {
            const amount = toBN(1e5);
            const tokens = await pool.getTokens.call();
            const amounts = await generateEqualAmountsForTokens(tokens, amount);
            const joinerAmounts = amounts.map((val) => val.mul(toBN(-1)));
            const watchAddresses = [joiner, weightedVault.address];
            const deadline = getDeadline();

            const joinInfo = await prepareJoinInfo(pool.address, amounts, joiner);
            const initialBalances = await getBalancesForAddresses(watchAddresses, tokens);

            const tx = await weightedVault.joinPool(
                pool.address,
                amounts,
                joiner,
                deadline,
                from(joiner)
            );

            const finalBalances = await getBalancesForAddresses(watchAddresses, tokens);
            checkBNDeltas(initialBalances, finalBalances, [joinerAmounts, amounts]);
            await postJoinChecks(joinInfo);
        })

        it('Enter pool using all tokens via router', async() => {
            const amount = toBN(1e5);
            const tokens = await pool.getTokens.call();
            const amounts = await generateEqualAmountsForTokens(tokens, amount);
            const deadline = getDeadline();

            const tx = await router.fullJoin(
                weightedVault.address,
                pool.address,
                amounts,
                deadline,
                from(joiner)
            )
        })

        it('Enter pool using some tokens', async() => {
            const amount = toBN(1e5);
            const tokens = await pool.getTokens.call();
            let amounts = await generateEqualAmountsForTokens(tokens, amount);
            amounts[getRandomId(amounts.length)] = toBN(0);
            const joinerAmounts = amounts.map((val) => val.mul(toBN(-1)));
            const watchAddresses = [joiner, weightedVault.address];
            const deadline = getDeadline();

            const joinTokens = []; const joinAmounts = [];
            for(const tokenInfo of amounts.entries()) {
                const key = tokenInfo[0]; const val = tokenInfo[1];
                if (val.eq(toBN(0))) continue;
                joinTokens.push(tokens[key]);
                joinAmounts.push(amounts[key]);
            }

            const joinInfo = await prepareJoinInfo(pool.address, amounts, joiner);
            const initialBalances = await getBalancesForAddresses(watchAddresses, tokens);

            const tx = await weightedVault.partialPoolJoin(
                pool.address,
                joinTokens,
                joinAmounts,
                joiner,
                deadline,
                from(joiner)
            );

            const finalBalances = await getBalancesForAddresses(watchAddresses, tokens);
            checkBNDeltas(initialBalances, finalBalances, [joinerAmounts, amounts]);
            await postJoinChecks(joinInfo);
        })

        it('Enter pool using one token', async() => {
            const amount = toBN(1e5);
            const tokens = await pool.getTokens.call();
            let amounts = await generateEqualAmountsForTokens(tokens, amount);
            const watchAddresses = [joiner, weightedVault.address];
            const randomId = getRandomId(amounts.length);
            amounts = amounts.map((val, index) => index == randomId ? val : toBN(0));
            const joinerAmounts = amounts.map((val) => val.mul(toBN(-1)));
            const deadline = getDeadline();

            const joinInfo = await prepareJoinInfo(pool.address, amounts, joiner);
            const initialBalances = await getBalancesForAddresses(watchAddresses, tokens);

            const tx = await weightedVault.singleTokenPoolJoin(
                pool.address,
                tokens[randomId],
                amounts[randomId],
                joiner,
                deadline,
                from(joiner)
            );

            const finalBalances = await getBalancesForAddresses(watchAddresses, tokens);
            checkBNDeltas(initialBalances, finalBalances, [joinerAmounts, amounts]);
            await postJoinChecks(joinInfo);
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
            const deadline = getDeadline();

            const swapInitInfo = await prepareSwapInfo(pool.address, amount, true);

            const watchAddresses = [swapper, weightedVault.address];
            const watchTokens = [swapInitInfo.tokenIn, swapInitInfo.tokenOut];
            const initialBalances = await getBalancesForAddresses(watchAddresses, watchTokens);
            const deltas = [
                [swapInitInfo.swapAmount.mul(toBN(-1)), swapInitInfo.expectedResult],
                [swapInitInfo.swapAmount, swapInitInfo.expectedResult.mul(toBN(-1))]
            ]

            const tx = await weightedVault.sellTokens(
                pool.address,
                swapInitInfo.tokenIn,
                swapInitInfo.tokenOut,
                swapInitInfo.swapAmount,
                toBN(1),
                swapper,
                deadline,
                from(swapper)
            );

            const finalBalances = await getBalancesForAddresses(watchAddresses, watchTokens);
            checkBNDeltas(initialBalances, finalBalances, deltas);
            await postSwapChecks(swapInitInfo);
        })

        it('Perfrom swap with calculating tokenIn amount', async() => {
            const amount = toBN(1e4);
            const deadline = getDeadline();

            const swapInitInfo = await prepareSwapInfo(pool.address, amount, false);

            const watchAddresses = [swapper, weightedVault.address];
            const watchTokens = [swapInitInfo.tokenIn, swapInitInfo.tokenOut];
            const initialBalances = await getBalancesForAddresses(watchAddresses, watchTokens);
            const deltas = [
                [swapInitInfo.expectedResult.mul(toBN(-1)), swapInitInfo.swapAmount],
                [swapInitInfo.expectedResult, swapInitInfo.swapAmount.mul(toBN(-1))]
            ]

            const tx = await weightedVault.buyTokens(
                pool.address,
                swapInitInfo.tokenIn,
                swapInitInfo.tokenOut,
                swapInitInfo.swapAmount,
                UINT256_MAX,
                swapper,
                deadline,
                from(swapper)
            );

            const finalBalances = await getBalancesForAddresses(watchAddresses, watchTokens);
            checkBNDeltas(initialBalances, finalBalances, deltas);
            await postSwapChecks(swapInitInfo);
        })
    })

    describe('Exit from pool', async() => {
        it('Exit using all tokens', async() => {
            const lpAmount = await getLPBalance(pool.address, joiner, toBN(10));
            const deadline = getDeadline();
            
            const exitObj = await prepareExitInfo(pool.address, lpAmount, joiner);

            const tx = await weightedVault.exitPool(
                pool.address,
                lpAmount,
                joiner,
                deadline,
                from(joiner)
            );

            await postExitChecks(exitObj);
        })

        it('Exit pool using one token', async() => {
            const lpAmount = await getLPBalance(pool.address, joiner, toBN(10));
            const tokens = await pool.getTokens.call();
            const randomId = getRandomId(tokens.length);
            const tokenOut = tokens[randomId];
            const deadline = getDeadline();

            const exitObj = await prepareExitInfo(pool.address, lpAmount, joiner, tokenOut);

            const tx = await weightedVault.exitPoolSingleToken(
                pool.address,
                lpAmount,
                tokenOut,
                joiner,
                deadline,
                from(joiner)
            );

            await postExitChecks(exitObj);
        })
    })

    describe('Withdraw protocol fees', async() => {
        it('withdraw to clear account from manager', async() => {
            const receiver = accounts[9];
            const tokens = await pool.getTokens.call();
            const amounts = [];
            for (const address of tokens) {
                amounts.push(
                    toBN(await weightedVault.collectedFees.call(address))
                )
            }
            const initBalances = await getBalancesForAddress(receiver, tokens);

            const to = new Array(amounts.length).fill(receiver);
            const tx = await weightedVault.withdrawCollectedFees(tokens, amounts, to);

            const finalBalances = await getBalancesForAddress(receiver, tokens);

            checkBNDeltas([initBalances], [finalBalances], [amounts]);
        })
    })

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
     * @param {BN[]} amounts 
     */
    async function getTokenAmountsWithMultipliers(poolAddress, amounts) {
        const poolInstance = await WeightedPool.at(poolAddress);
        const multipliers = await poolInstance.getMultipliers.call();
        const resultAmounts = [];
        for(let tokenId = 0; tokenId < multipliers.length; tokenId++) {
            resultAmounts.push(
                amounts[tokenId].mul(toBN(multipliers[tokenId]))
            )
        }
        return resultAmounts;
    }

    /**
     * @param {String} poolAddress 
     * @param {BN[]} amounts 
     * @returns {Promise<BN>}
     */
    async function denormalizeAmounts(poolAddress, amounts) {
        const poolInstance = await WeightedPool.at(poolAddress);
        const multipliers = await poolInstance.getMultipliers.call();
        const resultAmounts = [];
        for (let id = 0; id < multipliers.length; id++) {
            resultAmounts.push(
                amounts[id].div(toBN(multipliers[id]))
            )
        }
        return resultAmounts;
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

    /**
     * @param {String} poolAddress 
     * @param {BN} lpAmount 
     * @param {String} user 
     * @param {String?} token 
     * @returns {Promise<Object>}
     */
    async function prepareExitInfo(poolAddress, lpAmount, user, token) {
        const poolInstance = await WeightedPool.at(poolAddress);
        const poolLPToken = await ERC20Mock.at(poolAddress);

        const tokens = await poolInstance.getTokens.call();
        const protocolFee = toBN(await weightedVault.protocolFee.call());
        const weights = await poolInstance.getWeights.call();
        const poolBalances = await weightedVault.getPoolBalances.call(poolAddress);
        const normalizedBalances = await getTokenAmountsWithMultipliers(poolAddress, poolBalances);
        const initialLPTS = toBN(await poolLPToken.totalSupply.call());
        const initialUserLPBalance = toBN(await poolLPToken.balanceOf.call(user));
        const swapFee = toBN(await poolInstance.swapFee.call());
        let resObj = {
            amountsOut: new Array(tokens.length).fill(toBN(0)),
            fee: new Array(tokens.length).fill(toBN(0)),
            protocolFees: new Array(tokens.length).fill(toBN(0)),
            balanceChanges: new Array(tokens.length).fill(toBN(0))
        };
        if (token) {
            const tokenId = tokens.indexOf(token);
            resObj = await testMath.calcExitSingleToken(
                normalizedBalances[tokenId],
                weights[tokenId],
                lpAmount,
                initialLPTS,
                swapFee,
                protocolFee
            )
            resObj.amountsOut = await denormalizeAmounts(poolAddress, fullArrayFromTokens(tokens, [token], [resObj.amountOut]));
            resObj.fee = await denormalizeAmounts(poolAddress, fullArrayFromTokens(tokens, [token], [resObj.fee]));
            resObj.protocolFees = await denormalizeAmounts(poolAddress, fullArrayFromTokens(tokens, [token], [resObj.pf]));
            resObj.balanceChanges = await denormalizeAmounts(poolAddress, fullArrayFromTokens(tokens, [token], [resObj.balanceChange]));
            
        } else {
            const amountsOut = await testMath.calcExit(
                normalizedBalances,
                lpAmount,
                initialLPTS
            )
            resObj.amountsOut = await denormalizeAmounts(poolAddress, amountsOut);
            resObj.balanceChanges = resObj.amountsOut.map((val) => val.mul(toBN(-1)));
        }

        const initBalances = (await weightedVault.getPoolBalances.call(poolAddress)).map((val) => toBN(val));
        
        const initialProtocolFees = [];
        for (const tokenAddress of tokens) {
            initialProtocolFees.push(
                toBN(await weightedVault.collectedFees.call(tokenAddress))
            );
        }

        return {
            ...resObj,
            poolAddress,
            poolLPToken,
            weights,
            poolBalances,
            normalizedBalances,
            initialLPTS,
            initialUserLPBalance,
            swapFee,
            initBalances,
            initialProtocolFees,
            lpAmount
        }
    }

    /**
     * 
     * @param {Object} exitObj 
     */
    async function postExitChecks(exitObj) {
        const finalLPTS = toBN(await exitObj.poolLPToken.totalSupply.call());
        const finalUserLPBalance = toBN(await exitObj.poolLPToken.balanceOf.call(joiner)); 

        expect(finalLPTS).to.eq.BN(exitObj.initialLPTS.sub(exitObj.lpAmount), 'Invalid total supply');
        expect(finalUserLPBalance).to.eq.BN(exitObj.initialUserLPBalance.sub(exitObj.lpAmount), 'Invalid amount minted to user');

        const poolBalances = (await weightedVault.getPoolBalances.call(exitObj.poolAddress)).map((val) => toBN(val));
        checkBNDeltas([exitObj.initBalances], [poolBalances], [exitObj.balanceChanges]);

        const poolInstance = await WeightedPool.at(exitObj.poolAddress);
        const tokens = await poolInstance.getTokens.call();
        const protocolFees = [];
        for (const address of tokens) {
            protocolFees.push(
                toBN(await weightedVault.collectedFees.call(address))
            );
        }
        checkBNDeltas([exitObj.initialProtocolFees], [protocolFees], [exitObj.protocolFees]);
    }

    /**
     * @param {String} poolAddress 
     * @param {BN[]} amounts 
     * @param {String} user 
     * @returns 
     */
    async function prepareJoinInfo(poolAddress, amounts, user) {
        const poolInstance = await WeightedPool.at(poolAddress);
        const poolLPToken = await ERC20Mock.at(poolAddress);

        const tokens = await poolInstance.getTokens.call();
        const protocolFee = toBN(await weightedVault.protocolFee.call());
        const normalizedAmounts = await getTokenAmountsWithMultipliers(poolAddress, amounts);
        const weights = await poolInstance.getWeights.call();
        const poolBalances = await weightedVault.getPoolBalances.call(poolAddress);
        const normalizedBalances = await getTokenAmountsWithMultipliers(poolAddress, poolBalances);
        const initialLPTS = toBN(await poolLPToken.totalSupply.call());
        const initialUserLPBalance = toBN(await poolLPToken.balanceOf.call(user));
        const swapFee = toBN(await poolInstance.swapFee.call());
        const calcRes = await testMath.calcJoin(
            normalizedAmounts,
            normalizedBalances,
            weights,
            initialLPTS,
            swapFee,
            protocolFee
        )
        const balanceChanges = await denormalizeAmounts(poolAddress, calcRes.balanceChanges);
        const fee = await denormalizeAmounts(poolAddress, calcRes.fee);
        const protocolFees = await denormalizeAmounts(poolAddress, calcRes.pf);
        const expectedLPAmount = toBN(calcRes.lpAmount);

        const initBalances = (await weightedVault.getPoolBalances.call(poolAddress)).map((val) => toBN(val));
        
        const initialProtocolFees = [];
        for (const tokenAddress of tokens) {
            initialProtocolFees.push(
                toBN(await weightedVault.collectedFees.call(tokenAddress))
            );
        }

        return {
            poolAddress,
            poolLPToken,
            normalizedAmounts,
            weights,
            poolBalances,
            normalizedBalances,
            initialLPTS,
            initialUserLPBalance,
            swapFee,
            expectedLPAmount,
            balanceChanges,
            fee,
            protocolFees,
            initBalances,
            initialProtocolFees
        }
    }

    /**
     * @param {String} poolAddress 
     * @param {Object} joinInfo 
     */
    async function postJoinChecks(joinInfo) {
        const finalLPTS = toBN(await joinInfo.poolLPToken.totalSupply.call());
        const finalUserLPBalance = toBN(await joinInfo.poolLPToken.balanceOf.call(joiner)); 

        expect(finalLPTS).to.eq.BN(joinInfo.initialLPTS.add(joinInfo.expectedLPAmount), 'Invalid total supply');
        expect(finalUserLPBalance).to.eq.BN(joinInfo.initialUserLPBalance.add(joinInfo.expectedLPAmount), 'Invalid amount minted to user');

        const poolBalances = (await weightedVault.getPoolBalances.call(joinInfo.poolAddress)).map((val) => toBN(val));
        checkBNDeltas([joinInfo.initBalances], [poolBalances], [joinInfo.balanceChanges]);

        const poolInstance = await WeightedPool.at(joinInfo.poolAddress);
        const tokens = await poolInstance.getTokens.call();
        const protocolFees = [];
        for (const address of tokens) {
            protocolFees.push(
                toBN(await weightedVault.collectedFees.call(address))
            );
        }
        checkBNDeltas([joinInfo.initialProtocolFees], [protocolFees], [joinInfo.protocolFees]);
    }

    /**
     * @param {String} poolAddress 
     * @param {BN} amount 
     * @param {Boolean} exactIn 
     */
    async function prepareSwapInfo(poolAddress, amount, exactIn) {
        

        const poolInstance = await WeightedPool.at(poolAddress);

        const protocolFee = await weightedVault.protocolFee.call();
        const poolBalances = (await weightedVault.getPoolBalances.call(poolAddress)).map((val) => toBN(val));
        const normalizedBalances = await getTokenAmountsWithMultipliers(poolAddress, poolBalances);
        const tokens = await poolInstance.getTokens.call();
        const weights = await poolInstance.getWeights.call();
        const multipliers = (await poolInstance.getMultipliers.call()).map((val) => toBN(val));
        const swapFee = await poolInstance.swapFee.call();
        const [tokenInIndex, tokenOutIndex] = getTwoRandomNumbers(tokens.length);
        const [tokenIn, tokenOut] = [tokens[tokenInIndex], tokens[tokenOutIndex]];
        const swapTokens = [tokenIn, tokenOut];
        const swapAmount = await getTokenAmountWithDecimals(
            exactIn ? tokenIn : tokenOut,
            amount
        );

        let resObj = {};
        let expectedObj = {};
        if (exactIn) {
            expectedObj = await testMath.calcOutGivenIn(
                normalizedBalances[tokenInIndex],
                weights[tokenInIndex],
                normalizedBalances[tokenOutIndex],
                weights[tokenOutIndex],
                swapAmount.mul(multipliers[tokenInIndex]),
                swapFee,
                protocolFee
            );
            resObj.expectedResult = expectedObj.amountOut.div(multipliers[tokenOutIndex]);
        } else {
            expectedObj = await testMath.calcInGivenOut(
                normalizedBalances[tokenInIndex],
                weights[tokenInIndex],
                normalizedBalances[tokenOutIndex],
                weights[tokenOutIndex],
                swapAmount.mul(multipliers[tokenOutIndex]),
                swapFee,
                protocolFee
            )
            resObj.expectedResult = expectedObj.amountIn.div(multipliers[tokenInIndex]);
        }

        resObj.fee = await denormalizeAmounts(poolAddress, fullArrayFromTokens(tokens, [tokenIn], [expectedObj.fee]));
        resObj.balanceChanges = await denormalizeAmounts(poolAddress, fullArrayFromTokens(tokens, swapTokens, expectedObj.balanceChanges));
        resObj.protocolFees = await denormalizeAmounts(poolAddress, fullArrayFromTokens(tokens, [tokenIn], [expectedObj.pf]));

        const initialProtocolFees = [];
        for (const tokenAddress of tokens) {
            initialProtocolFees.push(
                toBN(await weightedVault.collectedFees.call(tokenAddress))
            );
        }

        return {
            ...resObj,
            tokens,
            tokenIn,
            tokenOut,
            swapAmount,
            poolBalances,
            swapFee,
            poolAddress,
            initialProtocolFees
        }
    }

    /**
     * @param {Object} swapInfo 
     */
    async function postSwapChecks(swapInfo) {
        const poolBalances = (await weightedVault.getPoolBalances.call(swapInfo.poolAddress)).map((val) => toBN(val));
        checkBNDeltas([swapInfo.poolBalances], [poolBalances], [swapInfo.balanceChanges]);

        const poolInstance = await WeightedPool.at(swapInfo.poolAddress);
        const tokens = await poolInstance.getTokens.call();
        const protocolFees = [];
        for (const address of tokens) {
            protocolFees.push(
                toBN(await weightedVault.collectedFees.call(address))
            );
        }
        checkBNDeltas([swapInfo.initialProtocolFees], [protocolFees], [swapInfo.protocolFees]);
    }

    /**
     * @param {BN[][]} init 
     * @param {BN[][]} finish 
     * @param {BN[][]} delta 
     */
    function checkBNDeltas(init, finish, delta) {
        for (let id = 0; id < init.length; id++) {
            for(let iid = 0; iid < init[id].length; iid++) {
                // Due to rounding errors numbers may be off by 1
                const change = finish[id][iid].sub(init[id][iid]);
                const mismatch = change.sub(delta[id][iid]).abs();
                expect(mismatch).to.lte.BN(toBN(1), "Invalid delta");
            }
        }
    }

    /**
     * 
     * @param {String[]} addresses 
     * @param {String[]} tokens 
     * @returns {Promise<BN[][]>}
     */
    async function getBalancesForAddresses(addresses, tokens) {
        const balances = [];
        for (const address of addresses) {
            balances.push(
                await getBalancesForAddress(address, tokens)
            )
        }
        return balances;
    }

    /**
     * @param {String} address 
     * @param {String[]} tokens 
     * @returns {Promise<BN[]>}
     */
    async function getBalancesForAddress(address, tokens) {
        const balances = [];
        for (let tokenAddress of tokens) {
            let token = await ERC20Mock.at(tokenAddress);
            balances.push(
                toBN(
                    await token.balanceOf.call(address)
                )
            )
        }
        return balances;
    }

    /**
     * @param {String[]} tokens 
     * @param {String[]} swapTokens 
     * @param {BN[]} amounts 
     * @returns 
     */
    function fullArrayFromTokens(tokens, swapTokens, amounts) {
        const fullArray = [];
        for (const token of tokens) {
            let index = swapTokens.indexOf(token);
            fullArray.push(
                index !== -1 ? 
                    amounts[index] : 
                    toBN(0)
            );
        }
        return fullArray;
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
    return Math.floor((+ new Date())/1000) + 10000;
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