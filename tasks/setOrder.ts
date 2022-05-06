import {
  stakingToken, web3, task, envParams, getSign, staking, dao, trade, rewardToken
} from "./tasks";

type tArgsType = {
  gaslimit: string;
  amount: string;
  privatekey: string;
  price: string;
}

function setOrderTask(){
  task("setorder", "set order")
  .addParam("gaslimit", "gaslimit")
  .addParam("privatekey", "Private key")
  .addParam("amount", "Amount of tokens")
  .addParam("price", "One token pice amount")
  .setAction(async(tArgs:tArgsType)=>{
    try{
      let {gaslimit, amount, privatekey, price} = tArgs;

      let data = await trade.methods.setOrder(amount, price).encodeABI();
      let sign = await getSign({gaslimit,data,privatekey, to: trade.address});
      let transaction = await web3.eth.sendSignedTransaction(sign.rawTransaction);
      console.log("Set Order: success!", transaction.transactionHash);

    }catch(e:any){
      console.log(e.message);
    }
  })
}

module.exports = {
  setOrderTask
}
