import {
  stakingToken, web3, task, envParams, getSign, staking, dao, trade, rewardToken
} from "./tasks";

type tArgsType = {
  gaslimit: string;
  amount: string;
  privatekey: string;
  id: string;
}

function finish(){
  task("finish", "Finish proposal")
  .addParam("gaslimit", "gaslimit")
  .addParam("privatekey", "Private key")
  .addParam("id", "Description")
  .setAction(async(tArgs:tArgsType)=>{
    try{
      let {gaslimit, privatekey, id} = tArgs;

      let data = await dao.methods.finish(id).encodeABI();
      let sign = await getSign({gaslimit,data,privatekey,to: envParams.DAO});
      let transaction = await web3.eth.sendSignedTransaction(sign.rawTransaction);
      console.log("Finish proposal: success!", transaction.transactionHash);

    }catch(e:any){
      console.log(e.message);
    }
  })
}

module.exports = {
  finish
}
