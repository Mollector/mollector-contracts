const { time } = require('@openzeppelin/test-helpers')
const truffleAssert = require('truffle-assertions');
const MoleculeToken = artifacts.require('../contracts/MoleculeToken.sol');
const TokenVesting = artifacts.require('../contracts/TokenVesting.sol');
var $ = {}
contract("TokenVesting", ([owner, bob, tom, alice, noShare]) => {
  describe('#setup()', () => {
    it('correct vesting vesting and lock', async () => {

      var token = await MoleculeToken.new({ from: owner })
      var vesting = await TokenVesting.new(0);
      var TGE =  Math.round(new Date().getTime() / 1000) + 5
      await vesting.init(token.address, TGE, 10, 100)

      await token.mint(owner, 2000000000000000)
    
      await vesting.addMultiBeneficiaries([bob, tom, alice], [20000000000, 10000000000, 10000000000], [10000000000000, 10000000000000, 10000000000000]);

      var tLock = await vesting.totalLockAmount()
      var tVesting = await vesting.totalVestingAmount()

      console.log(tLock.toNumber(), tVesting.toNumber())
      await token.transfer(vesting.address, tLock.toNumber() + tVesting.toNumber())
      console.log('Vesting balance', (await token.balanceOf(vesting.address)).toNumber())

      await truffleAssert.fails(
        vesting.unlock({ from: bob }),
        truffleAssert.ErrorType.REVERT,
        "Cannot unlock right now, please wait!"
      )

      console.log('start wait')
      await new Promise((resolve) => setTimeout(resolve, 6000))

      $.latestBlock = (await time.latestBlock()).toNumber()
      console.log('current block', $.latestBlock)
      await time.advanceBlockTo($.latestBlock + 1)
      

      console.log((await vesting.start()).toNumber(), (await vesting.TGE()).toNumber(), Math.round(new Date().getTime() / 1000))
      await vesting.unlock({ from: bob })


      await truffleAssert.fails(
        vesting.unlock({ from: bob }),
        truffleAssert.ErrorType.REVERT,
        "You cannot unlock"
      )


      truffleAssert.fails(
        vesting.unlock({ from: noShare }),
        truffleAssert.ErrorType.REVERT,
        "You cannot unlock"
      )

      console.log('tom balance', (await token.balanceOf(tom)).toNumber())
      console.log('bob balance', (await token.balanceOf(bob)).toNumber())
      console.log('alice balance', (await token.balanceOf(alice)).toNumber())
      console.log('Vesting balance', (await token.balanceOf(vesting.address)).toNumber())
      
      var tomUnlock = false
      while(new Date().getTime() < TGE * 1000 + 200 * 1000) {
        await new Promise((resolve) => setTimeout(resolve, 1000))
        console.log((await vesting.start()).toNumber() + (await vesting.duration()).toNumber() - Math.round(new Date().getTime() / 1000))
        console.log(100 - ((await vesting.start()).toNumber() + (await vesting.duration()).toNumber() - Math.round(new Date().getTime() / 1000)))
        console.log((await vesting.cliff()).toNumber() - Math.round(new Date().getTime() / 1000))

        $.latestBlock = (await time.latestBlock()).toNumber()
        await time.advanceBlockTo($.latestBlock + 1)

        console.log()
        console.log('bob', (await vesting.calculateReleaseAmount(bob)).toNumber())
        console.log('bob balance 1', (await token.balanceOf(bob)).toNumber())
        if ((await vesting.calculateReleaseAmount(bob)).toNumber() > 0) {
          await vesting.release({from: bob})
        }
        console.log('bob balance 2', (await token.balanceOf(bob)).toNumber())


        console.log()
        console.log('tom', (await vesting.calculateReleaseAmount(tom)).toNumber())
        console.log('tom balance 1', (await token.balanceOf(tom)).toNumber())
        if (!tomUnlock && (await vesting.cliff()).toNumber() - Math.round(new Date().getTime() / 1000) < 0) {
          await vesting.unlock({ from: tom })
          tomUnlock = true
        }
        if (((await vesting.start()).toNumber() + (await vesting.duration()).toNumber() - Math.round(new Date().getTime() / 1000)) % 5 == 0) {
          if ((await vesting.calculateReleaseAmount(tom)).toNumber() > 0) {
            await vesting.release({from: tom})
          }
        }
        console.log('tom balance 1', (await token.balanceOf(tom)).toNumber())

        console.log()
        console.log('alice', (await vesting.calculateReleaseAmount(alice)).toNumber())
        console.log('alice balance 1', (await token.balanceOf(alice)).toNumber())
        if ((await vesting.start()).toNumber() + (await vesting.duration()).toNumber() - Math.round(new Date().getTime() / 1000) < 0) {
          if ((await vesting.calculateReleaseAmount(alice)).toNumber() > 0) {
            await vesting.unlockAndRelease({from: alice})
          }
        }
        console.log('alice balance 1', (await token.balanceOf(alice)).toNumber())
      }

      console.log('tom balance', (await token.balanceOf(tom)).toNumber())
      console.log('bob balance', (await token.balanceOf(bob)).toNumber())
      console.log('alice balance', (await token.balanceOf(alice)).toNumber())
      console.log('Vesting balance', (await token.balanceOf(vesting.address)).toNumber())

      assert.equal(await token.balanceOf(bob), 20000000000 + 500000000000)
      assert.equal(await token.balanceOf(tom), 10000000000 + 200000000000)
      assert.equal(await token.balanceOf(alice), 10000000000 + 300000000000)
    });
  });
});
