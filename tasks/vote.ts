import {
  stakingToken, web3, task, envParams, getSign, staking, dao, trade, rewardToken
} from "./tasks";

type tArgsType = {
  gaslimit: string;
  privatekey: string;
  id: string;
  vote: string;
}

function vote(){
  task("vote", "Vote to any proposal")
  .addParam("gaslimit", "gaslimit")
  .addParam("privatekey", "Private key")
  .addParam("id", "order`s id")
  .addParam("vote", "Your vote")
  .setAction(async(tArgs:tArgsType)=>{
    try{
      let {gaslimit, privatekey, vote, id} = tArgs;

      let data = await trade.dao.vote(id,vote).encodeABI();
      let sign = await getSign({gaslimit,data,privatekey,to: envParams.DAO as string});
      let transaction = await web3.eth.sendSignedTransaction(sign.rawTransaction);
      console.log("Vote: success!", transaction.transactionHash);

    }catch(e:any){
      console.log(e.message);
    }
  })
}
