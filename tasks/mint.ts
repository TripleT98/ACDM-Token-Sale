import {
  stakingToken, web3, task, envParams, getSign, staking, dao, trade, rewardToken
} from "./tasks";

type tArgsType = {
  gaslimit: string;
  privatekey: string;
  amount: string;
  to: string;
}

function mint(){
  task("mint", "Mint staking tokens")
  .addParam("gaslimit", "gaslimit")
  .addParam("privatekey", "Private key")
  .addParam("to", "To")
  .addParam("amount", "Tokens amount")
  .setAction(async(tArgs:tArgsType)=>{
    try{
      let {gaslimit, amount, privatekey, to} = tArgs;

      let data = await stakingToken.methods.mint(to, amount).encodeABI();
      let sign = await getSign({gaslimit,data,privatekey,value, to: stakingToken.address});
      let transaction = await web3.eth.sendSignedTransaction(sign.rawTransaction);
      console.log("Mint: success!", transaction.transactionHash);

    }catch(e:any){
      console.log(e.message);
    }
  })
}

module.exports = {
  mint
}
