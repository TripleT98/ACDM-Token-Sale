
import { ethers } from "hardhat";
import * as dotenv from "dotenv";
dotenv.config();

async function deployTokens() {

  const ERC20 = await ethers.getContractFactory("MyERC20");
  const stakingToken = await ERC20.deploy("XXXToken", "XXX", 18);

  await stakingToken.deployed();

  console.log("Staking token deployed to:", stakingToken.address);

  const rewardToken = await ERC20.deploy("ACDMToken", "ACDM", 6);

  await rewardToken.deployed();

  console.log("Reward token deployed to:", rewardToken.address);
}


async function deployStakingAndDAO() {

  const Staking = await ethers.getContractFactory("Staking");
  const staking = await Staking.deploy(process.env.STAKING_TOKEN as string, process.env.REWARD_TOKEN as string);

  await staking.deployed();

  console.log("Staking deployed to:", staking.address);

  const DAO = await ethers.getContractFactory("DAO");
  const dao = await DAO.deploy(process.env.PUBLIC_KEY as string, 259200);

  await dao.deployed();

  console.log("DAO deployed to:", dao.address);
}

async function deployTrade(){
  const Trade = await ethers.getContractFactory("Trade");
  const trade = await Trade.deploy(259200);

  await trade.deployed();

  console.log("Trade deployed to:", trade.address);
}

deployStakingAndDAO().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
