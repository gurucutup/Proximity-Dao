// @ts-nocheck
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      // accounts visible to hardhat network used by `hardhat node --fork` (yarn net <chainName>)
      // accounts: hardhatNetworkAccounts,
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      timeout: 300000,
    },
    bsc: {
      url: "https://bsc-mainnet.nodereal.io/v1/083880c5faac4d7ca5b451a403575f08",
      chainId: 56,
      accounts: [process.env.PRIVATE_KEY],
    },
    bsctestnet: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545`,
      accounts: [process.env.PRIVATE_KEY_BSC],
      chainId: 97,
    },
    core: {
      url: `https://bsc-dataseed.binance.org`,
      accounts: [process.env.PRIVATE_KEY],
      chainId: 56,
    },
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/",
      chainId: 4,
      accounts: [process.env.PRIVATE_KEY],
    },
    mumbai: {
      url: "https://polygon-mumbai.infura.io/v3/4458cf4d1689497b9a38b1d6bbf05e78",
      // url: "https://rpc-mumbai.maticvigil.com/",
      // url: "https://polygon-mumbai.blockpi.network/v1/rpc/public",
      // url: "https://api-testnet.polygonscan.com/",
      chainId: 80001,
      accounts: [process.env.PRIVATE_KEY],
    },
    goerli: {
      url: "https://goerli.blockpi.network/v1/rpc/public",
      chainId: 5,
      accounts: [process.env.PRIVATE_KEY],
      // gas: 'auto',
      // gasPrice: 1000000000, // 1 gwei (in wei)
      // gasMultiplier: 1.5 // Multiplier to apply to `gas` to increase/decrease it.
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 40000
  },
  etherscan: {
    apiKey: process.env.MUMBAI_API_KEY
  }
};

export default config;
