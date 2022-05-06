import {
  stakingToken, web3, task, envParams, getSign, staking, dao, trade, rewardToken
} from "./tasks";

type tArgsType = {
  gaslimit: string;
  amount: string;
  privatekey: string;
  value: string;
}

function buyTokensTask(){
  task("buy", "Buy tokens")
  .addParam("gaslimit", "gaslimit")
  .addParam("privatekey", "Private key")
  .addParam("amount", "Amount of tokens")
  .addParam("value", "Wei amount")
  .setAction(async(tArgs:tArgsType)=>{
    try{
      let {gaslimit, amount, privatekey, value} = tArgs;

      let data = await trade.methods.buyTokens(amount).encodeABI();
      let sign = await getSign({gaslimit,data,privatekey,value, to: trade.address});
      let transaction = await web3.eth.sendSignedTransaction(sign.rawTransaction);
      console.log("Buy tokens: success!", transaction.transactionHash);

    }catch(e:any){
      console.log(e.message);
    }
  })
}

module.exports = {
  buyTokensTask
}
