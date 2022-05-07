import {
  stakingToken, web3, task, envParams, getSign, staking, dao, rewardToken
} from "./tasks";

type tArgsType = {
  gaslimit: string;
  privatekey: string;
}

function claim(){
  task("claim", "Claim reward tokens")
  .addParam("gaslimit", "gaslimit")
  .addParam("privatekey", "Private key")
  .setAction(async(tArgs:tArgsType)=>{
    try{
      let {gaslimit, privatekey} = tArgs;

      let data = await staking.methods.claim().encodeABI();
      let sign = await getSign({gaslimit,data,privatekey, to: envParams.STAKING_ADDRESS as string});
      let transaction = await web3.eth.sendSignedTransaction(sign.rawTransaction);
      console.log("Claim: success!", transaction.transactionHash);

    }catch(e:any){
      console.log(e.message);
    }
  })
}

module.exports = {
  claim
}
