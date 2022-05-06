import {
  stakingToken, web3, task, envParams, getSign, staking, dao, trade, rewardToken
} from "./tasks";

type tArgsType = {
  gaslimit: string;
  privatekey: string;
  id: string;
  value: string;
  amount: string;
}

function redeemOrderTask(){
  task("redeem", "redeem order")
  .addParam("gaslimit", "gaslimit")
  .addParam("privatekey", "Private key")
  .addParam("amount", "Amount of tokens")
  .addParam("value", "Wei value")
  .addParam("id", "Order`s id")
  .setAction(async(tArgs:tArgsType)=>{
    try{
      let {gaslimit, amount, privatekey, id, value} = tArgs;

      let data = await trade.methods.redeemOrder(amount, id).encodeABI();
      let sign = await getSign({gaslimit,data,privatekey,value, to: trade.address});
      let transaction = await web3.eth.sendSignedTransaction(sign.rawTransaction);
      console.log("Redeem order: success!", transaction.transactionHash);

    }catch(e:any){
      console.log(e.message);
    }
  })
}

module.exports = {
  redeemOrderTask
}
