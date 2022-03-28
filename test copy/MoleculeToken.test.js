const MoleculeToken = artifacts.require('../contracts/MoleculeToken.sol');

contract("MolToken", ([owner, bob, tom]) => {
  
  before(async () => {
    token = await MoleculeToken.new({ from: owner })
  });

  describe('#constructor()', () => {
    it('should set the token name, symbol, and URI', async () => {
      const symbol = await token.symbol();
      assert.equal(symbol, 'MOL');

      await token.mint(bob, 100, { from: owner })

      var balance = await token.balanceOf(bob)

      assert.equal(balance.toNumber(), 100)

      var pass = true
      try {
        await token.mint(bob, 100, { from: bob })
        pass = false
      }
      catch (ex) {
        pass = true
      }
      assert.equal(pass, true)

      await token.transfer(tom, 50, { from: bob })

      balance = await token.balanceOf(tom)
      assert.equal(balance.toNumber(), 50)

      await token.pause()

      try {
        await token.transfer(tom, 10, { from: bob })
        pass = false
      }
      catch (ex) {
        pass = true
      }
      assert.equal(pass, true)

      await token.unPause()

      await token.transfer(tom, 10, { from: bob })
      balance = await token.balanceOf(tom)
      assert.equal(balance.toNumber(), 60)

      try {
        await token.mint(tom, await token.cap(), { from: owner })
        pass = false
      }
      catch (ex) {
        pass = true
      }
      assert.equal(pass, true)
    });
  });
});
