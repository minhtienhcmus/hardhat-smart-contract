import { ethers, network, run } from "hardhat";
import config from "../config";
import { constants } from "@openzeppelin/test-helpers";
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



  console.log("Deploying TokenSwapWith0x");

  console.log("======================")
  const  tokenSwapWith0x = await ethers.getContractFactory("TokenSwapWithCbase");
  const ffac = (await tokenSwapWith0x.deploy(config.WETH[name]));
  await ffac.deployed();
  console.log("TokenSwapWithCbase:",ffac.address);
  // console.log("verifing TokenSwapWithOcario ...");
  // await run(`verify:verify`, {
  //   address: ffac.address,
  //   constructorArguments: [config.WETH[name]],
  // });

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);

  });
