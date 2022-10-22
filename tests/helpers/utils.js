const { SignerWithAddress } = require('@nomiclabs/hardhat-ethers/signers');
const { Contract, BigNumber } = require('ethers');

/**
 * @param {import('../../typechain').ERC20Mock[]} tokens 
 * @param {String} to 
 * @param {SignerWithAddress} from
 */
 async function approveInfToAddress(tokens, to, from) {
    const inf = BigNumber.from(2).pow(256).sub(1);
    for (const token of tokens) {
        await token.connect(from).approve(to, inf)
    }
}

/**
 * 
 * @param {import('ethers').BigNumberish} tokenAmount 
 * @param {import('../../typechain').ERC20Mock[]} tokens 
 * @param {String?} to
 * @param {Number[]?} skip
 */
async function generateEqualTokenAmounts(tokenAmount, tokens, to='', skip=[]) {
    const tokenAmounts = [];

    for (const [id, token] of tokens.entries()) {
        if (skip.indexOf(id) < 0) {
            const decimals = await token.decimals();
            tokenAmounts.push(
                BigNumber.from(10).pow(decimals).mul(tokenAmount)
            );
        }
        if (to) {
            token.mint(to, tokenAmounts[tokenAmounts.length-1])
        }
    }

    return tokenAmounts;
}

/**
 * 
 * @param {import('../../typechain').ERC20Mock} token 
 * @param {import('ethers').BigNumberish} amount 
 * @param {String} to 
 */
async function mintTokensTo(token, amount, to) {
    await token.mint(to, amount);
}

/**
 * @template T
 * @param {T[]} array
 * @returns {T[]}
 */
function sortContractsByAddress(array) {
    return array.sort((a, b) => a.address.toLowerCase() < b.address.toLowerCase() ? -1 : 1);
}

/**
 * @returns {Number}
 */
function getDeadline() {
    return Math.floor((+ new Date())/1000) + 10000;
}

/**
 * @param {String} signer 
 * @returns 
 */
function from(signer) {
    return {
        from: signer
    }
}

/**
 * @typedef {"Buy" | "Sell"} SwapTypes
 */

/** 
 * @param {SwapTypes} swapType
 * @returns {Number}
 */
function getSwapTypeId(swapType) {
    if (swapType.toLowerCase() == 'sell') return 0;
    if (swapType.toLowerCase() == 'buy') return 1;
    throw new Error('Unknown swap type');
}

/**
 * 
 * @param {import('../../typechain').WeightedVault} weightedVault 
 * @param {import('../../typechain').ERC20Mock[]} tokens 
 * @returns {Promise<import('ethers').BigNumberish[]>}
 */
async function getProtocolFees(
    weightedVault,
    tokens
) {
    const protocolFees = [];
    for (const token of tokens) {
        protocolFees.push(
            await weightedVault.collectedFees(token.address)
        )
    }
    return protocolFees;
}


module.exports = {
    sortContractsByAddress,
    generateEqualTokenAmounts,
    approveInfToAddress,
    getDeadline,
    from,
    getSwapTypeId,
    getProtocolFees,
    mintTokensTo
}