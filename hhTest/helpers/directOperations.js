const { SignerWithAddress } = require('@nomiclabs/hardhat-ethers/signers');
const { BigNumber } = require('ethers');
const { sortContractsByAddress, getDeadline, getSwapTypeId } = require('./utils');

const JoinTypes = {
    SingleToken: 'SingleToken',
    PartialJoin: 'PartialJoin',
    FullJoin: 'FullJoin'
}

/**
 * @param {import('../../typechain').WeightedVault} weightedVault
 * @param {import('../../typechain').WeightedPool} weightedPool
 * @param {import('../../typechain').ERC20Mock[]} tokens
 * @param {SignerWithAddress} provider
 * @param {String} receiver
 * @param {import('ethers').BigNumberish[]} amounts
 * @returns {Promise<import('@ethersproject/providers').TransactionReceipt>}
 */
async function provide(
    weightedVault,
    weightedPool,
    tokens,
    provider,
    receiver,
    amounts
) {

    let joinType = undefined;
    
    const tokenIds = [];
    /**@type {Record<String, import('ethers').BigNumberish>} */
    const tmpSortHashMap = {};
    const sortedTokens = sortContractsByAddress(tokens);
    for (const [id, token] of sortedTokens.entries()) {
        tokenIds.push(
            await weightedPool.getTokenId(token.address)
        );
        tmpSortHashMap[token.address] = amounts[id];
    }
    tokenIds.sort();

    /**@type {BigNumber[]} */
    const joinAmounts = new Array(tokens.length).fill(0);
    for (const [k, v] of Object.entries(tmpSortHashMap)) {
        const tokenId = sortedTokens.findIndex((val) => val.address == k)
        joinAmounts[tokenId] = BigNumber.from(v);
    }

    if (tokenIds.length == 1) {
        joinType = JoinTypes.SingleToken
    } else {
        let flag = true;
        for(const [id, val] of tokenIds.entries()) {
            flag = flag && val.eq(id);
        }
        joinType = flag ? JoinTypes.FullJoin : JoinTypes.PartialJoin;
    }   

    /**@type {import('@ethersproject/providers').TransactionResponse} */
    let txReceipt = undefined;

    if (joinType == JoinTypes.SingleToken) {
        txReceipt = await weightedVault.connect(provider).singleTokenPoolJoin(
            weightedPool.address,
            sortedTokens[0].address,
            joinAmounts[0],
            receiver,
            getDeadline()
        )
    }

    if (joinType == JoinTypes.PartialJoin) {
        txReceipt = await weightedVault.connect(provider).partialPoolJoin(
            weightedPool.address,
            sortedTokens.map((val) => val.address),
            joinAmounts,
            receiver,
            getDeadline()
        )
    }

    if (joinType == JoinTypes.FullJoin) {
        txReceipt = await weightedVault.connect(provider).joinPool(
            weightedPool.address,
            joinAmounts,
            receiver,
            getDeadline()
        )
    }

    if (!txReceipt) throw new Error(`Unknown provide type: ${joinType} or unable to join pool`);

    return (await txReceipt.wait());
}


/**
 * 
 * @param {import('../../typechain').WeightedVault} weightedVault 
 * @param {import('../../typechain').WeightedPool} weightedPool 
 * @param {SignerWithAddress} withdrawer 
 * @param {String} receiver 
 * @param {import('ethers').BigNumberish} lpAmount
 * @param {Boolean} singleToken 
 * @param {String?} token 
 * @returns {Promise<import('@ethersproject/providers').TransactionReceipt>}
 */
async function withdraw(
    weightedVault,
    weightedPool,
    withdrawer,
    receiver,
    lpAmount,
    singleTokenExit,
    token
) {
    /**@type {import('@ethersproject/providers').TransactionResponse} */
    let txReceipt = undefined;
    if (singleTokenExit) {
        await weightedPool.getTokenId(token);
        txReceipt = await weightedVault.connect(withdrawer).exitPoolSingleToken(
            weightedPool.address,
            lpAmount,
            token,
            receiver,
            getDeadline()
        );
    } else {
        txReceipt = await weightedVault.connect(withdrawer).exitPool(
            weightedPool.address,
            lpAmount,
            receiver,
            getDeadline()
        );
    }
    return (await txReceipt.wait());
}

/**
 * @param {import('../../typechain').WeightedVault} weightedVault
 * @param {import('../../typechain/contracts/Vaults/interfaces/ISwap').SwapRouteStruct} swapRoute 
 * @param {import('./utils').SwapTypes} swapType
 * @param {import('ethers').BigNumberish} swapAmount
 * @param {import('ethers').BigNumberish} minMaxAmount
 * @param {SignerWithAddress} swapper
 * @param {String} receiver
 * @returns {Promise<import('@ethersproject/providers').TransactionReceipt>}
 */
async function swap(
    weightedVault,
    swapRoute,
    swapType,
    swapAmount,
    minMaxAmount,
    swapper,
    receiver
) {
    let txReceipt = await weightedVault.connect(swapper).swap(
        swapRoute,
        getSwapTypeId(swapType),
        swapAmount,
        minMaxAmount,
        receiver,
        getDeadline()
    )

    return (await txReceipt.wait());
}

module.exports = {
    provide,
    withdraw,
    swap
}