const { time } = require('@openzeppelin/test-helpers')
const truffleAssert = require('truffle-assertions');
const MoleculeToken = artifacts.require('../contracts/MoleculeToken.sol');
const TokenVesting = artifacts.require('../contracts/TokenVesting.sol');
var $ = {}
contract("TokenVesting", ([owner, bob, tom, alice, noShare]) => {
  
  before(async () => {
    $.latestBlock = (await time.latestBlock()).toNumber()
    token = await MoleculeToken.new({ from: owner })
    vesting = await TokenVesting.new(token.address, $.latestBlock, 10, 100);
  });

  describe('#setup()', () => {
    it('correct balance', async () => {
      await token.mint(owner, 1000000)
      assert.equal(await token.balanceOf(owner), 1000000)

      await vesting.addBeneficiary(bob, 500000)
      assert.equal(await vesting.shares(bob), 500000)
      await vesting.addBeneficiary(bob, 100000)
      assert.equal(await vesting.shares(bob), 600000)

      assert.equal(await vesting.beneficiaries(0), bob)

      await vesting.addBeneficiary(tom, 200000)

      assert.equal(await vesting.totalShare(), 800000)
      assert.equal(await vesting.beneficiaries(1), tom)
      assert.equal(await vesting.shares(tom), 200000)
      assert.equal(await vesting.totalBeneficiaries(), 2)
      assert.equal(await vesting.totalReleased(), 0)
      assert.equal(await vesting.released(bob), 0)
      assert.equal(await vesting.released(tom), 0)
      assert.equal(await vesting.cliff(), $.latestBlock + 10)
      assert.equal(await vesting.duration(), 100)

      await vesting.addMultiBeneficiaries([tom, alice], [200000, 100000])
      assert.equal(await vesting.totalShare(), 1100000)
      
      await token.mint(vesting.address, 1100000)

      assert.equal((await token.balanceOf(vesting.address)).toString(), (await vesting.totalShare()).toString())

      assert.equal(await vesting.calculateReleaseAmount(bob), 0)
      assert.equal(await vesting.calculateReleaseAmount(tom), 0)
      assert.equal(await vesting.calculateReleaseAmount(alice), 0)
      assert.equal(await vesting.calculateReleaseAmount(noShare), 0)
      assert.equal(await vesting.totalBeneficiaries(), 3)

      await truffleAssert.fails(
        vesting.release({ from: tom }),
        truffleAssert.ErrorType.REVERT,
        "Have not start or finished"
      )

      await truffleAssert.fails(
        vesting.release({ from: noShare }),
        truffleAssert.ErrorType.REVERT,
        "You dont have share"
      )

      await time.advanceBlockTo($.latestBlock + 10)

      assert.equal(await vesting.calculateReleaseAmount(bob), 60000)
      assert.equal(await vesting.calculateReleaseAmount(tom), 40000)

      await truffleAssert.passes(
        vesting.release({ from: bob })
      ) // block 11

      assert.equal(await token.balanceOf(bob), 66000)

      assert.equal(await vesting.calculateReleaseAmount(bob), 0)
      assert.equal(await vesting.calculateReleaseAmount(tom), 44000)

      assert.equal(await vesting.released(bob), 66000)
      assert.equal(await vesting.released(tom), 0)

      await truffleAssert.fails(
        vesting.release({ from: noShare }),
        truffleAssert.ErrorType.REVERT,
        "You dont have share"
      ) // block 12

      await time.advanceBlockTo($.latestBlock + 10 + 3) // 13

      assert.equal(await vesting.calculateReleaseAmount(bob), 12000)
      assert.equal(await vesting.calculateReleaseAmount(tom), 52000)

      await truffleAssert.passes(
        vesting.release({ from: bob })
      ) // block 14

      assert.equal(await token.balanceOf(bob), 84000)

      assert.equal(await vesting.calculateReleaseAmount(bob), 0)
      assert.equal(await vesting.calculateReleaseAmount(tom), 56000)
      assert.equal(await vesting.calculateReleaseAmount(alice), 14000)

      assert.equal(await vesting.released(bob), 84000)
      assert.equal(await vesting.released(tom), 0)
      assert.equal(await vesting.released(alice), 0)

      await time.advanceBlockTo($.latestBlock + 50) // 50

      assert.equal(await vesting.calculateReleaseAmount(bob), 216000)
      assert.equal(await vesting.calculateReleaseAmount(tom), 200000)
      assert.equal(await vesting.calculateReleaseAmount(alice), 50000)

      await truffleAssert.passes(
        vesting.release({ from: bob })
      ) // block 51

      await truffleAssert.passes(
        vesting.release({ from: tom })
      ) // block 52

      assert.equal(await vesting.released(bob), 306000)
      assert.equal(await vesting.released(tom), 208000)
      assert.equal(await vesting.released(alice), 0)

      assert.equal(await token.balanceOf(bob), 306000)
      assert.equal(await token.balanceOf(tom), 208000)

      assert.equal(await vesting.calculateReleaseAmount(bob), 6000)
      assert.equal(await vesting.calculateReleaseAmount(tom), 0)
      assert.equal(await vesting.calculateReleaseAmount(alice), 52000)

      await truffleAssert.fails(
        vesting.releaseFor(alice, { from: noShare}),
        truffleAssert.ErrorType.REVERT,
        "Ownable: caller is not the owner"
      )

      await time.advanceBlockTo($.latestBlock + 101)

      assert.equal(await vesting.calculateReleaseAmount(bob), 294000)
      assert.equal(await vesting.calculateReleaseAmount(tom), 192000)
      assert.equal(await vesting.calculateReleaseAmount(alice), 100000)

      await truffleAssert.passes(
        vesting.release({ from: bob })
      )

      await truffleAssert.passes(
        vesting.release({ from: tom })
      )

      await truffleAssert.passes(
        vesting.releaseFor(alice)
      )

      assert.equal(await vesting.released(bob), 600000)
      assert.equal(await vesting.released(tom), 400000)
      assert.equal(await vesting.released(alice), 100000)

      assert.equal(await vesting.calculateReleaseAmount(bob), 0)
      assert.equal(await vesting.calculateReleaseAmount(tom), 0)
      assert.equal(await vesting.calculateReleaseAmount(alice), 0)

      assert.equal(await token.balanceOf(bob), 600000)
      assert.equal(await token.balanceOf(tom), 400000)
      assert.equal(await token.balanceOf(alice), 100000)

      await truffleAssert.fails(
        vesting.release({ from: bob }),
        truffleAssert.ErrorType.REVERT,
        "Cannot release more"
      )

      await truffleAssert.fails(
        vesting.release({ from: tom }),
        truffleAssert.ErrorType.REVERT,
        "Cannot release more"
      )

      await truffleAssert.fails(
        vesting.release({ from: alice }),
        truffleAssert.ErrorType.REVERT,
        "Cannot release more"
      )

      await token.mint(vesting.address, 1234567)
      assert.equal(await token.balanceOf(vesting.address), 1234567)

      await truffleAssert.fails(
        vesting.withdraw(token.address, noShare),
        truffleAssert.ErrorType.REVERT,
        "Cannot withdraw"
      )

      await truffleAssert.fails(
        vesting.requestWithdraw({ from: noShare }),
        truffleAssert.ErrorType.REVERT,
        "Ownable: caller is not the owner"
      )

      await truffleAssert.fails(
        vesting.addBeneficiary(noShare, 100000, { from: noShare }),
        truffleAssert.ErrorType.REVERT,
        "Ownable: caller is not the owner"
      )

      await vesting.requestWithdraw()

      await truffleAssert.fails(
        vesting.withdraw(token.address, noShare, { from: noShare }),
        truffleAssert.ErrorType.REVERT,
        "Ownable: caller is not the owner"
      )

      await truffleAssert.fails(
        vesting.withdraw(token.address, noShare),
        truffleAssert.ErrorType.REVERT,
        "Cannot withdraw"
      )

      await new Promise((resolve) => setTimeout(resolve, 30000))

      await truffleAssert.fails(
        vesting.withdraw(token.address, noShare, { from: noShare }),
        truffleAssert.ErrorType.REVERT,
        "Ownable: caller is not the owner"
      )

      await vesting.withdraw(token.address, noShare)
      assert.equal(await token.balanceOf(noShare), 1234567)
      
    });
  });
});
