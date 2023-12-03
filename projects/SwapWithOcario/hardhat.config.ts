import type { HardhatUserConfig, NetworkUserConfig } from "hardhat/types";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-web3";
import "@nomiclabs/hardhat-truffle5";
import "hardhat-abi-exporter";
import "hardhat-contract-sizer";
import "solidity-coverage";
import "dotenv/config";
import "@nomiclabs/hardhat-etherscan";
const bscTestnet: NetworkUserConfig = {
  url: "https://data-seed-prebsc-1-s3.binance.org:8545/",
  chainId: 97,
  accounts: [process.env.KEY_TESTNET!],
};


const goeliTestnet: NetworkUserConfig = {
  url: "https://goerli.infura.io/v3/f160240e31c24c64970dda4fa4e348d3",
  chainId: 5,
  accounts: [process.env.KEY_TESTNET!],
};
const bscMainnet: NetworkUserConfig = {
  url: "https://bsc-dataseed.binance.org/",
  chainId: 56,
  accounts: [process.env.KEY_MAINNET!],
};
const mumbaiTestnet: NetworkUserConfig = {
  url: "https://polygon-mumbai.g.alchemy.com/v2/PMf4J8vrEAHL6klsplo_2HYp81puJoCo",
  chainId: 80001,
  accounts: [process.env.KEY_TESTNET!],
};
const polygon: NetworkUserConfig = {
  url: "https://polygon-mainnet.infura.io/v3/f160240e31c24c64970dda4fa4e348d3",
  chainId: 137,
  accounts: [process.env.KEY_MAINNET!],
};
const baseGoerli: NetworkUserConfig = {
  url: "https://chain-proxy.wallet.coinbase.com?targetName=base-goerli",
  chainId: 84531,
  accounts: [process.env.KEY_TESTNET!],
  gasPrice: 20000000000
};
const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    testnet: goeliTestnet,
    // mainnet: polygon,
    base_goerli:baseGoerli
  },  
  etherscan: {
    apiKey: "79JTHKAUH3J5KSHEEUFZHQ3YSF5BQ24RK2"
    // apiKey: "G5MBKAKGYA7XAG5U13BVUHP6TVUA9DG6DV"
  },
  solidity: {
    version: "0.8.15",
    settings: {
      optimizer: {
        enabled: true,
        runs: 99999,
      },
    },
  },
  paths: {
    sources: "./contracts",
    // tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  abiExporter: {
    path: "./data/abi",
    clear: true,
    flat: false,
  },
};

export default config;
