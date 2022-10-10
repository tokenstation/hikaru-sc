const { BigNumber } = require("ethers");
const { getDeadline, from, getSwapTypeId } = require("./utils");

/**
 * 
 * @param {import("../../typechain").DefaultRouter} router 
 * @param {import("../../typechain").WeightedVault} weightedVault
 * @param {import("../../typechain").WeightedPool} weightedPool
 * @param {import("ethers").BigNumberish[]} amounts
 * @param {String} provider
 * @param {Boolean} calculate
 * @returns {Promise<import("@ethersproject/providers").TransactionReceipt | BigNumber>}
 */
async function routerFullJoin(
    router,
    weightedVault,
    weightedPool,
    provider,
    amounts,
    calculate
) {
    if (calculate) {
        return await router.calculateFullJoin(
            weightedVault.address,
            weightedPool.address,
            amounts
        );
    }

    const txReceipt = await router.fullJoin(
        weightedVault.address,
        weightedPool.address,
        amounts,
        getDeadline(),
        from(provider)
    )
    return (await txReceipt.wait());
}

/**
 * @param {import("../../typechain").DefaultRouter} router
 * @param {import("../../typechain").WeightedVault} weightedVault 
 * @param {import("../../typechain").WeightedPool} weightedPool 
 * @param {String} provider 
 * @param {String[]} tokens 
 * @param {import("ethers").BigNumberish[]} amounts 
 * @param {Boolean} calculate 
 * @returns {Promise<import("@ethersproject/providers").TransactionReceipt | BigNumber>}
 */
async function routerPartialJoin(
    router,
    weightedVault,
    weightedPool,
    provider,
    tokens,
    amounts,
    calculate
) {
    if (calculate) {
        return await router.calculatePartialJoin(
            weightedVault,
            weightedPool,
            tokens,
            amounts
        );
    }
    const txReceipt = await router.partialJoin(
        weightedVault.address,
        weightedPool.address,
        tokens,
        amounts,
        getDeadline(),
        from(provider)
    )
    return (await txReceipt.wait());
}

/**
 * @param {import("../../typechain").DefaultRouter} router
 * @param {import("../../typechain").WeightedVault} weightedVault
 * @param {import("../../typechain").WeightedPool} weightedPool
 * @param {String} provider
 * @param {String} token
 * @param {import("ethers").BigNumberish} amount
 * @param {Boolean} calculate
 */
async function routerSingleTokenJoin(
    router,
    weightedVault,
    weightedPool,
    provider,
    token,
    amount,
    calculate
) {
    if (calculate) {
        return await router.calculateSingleTokenJoin(
            weightedVault.address,
            weightedPool.address,
            token,
            amount
        );
    }

    const txReceipt = await router.singleTokenJoin(
        weightedVault.address,
        weightedPool.address,
        token,
        amount,
        getDeadline(),
        from(provider)
    );

    return (await txReceipt.wait());
}

/**
 * @param {import("../../typechain").DefaultRouter} router
 * @param {import("../../typechain").WeightedVault} weightedVault
 * @param {String} swapper
 * @param {String} receiver
 * @param {import("../../typechain/contracts/Router/DefaultRouter").SwapRouteStruct} swapRoute
 * @param {import("./utils").SwapTypes} swapType
 * @param {import("ethers").BigNumberish} swapAmount 
 * @param {Boolean} calculate
 * @param {import("ethers").BigNumberish} minMaxAmount
 * @returns {Promise<import("ethers").BigNumberish | import("@ethersproject/providers").TransactionReceipt>}
 */
async function routerSwap(
    router,
    weightedVault,
    swapper,
    receiver,
    swapRoute,
    swapType,
    swapAmount,
    calculate,
    minMaxAmount
) {
    if (calculate) {
        return await router.calculateSwap(
            weightedVault.address,
            swapRoute,
            getSwapTypeId(swapType),
            swapAmount
        );
    }

    const txReceipt = await router.swap(
        weightedVault.address,
        swapRoute,
        getSwapTypeId(swapType),
        swapAmount,
        minMaxAmount,
        receiver,
        getDeadline(),
        from(swapper)
    );

    return (await txReceipt.wait());
}

/**
 * @param {import("../../typechain").DefaultRouter} router
 * @param {import("../../typechain").WeightedVault} weightedVault
 * @param {import("../../typechain").WeightedPool} weightedPool
 * @param {String} provider
 * @param {import("ethers").BigNumberish} lpAmount
 * @param {Boolean} calculate
 * @returns {Promise<import("ethers").BigNumberish|import("@ethersproject/providers").TransactionReceipt>}
 */
async function routerFullExit(
    router,
    weightedVault,
    weightedPool,
    provider,
    lpAmount,
    calculate
) {
    if (calculate) {
        return await router.calculateExit(
            weightedVault.address,
            weightedPool.address,
            lpAmount
        );
    }

    const txReceipt = await router.exit(
        weightedVault.address,
        weightedPool.address,
        lpAmount,
        getDeadline(),
        from(provider)
    );

    return (await txReceipt.wait());
}

/**
 * 
 * @param {import("../../typechain").DefaultRouter} router 
 * @param {import("../../typechain").WeightedVault} weightedVault 
 * @param {import("../../typechain").WeightedPool} weightedPool 
 * @param {String} provider 
 * @param {String} token 
 * @param {import("ethers").BigNumberish} lpAmount 
 * @param {Boolean} calculate 
 * @returns {Promise<import("ethers").BigNumberish|import("@ethersproject/providers").TransactionReceipt>}
 */
async function routerSingleTokenExit(
    router,
    weightedVault,
    weightedPool,
    provider,
    token,
    lpAmount,
    calculate
) {
    if (calculate) {
        return router.calculateSingleTokenExit(
            weightedVault.address,
            weightedPool.address,
            lpAmount,
            token
        );
    }

    const txReceipt = await router.singleTokenExit(
        weightedVault.address,
        weightedPool.address,
        lpAmount,
        token,
        getDeadline(),
        from(provider)
    );

    return (await txReceipt.wait());
}

module.exports = {
    routerFullJoin,
    routerPartialJoin,
    routerSingleTokenJoin,
    routerSwap,
    routerFullExit,
    routerSingleTokenExit
}