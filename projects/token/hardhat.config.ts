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
const mumbaiTestnet: NetworkUserConfig = {
  url: "https://polygon-mumbai.g.alchemy.com/v2/PMf4J8vrEAHL6klsplo_2HYp81puJoCo",
  chainId: 80001,
  accounts: [process.env.KEY_TESTNET!],
};
const bscMainnet: NetworkUserConfig = {
  url: "https://bsc-dataseed.binance.org/",
  chainId: 56,
  accounts: [process.env.KEY_MAINNET!],
};
const polygon: NetworkUserConfig = {
  url: "https://polygon-mainnet.infura.io/v3/f160240e31c24c64970dda4fa4e348d3",
  chainId: 137,
  accounts: [process.env.KEY_MAINNET!],
};
const baseGoerli: NetworkUserConfig = {
  url: "https://base-goerli.rpc.thirdweb.com",
  chainId: 84531,
  accounts: [process.env.KEY_TESTNET!],
};

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    goerli: goeliTestnet,
    // mainnet: bscMainnet,
    mumbai:mumbaiTestnet,
    bsc_testnet:bscTestnet,
    // polygon,
    base_goerli:baseGoerli
  },  
  etherscan: {
    apiKey: {
      bscTestnet:"G5MBKAKGYA7XAG5U13BVUHP6TVUA9DG6DV",
      goerli:"97XJFBDVGF9CQ2J2Z71YCY5HBYRE94WU9X",
      polygonMumbai:"7H6FAKKVBZHSNEEV2SWKSDCIU42M92P78D",
      polygon:"7H6FAKKVBZHSNEEV2SWKSDCIU42M92P78D"
    }
  },
  solidity: {
    version: "0.5.16",
    settings: {
      optimizer: {
        enabled: true,
        runs: 99999,
      },
    },
  },
  paths: {
    sources: "./contracts",
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
