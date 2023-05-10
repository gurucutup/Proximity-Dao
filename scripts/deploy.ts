// @ts-nocheck
import { ethers } from "hardhat";
import hre from "hardhat";
import {PluginRepoFactory__factory} from '@aragon/osx-ethers';

import * as addresses from '../address.json';
import * as releaseMetaDataUri from '../releaseMetadata.json';
import * as buildMetadataUri from '../metadata.json';

const verifyContract = async (_address, _args) => {
  if (_args)
    await hre.run("verify:verify", {
      address: _address,
      constructorArguments: [..._args],
    });
  else
    await hre.run("verify:verify", {
      address: _address,
    });
};

export function toHex(input: string): BytesLike {
  return ethers.utils.hexlify(ethers.utils.toUtf8Bytes(input));
}

async function main() {
  // const TestVotingToken = await ethers.getContractFactory("TestVotingToken");
  // const testVotingToken = await TestVotingToken.deploy(10000000);
  // await testVotingToken.deployed();
  
  // console.log(`TestVotingToken contract deployed to ${testVotingToken.address}`);
  
  // const VetoPluginSetup = await ethers.getContractFactory("VetoPluginSetup");
  // const vetoPluginSetup = await VetoPluginSetup.deploy();
  // await vetoPluginSetup.deployed();
  
  // console.log(`VetoPluginSetup contract deployed to ${vetoPluginSetup.address}\n`);

  // PluginSetup Deploy
  /**
   * 
   * TestVotingToken contract deployed to 0xA3a0E817B9D8A73efa88Bd646EB4465BC49A611E
   * VetoPluginSetup contract deployed to 0x7ddcE896A2616f854a53B9646a52cC9Eb52b1BaB
   */
  const provider = new ethers.providers.JsonRpcProvider(addresses.mumbai.rpcUrl);

  const deployer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
  const pluginRepoFactory = PluginRepoFactory__factory.connect(
    addresses.mumbai.PluginRepoFactory,
    deployer,
  );

  const gasPrice = ethers.utils.parseUnits('20', 'gwei');

  const sendPromise = pluginRepoFactory.createPluginRepoWithFirstVersion(
    "Sub-Dao-proximity-mumbai",
    // VetoPluginSetup.address,
    // "0x7ddcE896A2616f854a53B9646a52cC9Eb52b1BaB",
    "0x44AD088f94234c97fa46D977D9Ca77a48081C181",
    "0x1e1a5D6E2B6a858c2879ccEF69215e41782C58fb",
    toHex(releaseMetaDataUri),
    toHex(buildMetadataUri),
    { gasPrice: gasPrice, gasLimit: 1000000 }
  );

  sendPromise.then((tx) => {
    console.log(`Transaction hash: ${tx.hash}`);
  }).catch((error) => {
    console.log(error);
  })

  // await verifyContract(testVotingToken.address, [10000000]);
  // await verifyContract(vetoPluginSetup.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
