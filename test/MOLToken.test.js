/* libraries used */
const truffleAssert = require('truffle-assertions');
/* Contracts in this test */
const MOLToken = artifacts.require('../contracts/MOLToken.sol');

contract("CyBlocCore", ([owner]) => {
  
  before(async () => {
    token = await MOLToken.new({ from: owner })
  });

  describe('#constructor()', () => {
    it('should set the token name, symbol, and URI', async () => {
      const symbol = await cyblocCore.symbol();
      assert.equal(symbol, 'MOL');
    });
  });
});
