import Web3 from "web3";
import * as dotenv from "dotenv";
import {task} from "hardhat/config";
import {provider as Provider} from "web3-core/types/index.d"
dotenv.config();
let {abi: erc20ABI} = require("./../artifacts/contracts/ERC20.sol/MyERC20.json");
let {abi: stakingABI} = require("./../artifacts/contracts/Staking.sol/Staking.json");
let {abi: tradeABI} = require("./../artifacts/contracts/Trade.sol/Trade.json");
let {abi: daoABI} = require("./../artifacts/contracts/DAO.sol/DAO.json");
let {abi: creator} = require("./../artifacts/contracts/createPair.sol/CreatePair.json");


let envParams = process.env;

let provider: Provider = new Web3.providers.HttpProvider(`${envParams.META_MASK_PROVIDER_URL}`)
let web3: Web3 = new Web3(provider);

let stakingToken = new web3.eth.Contract(erc20ABI, `${envParams.XXX_TOKEN}`);

let rewardToken = new web3.eth.Contract(erc20ABI, `${envParams.REWARD_TOKEN}`);

/*let trade = new web3.eth.Contract(tradeABI, `${envParams.TRADE_ADDRESS}`);*/

let dao = new web3.eth.Contract(daoABI, `${envParams.DAO_ADDRESS}`);

let staking = new web3.eth.Contract(stakingABI, `${envParams.STAKING_ADDRESS}`);

let pairCreator = new web3.eth.Contract(creator, `${envParams.STAKING_ADDRESS}`);

interface SignType {
  gaslimit: string;
  privatekey: string;
  data: string;
  to: string;
  value?: string;
}

async function getSign(obj:SignType, isForStaking?:boolean):Promise<any> {
  //Создаю объект необходимый для подписи транзакций
    return await web3.eth.accounts.signTransaction({
      to:obj.to,//Адрес контракта, к которому нужно обратиться
      value: obj.value,//Велечина эфира, которую вы хотите отправить на контракт
      gas: Number(obj.gaslimit),//Лимит газа, максимально допустимый газ, который вы допускаете использовать при выполнении транзакции.Чем больше лимит газа, тем более сложные операции можно провести при выполнении транзакции
      data: obj.data//Бинарный код транзакции, которую вы хотите выполнить
    }, obj.privatekey)
}


export {
  stakingToken, web3, task, envParams, getSign, staking, dao, /*trade,*/ rewardToken, pairCreator
}
