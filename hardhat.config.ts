import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";

import { HardhatUserConfig } from "hardhat/config";

import { resolve } from "path";
import { config as dotenvConfig } from "dotenv";
dotenvConfig({ path: resolve(__dirname, "./.env") });

const privateKey = process.env.PRIVATE_KEY || "";
const etherscanApiKey = process.env.ETHERSCAN_API_KEY || "";
const infuraKey = process.env.INFURA_KEY || "";

const config: HardhatUserConfig = {
  defaultNetwork: "testnet",
  networks: {
    mainnet: {
      accounts: [privateKey],
      chainId: 1,
      url: `https://mainnet.infura.io/v3/${infuraKey}`,
    },
    testnet: {
      accounts: [privateKey],
      chainId: 11155111,
      url: `https://sepolia.infura.io/v3/${infuraKey}`,
    },
    base: {
      accounts: [privateKey],
      chainId: 8453,
      url: `https://base-mainnet.infura.io/v3/${infuraKey}`,
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  etherscan: {
    apiKey: etherscanApiKey,
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
    deploy: "./scripts/deploy",
    deployments: "./deployments",
  },
  solidity: {
    settings: {
      outputSelection: {
        "*": {
          "*": ["storageLayout"],
        },
      },
      metadata: {
        bytecodeHash: "none",
      },
      optimizer: {
        enabled: true,
        runs: 20,
      },
    },
    compilers: [
      { version: "0.7.5" },
      { version: "0.7.6" },
      { version: "0.8.0" },
      { version: "0.8.10" },
      { version: "0.8.15" },
      {
        version: "0.8.20",
        settings: {
          metadata: { bytecodeHash: "none" },
          optimizer: { enabled: true, runs: 20 },
        },
      },
    ],
  },
  gasReporter: {
    currency: "USD",
    enabled: true,
    excludeContracts: [],
    src: "/contracts",
  },
  mocha: {
    timeout: 1000000000000000000000000,
  },
};

export default config;
