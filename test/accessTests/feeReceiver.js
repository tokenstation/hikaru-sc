// What we need to check:
// FeeReceiver:
// 1. withdrawFeesTo

const { expectRevert } = require("@openzeppelin/test-helpers");
const { toBN } = require("web3-utils");

const FeeReceiver = artifacts.require('FeeReceiver')

contract('FeeReceiver', async(accounts) => {
    let feeReceiver;

    before(async() => {
        feeReceiver = await FeeReceiver.deployed();
    })

    describe('Try to access token withdraw function', async() => {
        it('Trying to access', async() => {
            let randomUser = accounts[1];

            await expectRevert(
                feeReceiver.withdrawFeesTo([randomUser], [randomUser], [toBN(1e18)], from(randomUser)),
                "Only manager can execute this function."
            );
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