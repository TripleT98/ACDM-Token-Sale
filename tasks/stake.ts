import {
  stakingToken, web3, task, envParams, getSign, staking, dao, trade, rewardToken
} from "./tasks";

type tArgsType = {
  gaslimit: string;
  amount: string;
  privatekey: string;
}

function stake(){
  task("stake", "stake tokens")
  .addParam("gaslimit", "gaslimit")
  .addParam("privatekey", "Private key")
  .addParam("amount", "Amount of tokens")
  .setAction(async(tArgs:tArgsType)=>{
    try{
      let {gaslimit, amount, privatekey} = tArgs;

      let data = await staking.methods.stake(amount).encodeABI();
      let sign = await getSign({gaslimit,data,privatekey,value, to: staking.address});
      let transaction = await web3.eth.sendSignedTransaction(sign.rawTransaction);
      console.log("Stake: success!", transaction.transactionHash);

    }catch(e:any){
      console.log(e.message);
    }
  })
}

module.exports = {
  stake
}
