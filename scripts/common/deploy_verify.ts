import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployResult } from "hardhat-deploy/types";
import { ContractInforType } from "../constants";

const deployAndVerifyContract = async (
  _hre: HardhatRuntimeEnvironment,
  _contract: ContractInforType,
  _constructorArguments?: any[]
) => {
  const _deployment = await _deployCcontract(
    _hre,
    _contract,
    _constructorArguments
  );
  await _verifyCcontract(_hre, _deployment, _constructorArguments);
  return _deployment;
};

const _deployCcontract = async (
  _hre: HardhatRuntimeEnvironment,
  _contract: ContractInforType,
  _constructorArguments?: any[]
) => {
  const { deployments, getNamedAccounts } = _hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const deployName = _contract.deployName;
  const contractName = _contract.contractName;

  const _deployment = await deploy(deployName, {
    contract: contractName,
    from: deployer,
    args: _constructorArguments,
    log: true,
    skipIfAlreadyDeployed: true,
  });

  return _deployment;
};

const _verifyCcontract = async (
  _hre: HardhatRuntimeEnvironment,
  _deployment: DeployResult,
  _constructorArguments?: any[]
) => {
  await _hre
    .run("verify:verify", {
      address: _deployment.address,
      constructorArguments: _constructorArguments,
    })
    .catch(() => null);
};

export default deployAndVerifyContract;
