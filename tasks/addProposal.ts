import {
  stakingToken, web3, task, envParams, getSign, staking, dao, trade, rewardToken
} from "./tasks";

type tArgsType = {
  gaslimit: string;
  amount: string;
  privatekey: string;
  signature: string;
  recepient: string;
  description: string;
}

function addProposal(){
  task("addproposal", "Add proposal to dao")
  .addParam("gaslimit", "gaslimit")
  .addParam("privatekey", "Private key")
  .addParam("signature", "Function`s signature u wanna call")
  .addParam("recepient", "Address of recepient")
  .addParam("description", "Description")
  .setAction(async(tArgs:tArgsType)=>{
    try{
      let {gaslimit, amount, privatekey, signature, recepient, description} = tArgs;

      let data = await trade.dao.addProposal(amount).encodeABI();
      let sign = await getSign({gaslimit,data,privatekey,to: dao.address});
      let transaction = await web3.eth.sendSignedTransaction(sign.rawTransaction);
      console.log("Add proposal: success!", transaction.transactionHash);

    }catch(e:any){
      console.log(e.message);
    }
  })
}

module.exports = {
  addProposal
}
