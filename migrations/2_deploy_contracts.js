
const MoleculeToken = artifacts.require("./MoleculeToken.sol");
const BigNumber = require('bignumber.js')

BigNumber.config({
  EXPONENTIAL_AT: 100
})

module.exports = async (deployer) => {
  await deployer.deploy(MoleculeToken, {gas: 5000000});
};