import { ethers, network, run } from "hardhat";
import config from "../config";
import { constants } from "@openzeppelin/test-helpers";
import '@nomiclabs/hardhat-ethers';
const fs = require("fs");
const log_file = fs.createWriteStream(__dirname + `/deployLog_${Date.now()}.log`, { flags: "w" });
const log_stdout = process.stdout;
const ZE_PROXY_ABI = require("../artifacts/contracts/Factory.sol/Factory.json");
const positionDescriptorContractABI = require("../artifacts/contracts/TokenPositionDescriptor.sol/TokenPositionDescriptor.json");
const antiSnipAttackPositionManagerContractABI = require("../artifacts/contracts/AntiSnipAttackPositionManager.sol/AntiSnipAttackPositionManager.json");
// console.log("ZE_PROXY_ABI",ZE_PROXY_ABI)
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
  const [deployer] = await ethers.getSigners();
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

  // console.log("======================")
  // const  factory = await ethers.getContractFactory("Factory");
  // const ffac = (await factory.deploy(config.VESTINGPERIOD[name]));
  // await ffac.deployed();
  // console.log("FactoryAdress:",ffac.address);

  // // console.log("======================")
  // const  tokenPositionDescriptor = await ethers.getContractFactory("TokenPositionDescriptor");
  // const positionDescriptorContract = await tokenPositionDescriptor.deploy();
  // await positionDescriptorContract.deployed();
  // console.log("positionDescriptorContractAddress:",positionDescriptorContract.address);

  // // console.log("======================")
  // const  ticksFeesReader = await ethers.getContractFactory("TicksFeesReader");
  // const ticksFeesReaderContract = await ticksFeesReader.deploy();
  // await ticksFeesReaderContract.deployed();
  // console.log("TicksFeesReaderAddress:",ticksFeesReaderContract.address);
  const ffac = new ethers.Contract("0xDdE98eF36255342F57d0C79e0241732Dc792Fb8B", ZE_PROXY_ABI.abi, deployer);
  console.log("==========ffac============",ffac.address)

  // const positionDescriptorContract = new ethers.Contract("0x1C205DA412935E6b07836E6A09Ff81dA6F057F66", positionDescriptorContractABI.abi, deployer);
  // console.log("=========positionDescriptorContract=============",positionDescriptorContract.address)

  const antiSnipAttackPositionManagerContract = new ethers.Contract("0x1C205DA412935E6b07836E6A09Ff81dA6F057F66", antiSnipAttackPositionManagerContractABI.abi, deployer);
  console.log("=========antiSnipAttackPositionManagerContract=============",antiSnipAttackPositionManagerContract.address)

  // const  antiSnipAttackPositionManager = await ethers.getContractFactory("AntiSnipAttackPositionManager");
  // const antiSnipAttackPositionManagerContract = await antiSnipAttackPositionManager.deploy(ffac.address,config.WETH[name],positionDescriptorContract.address);
  // // const antiSnipAttackPositionManagerContract = await antiSnipAttackPositionManager.deploy("0x00FBd026c661a99e3d81D810b1bCa39B2eB9aA34",config.WETH[name],"0x8225a33aE194E9Ffb2Df6cc1c621809B7350f801");
  // await antiSnipAttackPositionManagerContract.deployed();
  // console.log(`addNFTManager..`);
  // await ffac.addNFTManager(antiSnipAttackPositionManagerContract.address);
  // console.log(`updating config master...`);
  // await ffac.updateConfigMaster(config.ADMIN[name]);
  // console.log("antiSnipAttackPositionManagerContractAddress:",antiSnipAttackPositionManagerContract.address);

  // console.log("======================")
  // const  quoterV2 = await ethers.getContractFactory("QuoterV2");
  // const quoterV2Contract = await quoterV2.deploy(ffac.address);
  // await quoterV2Contract.deployed();
  // console.log("quoterV2ContractAddress:",quoterV2Contract.address);

  console.log("======================")
  const router = await ethers.getContractFactory("Router");
  const routerContract = await router.deploy(ffac.address,config.WETH[name]);
  await routerContract.deployed();
  console.log("routerContractAddress:",routerContract.address);

  console.log("======================")
  const CbaseSwapV3LM = await ethers.getContractFactory("CbaseSwapV3LM");
  const CbaseSwapV3LMContract = await CbaseSwapV3LM.deploy(antiSnipAttackPositionManagerContract.address,config.LOCK[name]);
  // const OcarioSwapElasticLMContract = await OcarioSwapElasticLM.deploy(config.POSMANAGE[name], config.LOCK[name]);
  await CbaseSwapV3LMContract.deployed();
  console.log("OcarioSwapElasticLMContractAddress:",CbaseSwapV3LMContract.address);
  
  // await verify("Factory",ffac.address,[config.VESTINGPERIOD[name]]);
  // await verify("antiSnipAttackPositionManagerContract",antiSnipAttackPositionManagerContract.address,[ffac.address,config.WETH[name],positionDescriptorContract.address]);
  // await verify("quoterV2Contract",quoterV2Contract.address,[ffac.address]);
  // await verify("routerContract",routerContract.address,[ffac.address,config.WETH[name]]);
  // await verify("OcarioSwapElasticLMContract",OcarioSwapElasticLMContract.address,[antiSnipAttackPositionManagerContract.address,config.LOCK[name]]);
  const poolInitHash =  await ffac.poolInitHash();
  console.log("getpoolInitHash:",poolInitHash); 
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
