import { ethers, network, run } from "hardhat";
import config from "../config";
import {HardhatRuntimeEnvironment} from 'hardhat/types';
import '@nomiclabs/hardhat-ethers';
import { constants } from "@openzeppelin/test-helpers";
const fs = require("fs");
const log_file = fs.createWriteStream(__dirname + `/deployLog_${Date.now()}.log`, { flags: "w" });
const log_stdout = process.stdout;

console.log = function (m1, m2 = "") {
  log_file.write(`${m1} ${m2}` + "\n");
  log_stdout.write(`${m1} ${m2}` + "\n");
};
const verify = async (name, contractAddress, args) => {
  console.log(`== START VERIFY: ${name} ==`);
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    });
  } catch (e) {
    if (e.message.toLowerCase().includes("already verified")) {
      console.log("Already verified!");
    } else {
      console.log(e);
    }
  }
  console.log(`== VERIFY DONE: ${name} ==`);
  console.log("");
};
const main = async () => {
  // Get network name: hardhat, testnet or mainnet.
  const { name } = network;

  if (name == "mainnet") {
    if (!process.env.KEY_MAINNET) {
      throw new Error("Missing private key, refer to README 'Deployment' section");
    }
    if (!config.ADMIN[name]) {
      throw new Error("Missing VESTINGPERIOD , refer to README 'Deployment' section");
    }


  }

  console.log("Deploying to network:", network);



    console.log("Deploying Multicall");
    // const CakeContract = await ethers.getContractFactory("CakeToken");
    // const SyrupContract = await ethers.getContractFactory("SyrupBar");
    // // const MasterChefContract = await ethers.getContractFactory("MasterChef");
    // const currentBlock = await ethers.provider.getBlockNumber()



  // console.log("Deploying Masterchef v2 ...");
  console.log("======================")
  const  factory = await ethers.getContractFactory("Multicall2");
  const ffac = await factory.deploy();
  await ffac.deployed();
  console.log("Multicall:",ffac.address);

  // await verify("OcarioRewardLockerV2Contract", ffac.address,[config.ADMIN[name]]);



};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);

  });
