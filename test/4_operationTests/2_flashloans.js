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

const ERC20Mock = artifacts.require('ERC20Mock');
const FlashloanerMock = artifacts.require('FlashloanerMock');

contract('WeightedVault', async(accounts) => {
    let weightedVault;
    let flashloanerMock;

    before(async() => {
        weightedVault = await WeightedVault.deployed();
        flashloanerMock = await FlashloanerMock.new();
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
            await flashloan(
                tokens,
                flashloanAmounts,
                flags
            );
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

    /**
     * 
     * @param {String[]} tokens 
     * @param {BN[]} amounts 
     * @param {Boolean[]} flags 
     * 
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
})