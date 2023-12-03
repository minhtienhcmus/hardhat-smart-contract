import { ethers, network, run } from "hardhat";
import config from "../config";
import { constants } from "@openzeppelin/test-helpers";
import '@nomiclabs/hardhat-ethers';
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
    if (!config.VESTINGPERIOD[name]) {
      throw new Error("Missing VESTINGPERIOD , refer to README 'Deployment' section");
    }


  }

  console.log("Deploying to network:", network);



    console.log("Deploying Factory ...");
    // const CakeContract = await ethers.getContractFactory("CakeToken");
    // const SyrupContract = await ethers.getContractFactory("SyrupBar");
    // // const MasterChefContract = await ethers.getContractFactory("MasterChef");
    // const currentBlock = await ethers.provider.getBlockNumber()

    const [deployer] = await ethers.getSigners();
    const zeroExMigration = new ethers.Contract("0xedb270B3E9ee10e88C91a91573cc1C9E75784E28", '[{ "inputs": [], "name": "poolInitHash", "outputs": [ {"internalType": "bytes32","name": "","type": "bytes32"}], "stateMutability": "view","type": "function"}]', deployer);
   const poolInitHash =  await zeroExMigration.poolInitHash();
   console.log("++++====poolInitHash=====++++",poolInitHash)
    // await verify("Factory",ffac.address,[config.VESTINGPERIOD[name]]);
  // await verify("antiSnipAttackPositionManagerContract",antiSnipAttackPositionManagerContract.address,[ffac.address,config.WETH[name],positionDescriptorContract.address]);
  // await verify("quoterV2Contract",quoterV2Contract.address,[ffac.address]);
  // await verify("routerContract",routerContract.address,[ffac.address,config.WETH[name]]);
  // await verify("OcarioSwapElasticLMContract",OcarioSwapElasticLMContract.address,[antiSnipAttackPositionManagerContract.address,config.LOCK[name]]);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
