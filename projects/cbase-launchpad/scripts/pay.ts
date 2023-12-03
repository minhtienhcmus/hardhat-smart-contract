import { ethers, network, run } from "hardhat";
import config from "../config";
import { constants } from "@openzeppelin/test-helpers";
const IDO_ABI  = require("../abi/IDOFactory.json");
const TokenABI  = require("../abi/tokenERC20.json");
// địa chỉ Wrapped Ether (WETH) trên goerli
const IDO_ADDRESS = "0xEbb1E7fFf99d8115C280daece4C1D62b868c3c73";
const TOKEN_ADDRESS = "0x493A0aee4312053674A9DA8ff46f3B630E4afc07";
const main = async () => {
  // Get network name: hardhat, testnet or mainnet.
  const { name } = network;

  const [deployer] = await ethers.getSigners();

  // console.log("IDO_ABI OK",IDO_ABI);
  const idoF = new ethers.Contract(IDO_ADDRESS, IDO_ABI.abi, deployer);
  const token = new ethers.Contract(TOKEN_ADDRESS, TokenABI, deployer);
  console.log("approving ");
  await token.approve(IDO_ADDRESS,"10000000000000000000000");
  console.log("approved OK");
  await idoF.createIDO("0x493A0aee4312053674A9DA8ff46f3B630E4afc07",["350000000000000","10000000000000000","200000000000000000","5000000000000000","20000000000000000","500000000000000","60"],["1694318061","1694318421","1694318721"],["0x8B76f8e008570686aD5933e5669045c5B01DB7bE","0x1a91f5ADc7cB5763d35A26e98A18520CB9b67e70","0x48f6D7dAE56623Dde5a0D56B283165cAE1753D70","86520","105960","7922812760334014175246846344927",[-887272, -887272]],"0x63d1B9f9bE07Fe9Ac7979811Ab8581A1d622f133","https://bafybeig45lg7xoszu3obuinz76v5a7pa7iz5opc3wscctj3u47gqgj42yy.ipfs.w3s.link/9.png");
  console.log("createIDO OK");
  

};

main()
  .then(() => process.exit(0))
  .catch((error) => { 
    console.error(error);
    process.exit(1);

  });
