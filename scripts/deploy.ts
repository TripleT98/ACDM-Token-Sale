
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


async function deployDAOandTrade() {

  /*const DAO = await ethers.getContractFactory("DAO");
  const dao = await DAO.deploy(process.env.PUBLIC_KEY as string, 259200);

  await dao.deployed();

  console.log("DAO deployed to:", dao.address);*/

  const Trade = await ethers.getContractFactory("TradeA");
  const trade = await Trade.deploy(259200);

  await trade.deployed();

  console.log("Trade deployed to:", trade.address);


}

async function deployPairCreator() {

  /*const DAO = await ethers.getContractFactory("DAO");
  const dao = await DAO.deploy(process.env.PUBLIC_KEY as string, 259200);

  await dao.deployed();

  console.log("DAO deployed to:", dao.address);*/

  const PairCreator = await ethers.getContractFactory("CreatePair");
  const pairCreator = await PairCreator.deploy("0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f");

  await pairCreator.deployed();

  console.log("Pair creator deployed to:", pairCreator.address);


}

deployDAOandTrade().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
