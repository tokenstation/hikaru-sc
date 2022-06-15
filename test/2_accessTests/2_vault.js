// What we need to check:
// WeightedVault:
// 1. setFactoryAddress 
// 2. setFlashloanFees
// 3. setFeeReceiver
// 4. registerPool

const { expectRevert, expectEvent } = require("@openzeppelin/test-helpers");
const { toBN } = require("web3-utils");

const WeightedVault = artifacts.require('WeightedVault');

contract('WeightedVault', async(accounts) => {
    let weightedVault;
    before(async() => {
        weightedVault = await WeightedVault.deployed();
    }) 


    describe('Test access to setters', async() => {
        const admin = accounts[0];
        const randomUser = accounts[1];

        it('Change factory address from random user', async() => {
            await expectRevert.unspecified(
                weightedVault.setFactoryAddress(weightedVault.address, from(randomUser)),
                "Only manager can execute this function."
            );
        })
        it('Change factory address', async() => {
            const tx = await weightedVault.setFactoryAddress(weightedVault.address, from(admin));
            expectEvent(tx, 'FactoryAddressUpdate', {newFactoryAddress: weightedVault.address});
        })

        it('Change flashloan fees from random user', async() => {
            const flashloanFees = toBN(await weightedVault.flashloanFee.call()).add(toBN(1));
            await expectRevert.unspecified(
                weightedVault.setFlashloanFees(flashloanFees, from(randomUser)),
                "Only manager can execute this function."
            )
        })
        it('Change flashloan fees', async() => {
            const flashloanFees = toBN(await weightedVault.flashloanFee.call()).add(toBN(1));
            const tx = await weightedVault.setFlashloanFees(flashloanFees, from(admin));
            expectEvent(tx, 'FlashloanFeesUpdate', {newFlashloanFees: flashloanFees});
        })

        it('Change flashloan fee receiver from random user', async() => {
            await expectRevert.unspecified(
                weightedVault.setFeeReceiver(randomUser, from(randomUser)),
                "Only manager can execute this function."
            )
        })
        it('Change flashloan fee receiver', async() => {
            const tx = await weightedVault.setFeeReceiver(randomUser, from(admin));
            expectEvent(tx, 'FeeReceiverUpdate', {newFeeReceiver: randomUser});
        })

        it('Try to register pool from random user', async() => {
            await expectRevert.unspecified(
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