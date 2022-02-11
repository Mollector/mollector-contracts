
const MOLToken = artifacts.require("./MOLToken.sol");
const BigNumber = require('bignumber.js')

BigNumber.config({
  EXPONENTIAL_AT: 100
})

module.exports = async (deployer) => {
  await deployer.deploy(MOLToken, {gas: 5000000});
};