import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { CONTRACTS } from "../constants";
import deployAndVerifyContract from "../common/deploy_verify";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  await deployAndVerifyContract(hre, CONTRACTS.AdventFactoryContract, [
    "0x51fce89b9f6d4c530698f181167043e1bb4abf89",
  ]);
};

export default func;
