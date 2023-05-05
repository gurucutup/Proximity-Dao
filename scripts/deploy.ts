// @ts-nocheck
import { ethers } from "hardhat";
import hre from "hardhat";

const verifyContract = async (_address, _args) => {
  if (_args)
    await hre.run("verify:verify", {
      address: _address,
      constructorArguments: _args,
    });
  else
    await hre.run("verify:verify", {
      address: _address,
    });
};

async function main() {
  const VetoPluginSetup = await ethers.getContractFactory("VetoPluginSetup");
  const vetoPluginSetup = await VetoPluginSetup.deploy();

  await vetoPluginSetup.deployed();
  
  const TestVotingToken = await ethers.getContractFactory("TestVotingToken");
  const testVotingToken = await TestVotingToken.deploy(100000);

  await testVotingToken.deployed();

  console.log(
    `VetoPluginSetup contract deployed to ${vetoPluginSetup.address}\n TestVotingToken contract deployed to ${testVotingToken.address}`
  );

  await verifyContract(vetoPluginSetup.address);
  await verifyContract(testVotingToken.address, [100000]);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
