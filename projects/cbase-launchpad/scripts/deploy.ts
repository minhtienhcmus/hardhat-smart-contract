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



  console.log("Deploying IDOFactory");

  console.log("======================")
  const  idoFactory = await ethers.getContractFactory("IDOFactory");
  const ido = (await idoFactory.deploy(config.FeeAmount[name],config.ADMIN[name]));
  await ido.deployed();
  console.log("IDOFactory:",ido.address);

  console.log("Deploying TokenLockerFactory");

  console.log("======================")
  const  tokenLockerFactory = await ethers.getContractFactory("TokenLockerFactory");
  const tokenLocker = await tokenLockerFactory.deploy(config.basePositionManager[name]);
  await tokenLocker.deployed();
  console.log("TokenLockerFactory:",tokenLocker.address);
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
