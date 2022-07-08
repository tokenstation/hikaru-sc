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

        it('Change factory address as random user', async() => {
            await expectRevert.unspecified(
                weightedVault.setFactoryAddress(weightedVault.address, from(randomUser)),
                "Only manager can execute this function."
            );
        })
        it('Change factory address', async() => {
            // Factory address is already set in migrations so this will fail
            await expectRevert.unspecified(
                weightedVault.setFactoryAddress(weightedVault.address, from(admin)),
                'HIKARU#501'
            )
            // expectEvent(tx, 'FactoryAddressUpdate', {newFactoryAddress: weightedVault.address});
        })

        it('Change flashloan fees as random user', async() => {
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

        it('Change flashloan fee receiver as random user', async() => {
            await expectRevert.unspecified(
                weightedVault.setFeeReceiver(randomUser, from(randomUser)),
                "Only manager can execute this function."
            )
        })
        it('Change flashloan fee receiver', async() => {
            const tx = await weightedVault.setFeeReceiver(randomUser, from(admin));
            expectEvent(tx, 'FeeReceiverUpdate', {newFeeReceiver: randomUser});
        })

        it('Change protocol fee as random user', async() => {
            const protocolFee = toBN(await weightedVault.protocolFee.call()).add(toBN(1));
            await expectRevert.unspecified(
                weightedVault.setProtocolFee(protocolFee, from(randomUser))
            );
        })
        it('Change protocol fee', async() => {
            const protocolFee = toBN(await weightedVault.protocolFee.call()).add(toBN(1));
            const tx = await weightedVault.setProtocolFee(protocolFee, from(admin));
            expectEvent(tx, 'ProtocolFeeUpdate', {newProtocolFee: protocolFee});
        })

        it('Try to register pool as random user', async() => {
            await expectRevert.unspecified(
                weightedVault.registerPool(randomUser, [randomUser], from(randomUser)),
                "Only manager can execute this function."
            )
        })

        it('Withdraw collected fees as random user', async() => {
            const tokens = [accounts[3], accounts[4]];
            const amounts = [toBN(100), toBN(100)];
            const to = [randomUser, randomUser];
            await expectRevert.unspecified(
                weightedVault.withdrawCollectedFees(
                    tokens,
                    amounts,
                    to,
                    from(randomUser)
                )
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