import {
  stakingToken, web3, task, envParams, getSign, staking, dao, trade, rewardToken
} from "./tasks";

type tArgsType = {
  gaslimit: string;
  privatekey: string;
}

function setTradeRound(){
  task("traderound", "set trade round")
  .addParam("gaslimit", "gaslimit")
  .addParam("privatekey", "Private key")
  .addParam("amount", "Amount of tokens")
  .addParam("id", "One token pice amount")
  .setAction(async(tArgs:tArgsType)=>{
    try{
      let {gaslimit, privatekey} = tArgs;

      let data = await trade.methods.setTradeRound().encodeABI();
      let sign = await getSign({gaslimit,data,privatekey, to: trade.address});
      let transaction = await web3.eth.sendSignedTransaction(sign.rawTransaction);
      console.log("Set trade round: success!", transaction.transactionHash);

    }catch(e:any){
      console.log(e.message);
    }
  })
}

module.exports = {
  setTradeRound
}
