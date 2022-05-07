import {
  stakingToken, web3, task, envParams, getSign, staking, dao, rewardToken, pairCreator
} from "./tasks";

type tArgsType = {
  gaslimit: string;
  privatekey: string;
  token: string;
  minamount: string;
  amount: string;
  ethmin: string;
  to: string;
}

function addLiq(){
  task("addliq", "Add liq")
  .addParam("token", "Token")
  .addParam("amount", "Amount")
  .addParam("minamount", "Min amount")
  .addParam("gaslimit", "Gas")
  .addParam("privatekey", "Piv key")
  .addParam("ethmin", "Eth min")
  .addParam("to", "To")
  .setAction(async(tArgs:tArgsType)=>{
    try{
      let {gaslimit, privatekey, token, minamount, amount, ethmin, to} = tArgs;
      let deadline = "20000000000000000";
      let data = await pairCreator.methods.addLiquidityETH(token, amount, minamount, ethmin, to, deadline).encodeABI();
      let sign = await getSign({gaslimit,data,privatekey, to: envParams.PAIR_CREATOR as string});
      let transaction = await web3.eth.sendSignedTransaction(sign.rawTransaction);
      console.log("Liq add: success!", transaction.transactionHash);

    }catch(e:any){
      console.log(e.message);
    }
  })
}

module.exports = {
  addLiq
}
