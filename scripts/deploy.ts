// @ts-nocheck
import { ethers } from "hardhat";
import hre from "hardhat";

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

async function main() {

  
  const TestVotingToken = await ethers.getContractFactory("TestVotingToken");
  const testVotingToken = await TestVotingToken.deploy(10000000);
  await testVotingToken.deployed();
  
  console.log(`TestVotingToken contract deployed to ${testVotingToken.address}`);
  
  const VetoPluginSetup = await ethers.getContractFactory("VetoPluginSetup");
  const vetoPluginSetup = await VetoPluginSetup.deploy();
  await vetoPluginSetup.deployed();
  
  
  console.log(
    `VetoPluginSetup contract deployed to ${vetoPluginSetup.address}\n`
    );
    
  await verifyContract(testVotingToken.address, [10000000]);
  await verifyContract(vetoPluginSetup.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
