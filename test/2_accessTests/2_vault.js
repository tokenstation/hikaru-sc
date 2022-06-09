// What we need to check:
// WeightedVault:
// 1. setFactoryAddress 
// 2. setFlashloanFees
// 3. setFeeReceiver
// 4. registerPool

const { expectRevert } = require("@openzeppelin/test-helpers");
const { toBN } = require("web3-utils");

const WeightedVault = artifacts.require('WeightedVault');

contract('WeightedVault', async(accounts) => {
    let weightedVault;
    before(async() => {
        weightedVault = await WeightedVault.deployed();
    }) 


    describe('Test access to setters', async() => {
        const randomUser = accounts[1];

        it('Change factory address', async() => {
            await expectRevert(
                weightedVault.setFactoryAddress(weightedVault.address, from(randomUser)),
                "Only manager can execute this function."
            );
        })

        it('Change flashloan fees', async() => {
            const flashloanFees = toBN(await weightedVault.flashloanFee.call()).add(toBN(1));
            await expectRevert(
                weightedVault.setFlashloanFees(flashloanFees, from(randomUser)),
                "Only manager can execute this function."
            )
        })

        it('Change flashloan fee receiver', async() => {
            await expectRevert(
                weightedVault.setFeeReceiver(randomUser, from(randomUser)),
                "Only manager can execute this function."
            )
        })

        it('Try to register pool', async() => {
            await expectRevert(
                weightedVault.registerPool(randomUser, [randomUser], from(randomUser)),
                "Only manager can execute this function."
            )
        })
    })
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