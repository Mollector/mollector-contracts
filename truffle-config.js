const HDWalletProvider = require("truffle-hdwallet-provider");

const MNEMONIC = "";
const NODE_API_KEY = "d81b764e1175473ab36844831dc02fa0" || process.env.ALCHEMY_KEY;
const isInfura = 1;

const needsNodeAPI =
  process.env.npm_config_argv &&
  (process.env.npm_config_argv.includes("rinkeby") ||
    process.env.npm_config_argv.includes("live"));

if ((!MNEMONIC || !NODE_API_KEY) && needsNodeAPI) {
  console.error("Please set a mnemonic and ALCHEMY_KEY or INFURA_KEY.");
  process.exit(0);
}

const rinkebyNodeUrl = isInfura
  ? "https://rinkeby.infura.io/v3/" + NODE_API_KEY
  : "https://eth-rinkeby.alchemyapi.io/v2/" + NODE_API_KEY;

const mainnetNodeUrl = isInfura
  ? "https://mainnet.infura.io/v3/" + NODE_API_KEY
  : "https://eth-mainnet.alchemyapi.io/v2/" + NODE_API_KEY;

const bscNodeUrl = 'https://data-seed-prebsc-1-s1.binance.org:8545';
const tomoNodeUrl = 'https://rpc.testnet.tomochain.com';

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      gas: 5000000,
      network_id: "*", // Match any network id
    },
    rinkeby: {
      provider: function () {
        return new HDWalletProvider(MNEMONIC, rinkebyNodeUrl);
      },
      gas: 5000000,
      network_id: 4,
    },
    live: {
      network_id: 1,
      provider: function () {
        return new HDWalletProvider(MNEMONIC, mainnetNodeUrl);
      },
      gas: 5000000,
      gasPrice: 5000000000,
    },
    bsc_test: {
      network_id: 97,
      provider: function () {
        return new HDWalletProvider(MNEMONIC, bscNodeUrl);
      },
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },   
    bsc: {
      network_id: 56,
      provider: function () {
        return new HDWalletProvider(MNEMONIC, bscNodeUrl);
      },
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },      
    tomo_test: {
      network_id: 89,
      provider: function () {
        return new HDWalletProvider(MNEMONIC, tomoNodeUrl);
      },
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },     
  },
  mocha: {
    reporter: "eth-gas-reporter",
    reporterOptions: {
      currency: "USD",
      gasPrice: 2,
    },
  },
  compilers: {
    solc: {
      version: "^0.8.0",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200   // Optimize for how many times you intend to run the code
        },
      },
    },
  },
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    bscscan: 'YYEBPBZ4H5GS1R4K8FUN8ZBU7EYMFMR8X1'
  },
};
