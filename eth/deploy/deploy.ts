// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, deployments } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from 'hardhat-deploy/types';
import { BigNumber } from "@ethersproject/bignumber";
import { BN, Address, toChecksumAddress } from "ethereumjs-util";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts } = hre;
  const l1Deployer = (await getNamedAccounts()).l1Deployer;
  const nonce = await ethers.provider.getTransactionCount(l1Deployer);
  const deployAddress = Address.generate(
    Address.fromString(l1Deployer),
    new BN(String(nonce))
  );

  // use this address to deploy contracts on starknet
  // 0xDbe6E6A1615908156Cf790db9570A80b520906Ef
  console.log(toChecksumAddress(deployAddress.toString()));

  // uncomment this to deploy contracts on L1 after deploying on starknet
  // const gateway = "0xa21...f3a"
  const starknetCore = "0xde29d060D45901Fb19ED6C6e959EB22d8626708e";
  const gateway =
    "0x059b4cfd569909079fcef3b9b10159efda2c3c8975f2a1e069984a74934e0045";

  const l1 = await deployments.deploy("Claimer", {
    from: l1Deployer,
    args: [starknetCore, BigNumber.from(gateway)],
  });

  console.log("Claimer deployed to:", l1.address);
};

export default func;
func.tags = ["C2C"];
