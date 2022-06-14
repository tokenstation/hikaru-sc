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

const WeightedVault = artifacts.require('WeightedVault');
const FeeReceiver = artifacts.require('FeeReceiver');

const ERC20Mock = artifacts.require('ERC20Mock');
const FlashloanerMock = artifacts.require('FlashloanerMock');

var chai = require('chai');
var expect = chai.expect;
var BN = require('bn.js');
var bnChai = require('bn-chai');

chai.use(bnChai(BN));


contract('WeightedVault', async(accounts) => {
    let weightedVault;
    let flashloanerMock;
    let feeReceiver;

    before(async() => {
        weightedVault = await WeightedVault.deployed();
        flashloanerMock = await FlashloanerMock.new();
        feeReceiver = await FeeReceiver.deployed();
    })

    /**
     * @type {String[]}
     */
    let tokens = [];

    describe('Prepare vault', async () => {
        it('Create tokens', async() => {
            const tokensConfig = [
                {
                    name: 'tokenA',
                    symbol: 'TA',
                    decimals: 6,
                },
                {
                    name: 'tokenB',
                    symbol: 'TB',
                    decimals: 12,
                },
                {
                    name: 'tokenC',
                    symbol: 'TC',
                    decimals: 18,
                }
            ];

            for (const tokenInfo of tokensConfig) {
                const token = await ERC20Mock.new(
                    tokenInfo.name,
                    tokenInfo.symbol,
                    tokenInfo.decimals
                );
                tokens.push(token.address.toLowerCase());
            }

            if (tokens[0] < tokens[1]) [tokens[0], tokens[1]] = [tokens[1], tokens[0]];
        })

        it('Send tokens to vault', async() => {
            const amount = toBN(1e6);
            const flashloanAmounts = await generateEqualAmountsForTokens(tokens, amount);
            await mintTokensToUser(weightedVault.address, tokens, flashloanAmounts);
        })
    })

    describe('Execute flashloans', async() => {
        it('Try with unsorted tokens', async() => {
            const amount = toBN(1e5);
            const flashloanAmounts = await generateEqualAmountsForTokens(tokens, amount);
            const flags = [true, false, false];
            await expectRevert.unspecified(
                flashloan(
                    tokens,
                    flashloanAmounts,
                    flags
                )
            )
        })

        it('Regular flashloan', async() => {
            tokens = tokens.sort();
            const amount = toBN(1e5);
            const flashloanAmounts = await generateEqualAmountsForTokens(tokens, amount);
            const flags = [true, false, false];

            const flashloanFee = await weightedVault.flashloanFee.call();
            const expectedBalanceDelta = flashloanAmounts.map((val) => val.mul(flashloanFee).div(toBN(1e18)));
            const initialVaultBalances = await getBalancesForAddress(weightedVault.address, tokens);
            const initialFRBalances = await getBalancesForAddress(feeReceiver.address, tokens);

            await flashloan(
                tokens,
                flashloanAmounts,
                flags
            );

            const finalVaultBalances = await getBalancesForAddress(weightedVault.address, tokens);
            const finalFRBalances = await getBalancesForAddress(feeReceiver.address, tokens);

            const receivedVaultAddress = await flashloanerMock.vaultAddress.call();
            const rf0 = await flashloanerMock.returnFlashloan.call();
            const rf1 = await flashloanerMock.tryReentrancy.call();
            const rf2 = await flashloanerMock.tryToStealTokens.call();

            for (let id = 0; id < tokens.length; id++) {
                const receivedAmount = toBN(await flashloanerMock.receivedAmounts.call(id));
                const receivedFee = toBN(await flashloanerMock.receivedFees.call(id));
                const receivedToken = (await flashloanerMock.receivedTokens.call(id)).toLowerCase();
                expect(receivedAmount).to.eq.BN(flashloanAmounts[id], 'Invalid flahsloan amounts');
                expect(receivedFee).to.eq.BN(expectedBalanceDelta[id], 'invalid flashloan fees');
                expect(receivedToken).to.equal(tokens[id], 'Invalid token address received');
            }

            expect(receivedVaultAddress).to.equal(weightedVault.address, 'invalid vault address received');
            expect(rf0 == flags[0] && rf1 == flags[1] && rf2 == flags[2], 'invalid user data received');

            checkBNDeltas(initialVaultBalances, finalVaultBalances, new Array(tokens.length).fill(toBN(0)));
            checkBNDeltas(initialFRBalances, finalFRBalances, expectedBalanceDelta);
        })

        it('Try reentrancy', async () => {
            const amount = toBN(1e5);
            const flashloanAmounts = await generateEqualAmountsForTokens(tokens, amount);
            const flags = [true, true, false];
            await expectRevert.unspecified(
                flashloan(
                    tokens,
                    flashloanAmounts,
                    flags
                )
            );
        })

        it('Try not to return flashloan', async() => {
            const amount = toBN(1e5);
            const flashloanAmounts = await generateEqualAmountsForTokens(tokens, amount);
            const flags = [false, false, false];
            await expectRevert.unspecified(
                flashloan(
                    tokens,
                    flashloanAmounts,
                    flags
                )
            );
        })

        it('Try to steal tokens from vault', async() => {
            const amount = toBN(1e5);
            const flashloanAmounts = await generateEqualAmountsForTokens(tokens, amount);
            const flags = [false, false, true];
            await expectRevert.unspecified(
                flashloan(
                    tokens,
                    flashloanAmounts,
                    flags
                )
            );
        })
    })

    describe('Withdraw tokens from fee receiver', async () => {
        it('Withdraw fees', async() => {
            const receiver = accounts[2];
            const initBalances = await getBalancesForAddress(receiver, tokens);
            const initFeeReceiverBalances = await getBalancesForAddress(feeReceiver.address, tokens);
            const expectedBalanceDelta = initFeeReceiverBalances.map((val) => val.mul(toBN(-1)));

            await feeReceiver.withdrawFeesTo(
                tokens,
                new Array(tokens.length).fill(receiver),
                initFeeReceiverBalances
            );

            const finalBalances = await getBalancesForAddress(receiver, tokens);
            const finalFeeReceierBalances = await getBalancesForAddress(feeReceiver.address, tokens);

            checkBNDeltas(initBalances, finalBalances, initFeeReceiverBalances);
            checkBNDeltas(initFeeReceiverBalances, finalFeeReceierBalances, expectedBalanceDelta);
        })
    })

    /**
     * @param {String[]} tokens 
     * @param {BN[]} amounts 
     * @param {Boolean[]} flags
     */
    async function flashloan(tokens, amounts, flags) {
        return flashloanerMock.initiateFlashloan(
            weightedVault.address,
            tokens,
            amounts,
            flags[0],
            flags[1],
            flags[2]
        )
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
     * @param {String} tokenAddress 
     * @param {BN} amount 
     */
    async function getTokenAmountWithDecimals(tokenAddress, amount) {
        const tokenInstance = await ERC20Mock.at(tokenAddress);
        const decimals = toBN(await tokenInstance.decimals.call());
        return amount.mul(toBN(10).pow(decimals));
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
     * @param {BN[]} init 
     * @param {BN[]} finish 
     * @param {BN[]} delta 
     */
    function checkBNDeltas(init, finish, delta) {
        for (let id = 0; id < init.length; id++) {
            expect(finish[id]).to.eq.BN(init[id].add(delta[id]), "Invalid delta")
        }
    }
})