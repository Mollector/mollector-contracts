const MOLToken = artifacts.require('../contracts/MOLToken.sol');

contract("CyBlocCore", ([owner, bob, tom]) => {
  
  before(async () => {
    token = await MOLToken.new({ from: owner })
  });

  describe('#constructor()', () => {
    it('should set the token name, symbol, and URI', async () => {
      const symbol = await token.symbol();
      assert.equal(symbol, 'MOL');

      await token.mint(bob, 100, { from: owner })

      var balance = await token.balanceOf(bob)

      assert.equal(balance.toNumber(), 100)

      try {
        await token.mint(bob, 100, { from: bob })
        assert.equal(1, 0)
      }
      catch (ex) {
      }

      await token.transfer(tom, 50, { from: bob })

      balance = await token.balanceOf(tom)
      assert.equal(balance.toNumber(), 50)

      await token.pause()

      try {
        await token.transfer(tom, 10, { from: bob })
        assert.equal(1, 0)
      }
      catch (ex) {}

      await token.unPause()

      await token.transfer(tom, 10, { from: bob })
      balance = await token.balanceOf(tom)
      assert.equal(balance.toNumber(), 60)
    });
  });
});
