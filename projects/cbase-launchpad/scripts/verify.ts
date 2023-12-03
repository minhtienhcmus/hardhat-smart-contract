import { ethers, network, run } from "hardhat";
import config from "../config";
import { constants } from "@openzeppelin/test-helpers";
// const IDO_ABI  = require("../abi/IDOFactory.json");
const IDOPOOL  = require("../abi/IDOPOOL.json");
// địa chỉ Wrapped Ether (WETH) trên goerli
// const IDO_ADDRESS = "0x13Eb7C41D61511a4B3f743821DC0D0E580B25f65";
const _ADDRESS = "0xc42d1b26b4270b9f3633e328a4aa3bba9e7e5ee1";
const main = async () => {
  // Get network name: hardhat, testnet or mainnet.
  const { name } = network;

  const [deployer] = await ethers.getSigners();

  // console.log("IDO_ABI OK",IDO_ABI);
  // const idoF = new ethers.Contract(IDO_ADDRESS, IDO_ABI.abi, deployer);
  const poolContract = new ethers.Contract(_ADDRESS, IDOPOOL.abi, deployer);
  const address = await poolContract.setPoolVerify();
  // console.log("address OK",address.toString());
  // await idoF.createIDO("0x1dAab5922D2D9983166726fB678Be0798ef4148d",["0x25e546dd9aaab","0x2386f26fc10000","0x470de4df820000","0x2386f26fc10000","0x470de4df820000","0x2bb9c7ec013b2",6050,0,0,10000],["1695110343","1695113943","1695117543"],["0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f","0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D","0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f","0xb4fbf271143f4fbf7b91a5ded31805e42b2208d6",-77280,-57840,"2197369742407909185249577052",[-887272,-887272],"other"],"0xc30Ffc988Dc9e4270e3E053ceA3Bec690B546810","QmTB4DZURWyVj3NDw9imz2xZKbztASLqwjy5K7Mf4GcSrH",false);
  // console.log("createIDO OK");

};

main()
  .then(() => process.exit(0))
  .catch((error) => { 
    console.error(error);
    process.exit(1);

  });
