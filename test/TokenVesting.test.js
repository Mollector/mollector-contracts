const { time } = require('@openzeppelin/test-helpers')
const truffleAssert = require('truffle-assertions');
const MoleculeToken = artifacts.require('../contracts/MoleculeToken.sol');
const TokenVesting = artifacts.require('../contracts/TokenVesting.sol');
var $ = {}
contract("TokenVesting", ([owner, bob, tom, alice, noShare]) => {
  describe('#setup()', () => {
    it('correct vesting vesting and lock', async () => {

      token = await MoleculeToken.new({ from: owner })
      vesting = await TokenVesting.new(0);
      await vesting.init(token.address, Math.round(new Date().getTime() / 1000) + 30, 100, 200)

      await token.mint(owner, 2000000000000000)
      

      await vesting.addMultiBeneficiaries([bob, tom, alice], [20000000000, 10000000000, 10000000000], [500000000000, 200000000000, 300000000000]);

      var tLock = await vesting.totalLockAmount()
      var tVesting = await vesting.totalVestingAmount()


      await token.transfer(vesting.address, tLock.plus(tVesting).toString())

      truffleAssert.fails(
        vesting.unlock({ from: bob }),
        truffleAssert.ErrorType.REVERT,
        "Cannot unlock right now, please wait!"
      )

      await new Promise((resolve) => setTimeout(resolve, 30000))
      
      await vesting.unlock({ from: bob })
      await vesting.unlock({ from: tom })

      truffleAssert.fails(
        vesting.unlock({ from: bob }),
        truffleAssert.ErrorType.REVERT,
        "You cannot unlock"
      )

      truffleAssert.fails(
        vesting.unlock({ from: noShare }),
        truffleAssert.ErrorType.REVERT,
        "You cannot unlock"
      )


      $.latestBlock = (await time.latestBlock()).toNumber()
      setInterval(async () => {
        await time.advanceBlockTo($.latestBlock + 1)
        $.latestBlock = $.latestBlock + 1
      }, 1000)

      setInterval(() => {
        console.log('bob', (await vesting.calculateReleaseAmount(bob)).toNumber())
        console.log('bob balance 1', (await token.balanceOf(bob).toNumber()))
        if ((await vesting.calculateReleaseAmount(bob)).toNumber() > 0) {
          await vesting.release({from: bob})
        }
        console.log('bob balance 2', (await token.balanceOf(bob).toNumber()))
      }, 5000)

      setInterval(() => {
        console.log('tom', (await vesting.calculateReleaseAmount(tom)).toNumber())
        console.log('tom balance 1', (await token.balanceOf(tom).toNumber()))
        if ((await vesting.calculateReleaseAmount(tom)).toNumber() > 0) {
          await vesting.release({from: tom})
        }
        console.log('tom balance 1', (await token.balanceOf(tom).toNumber()))
      }, 10000)

      setInterval(() => {
        console.log('alice', (await vesting.calculateReleaseAmount(alice)).toNumber())
        console.log('alice balance 1', (await token.balanceOf(alice).toNumber()))
        if ((await vesting.calculateReleaseAmount(alice)).toNumber() > 0) {
          await vesting.release({from: alice})
        }
        console.log('alice balance 1', (await token.balanceOf(alice).toNumber()))
      }, 20000)

      // assert.equal(await token.balanceOf(bob), 20000000000 + 500000000000)
      // assert.equal(await token.balanceOf(tom), 10000000000 + 200000000000)
      // assert.equal(await token.balanceOf(alice), 10000000000 + 300000000000)
    });
  });
});
