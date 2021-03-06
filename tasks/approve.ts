import {
  stakingToken, web3, task, envParams, getSign, staking, rewardToken
} from "./tasks";

type tArgsType = {
  gaslimit: string;
  privatekey: string;
  amount: string;
  to: string;
}

function approve(){
  task("approve", "Approve staking tokens")
  .addParam("gaslimit", "gaslimit")
  .addParam("privatekey", "Private key")
  .addParam("to", "To")
  .addParam("amount", "Tokens amount")
  .setAction(async(tArgs:tArgsType)=>{
    try{
      let {gaslimit, amount, privatekey, to} = tArgs;

      let data = await stakingToken.methods.approve(to, amount).encodeABI();
      let sign = await getSign({gaslimit,data,privatekey, to: envParams.XXX_TOKEN as string});
      let transaction = await web3.eth.sendSignedTransaction(sign.rawTransaction);
      console.log("Approve: success!", transaction.transactionHash);

    }catch(e:any){
      console.log(e.message);
    }
  })
}

module.exports = {
  approve
}
