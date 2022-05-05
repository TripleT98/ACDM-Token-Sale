let { expect } = require("chai");
let hre = require("hardhat");
let {ethers} = hre;
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Signer, Contract, ContractFactory, BigNumber } from "ethers";
let Web3 = require("web3");
let {abi} = require("./MyERC20");

hre.Web3 = Web3;
hre.web3 = new Web3(hre.network.provider);
let web3 = hre.web3;

type StakeholderParams = {
  stake: string;
  timestamp: string;
  reward: string;
  exist: boolean;
}

function calcDif(a:string | number, b: string | number): string {
  return String(Number(a) - Number(b));
}

async function getBalance(address: string){
  return await ethers.provider.getBalance(address);
}

function calcSumm(a:string | number, b: string | number): string {
  return String(Number(a) + Number(b));
}

function getPrice(a:string | number, b: string | number): string {
  return String(Number(a) * Number(b));
}

function getFeeAmount(total:string, fee1: string, fee2: string): string {
  return String((Number(total)/100)*(Number(fee1) + Number(fee2)));
}

function  parseBalnce(balance:string): string {
    let str: string[] = balance.split("e+");
    let float = str[0].split(".");
    let num = Number(str[1]);
    let cum: string = float[0];
    for(let i = num, j = 0; i > 0; i--, j++){
      if(float[1][j] == undefined){
        cum = cum + "0";
        continue;
      }
      cum = cum + float[1][j];
    }
    return cum;
}

function encodeFunctionCall(func: string, params: string[], paramTypes: string[], paramValues: string[]):any | string {
  if(params.length != paramTypes.length || paramTypes.length != paramValues.length){
    return false;
  }
  let inputs = params.map((e,i)=>({name:e, type:paramTypes[i]}));
  return web3.eth.abi.encodeFunctionCall({
    name: func,
    type: "function",
    inputs
  }, paramValues)
}

function getStakeholderParams(params:any[]):StakeholderParams {
  return {
    stake: String(params[0]),
    timestamp: String(params[1]),
    reward: String(params[2]),
    exist: params[3],
  }
}

type TPropossl = {
  data: string;
  recepient: string;
  description: string;
  chairman: SignerWithAddress;
}



describe("Staking", async ()=>{

  let Staking: ContractFactory, staking: Contract,
      DAO: ContractFactory, dao: Contract,
      Trade: ContractFactory, trade: Contract,
      XXXToken: ContractFactory, xxxToken: Contract,
      ACDMToken: ContractFactory, acdmToken: Contract,
      owner: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress, user3: SignerWithAddress, chairman: SignerWithAddress,
      zeroAddr: Array<string> = new Array(40).fill("0");
      zeroAddr.unshift("0x");
      let zA:string = zeroAddr.join(""),
      buyAmount: number = 1000000000,
      unitPrice: string,
      saleAmount: string,
      ref1Fee:string,
      ref2Fee:string,
      fee:string;

    async function addProposal(obj:TPropossl):Promise<any> {
        return await dao.connect(obj.chairman).addProposal(obj.data, obj.recepient, obj.description);
    }

    async function mintAndApprove(mintTo: SignerWithAddress, approveTo: Contract, amount: string):Promise<any>{
        await acdmToken.connect(owner).mint(mintTo.address, amount);
        await acdmToken.connect(mintTo).approve(approveTo.address, amount);
    }

    function pars(str:string): number {
      let even = str.split(".");
      let num = even[0];
      return Number(num)*10**6;
    }

    async function increaseTime(time:number) {
     await web3.currentProvider._sendJsonRpcRequest({
       jsonrpc: '2.0',
       method: 'evm_increaseTime',
       params: [time],
       id: 0,
     }, () => {console.log("increace done!")});
     await web3.currentProvider._sendJsonRpcRequest({
       jsonrpc: '2.0',
       method: 'evm_mine',
       params: [],
       id: 0,
     }, () => {console.log("mining done!")});
     }

    let day: number = 60*60*24;
    let mintVal: string = String(10**20);
    let stakeVal: string = String(Math.ceil(Math.random()*10)*10**18);

    beforeEach(async ()=>{
       [owner,user1, user2, user3, chairman] = await ethers.getSigners();

       XXXToken = await ethers.getContractFactory("MyERC20");
       xxxToken = await XXXToken.connect(owner).deploy("XXXCoin", "XXX", 18);
       await xxxToken.deployed();

       ACDMToken = await ethers.getContractFactory("MyERC20");
       acdmToken = await ACDMToken.connect(owner).deploy("ACDMCoin", "ACDM", 6);
       await acdmToken.deployed();

       DAO = await ethers.getContractFactory("DAO");
       dao = await DAO.connect(owner).deploy(chairman.address, 3*day);
       await dao.deployed();

       Trade = await ethers.getContractFactory("Trade");
       trade = await Trade.connect(owner).deploy(3*day);
       await trade.deployed();

       Staking = await ethers.getContractFactory("Staking");
       staking = await Staking.connect(owner).deploy(xxxToken.address, acdmToken.address);
       await staking.deployed();

       await staking.connect(owner).setDAO(dao.address);
       await trade.connect(owner).setDAO(dao.address);
       await trade.connect(owner).setACDM(acdmToken.address);
       await acdmToken.connect(owner).addAdmin(trade.address);
       await trade.connect(owner).setSaleRound();
       await dao.connect(chairman).setStakingAddress(staking.address);


         await xxxToken.connect(owner).mint(owner.address, mintVal);
         await xxxToken.connect(owner).mint(user1.address, mintVal);
         await xxxToken.connect(owner).mint(user2.address, mintVal);
         await xxxToken.connect(owner).mint(user3.address, mintVal);

         await acdmToken.connect(owner).mint(staking.address, mintVal);

         await xxxToken.connect(user1).approve(staking.address, mintVal);
         await xxxToken.connect(user2).approve(staking.address, mintVal);
         await xxxToken.connect(user3).approve(staking.address, mintVal);
         await xxxToken.connect(owner).approve(staking.address, mintVal);

         await staking.connect(user1).stake(mintVal);
         await staking.connect(user2).stake(mintVal);
         await staking.connect(user3).stake(mintVal);
         await staking.connect(owner).stake(mintVal);


     })

  //addProposal(bytes calldata _signature, address _recepient, string calldata _description)


  it("Testing set fee function", async()=>{
    let prevFee: string = String(await trade.fee());
    let data: string = encodeFunctionCall("setFee", ["_fee"], ["uint256"], ["10"]);
    let recepient: string = trade.address;
    let description: string = "Set new fee to trading platform!";
    await addProposal({chairman, data, recepient, description});
    await dao.connect(user1).vote("1",true);
    await dao.connect(user2).vote("1",true);
    await dao.connect(user3).vote("1",false);
    await increaseTime(3*day);
    await dao.finish("1");
    expect(String(await trade.fee())).to.eq("10");
  })

  it("Testing set ref1Fee and set ref2Fee", async()=>{
    let prev1Fee: string = String(await trade.ref1Fee());
    let prev2Fee: string = String(await trade.ref2Fee());
    let dataFee1: string = encodeFunctionCall("setRef1Fee", ["_fee"], ["uint256"], ["4"]);
    let dataFee2: string = encodeFunctionCall("setRef2Fee", ["_fee"], ["uint256"], ["8"]);
    let description1: string = "Set new fee to referal 1!";
    let description2: string = "Set new fee to referal 2!";
    let recepient: string = trade.address;
    await addProposal({chairman, data:dataFee1, recepient, description:description1});
    await addProposal({chairman, data:dataFee2, recepient, description:description2});
    let prop1 = await dao.proposals("1");
    let prop2 = await dao.proposals("2");
    expect(dataFee1).to.eq(prop1.signature);
    expect(dataFee2).to.eq(prop2.signature);
  })

  it("Testing set setRewardTime and set setRewardShare", async()=>{
    let prev1Fee: string = String(await trade.ref1Fee());
    let prev2Fee: string = String(await trade.ref2Fee());
    let dataFee1: string = encodeFunctionCall("setRef1Fee", ["_fee"], ["uint256"], ["4"]);
    let dataFee2: string = encodeFunctionCall("setRef2Fee", ["_fee"], ["uint256"], ["8"]);
    let description1: string = "Set new fee to referal 1!";
    let description2: string = "Set new fee to referal 2!";
    let recepient: string = trade.address;
    await addProposal({chairman, data:dataFee1, recepient, description:description1});
    await addProposal({chairman, data:dataFee2, recepient, description:description2});
    let prop1 = await dao.proposals("1");
    let prop2 = await dao.proposals("2");
    expect(dataFee1).to.eq(prop1.signature);
    expect(dataFee2).to.eq(prop2.signature);
    expect(prev1Fee).not.to.eq(prop1.signature);
    expect(prev2Fee).not.to.eq(prop2.signature);
  })

  it("Cheking initial parameters", async()=>{
    expect(acdmToken.address).to.eq(await trade.ACDMToken());
    expect(3*day).to.eq(Number(await trade.roundDuration()));
    expect("0").to.eq(String(await trade.currentRound()));
    expect("25").to.eq(String(await trade.fee()));
    expect("5").to.eq(String(await trade.ref1Fee()));
    expect("3").to.eq(String(await trade.ref2Fee()));
    expect("0").to.eq(String(await trade.orderId()));
    expect("1000000").to.eq(String(await trade.ACDMMultiplier()));
    expect(1).to.eq(1);
  })

  it("Testing register function. Then we trying to get referals!", async()=>{
    await trade.connect(owner).register(zA);
    await trade.connect(user1).register(owner.address);
    await trade.connect(user2).register(user1.address);
    expect(String(await trade.referals(owner.address))).to.eq(zA);
    expect(String(await trade.referals(user1.address))).to.eq(owner.address);
    expect(String(await trade.referals(user2.address))).to.eq(user1.address);
    console.log("Cheking our referals!");
    expect(String(await trade.getReferals(owner.address))).to.eq(`${zA},${zA}`);
    expect(String(await trade.getReferals(user1.address))).to.eq(`${owner.address},${zA}`);
    expect(String(await trade.getReferals(user2.address))).to.eq(`${user1.address},${owner.address}`);
  })

  it("Testing Sale/Trade system", async()=>{
    let roundDuration: number = Number(await trade.roundDuration());
    let round = await trade.saleRound();
    unitPrice = String(round.unitPrice);
    saleAmount = String(round.tokenAmount);
    ref1Fee = String(await trade.ref1Fee());
    ref2Fee = String(await trade.ref2Fee());
    fee = String(Number(await trade.fee())/10);
    await trade.connect(user2).register(zA);
    await trade.connect(user1).register(user2.address);
    await trade.connect(owner).register(user1.address);
    let totalPrice: string = getPrice(unitPrice, buyAmount);
    expect(String(round.tokenAmount)).to.eq("100000000000");
    expect(String(round.unitPrice)).to.eq("10000000");
    expect(String(await acdmToken.balanceOf(trade.address))).to.eq(String(10**11));
    await expect(trade.connect(owner).buyTokens(buyAmount, {value:totalPrice})).to.emit(trade, "TokensBought").withArgs(owner.address, buyAmount, totalPrice);
    round = await trade.saleRound();
    let _fee: string = getFeeAmount(totalPrice, ref1Fee, ref2Fee);
    expect(String(await acdmToken.balanceOf(trade.address))).to.eq(calcDif(saleAmount, buyAmount));
    expect(await getBalance(trade.address)).to.eq(totalPrice);
    expect(String(round.tokenAmount)).to.eq(calcDif("100000000000", buyAmount));
    expect(String(await trade.balances(user1.address))).to.eq(getFeeAmount(totalPrice, ref1Fee,"0"));
    expect(String(await trade.balances(user2.address))).to.eq(getFeeAmount(totalPrice, ref2Fee,"0"));


    await increaseTime(2*roundDuration);
    await trade.setTradeRound();

    expect(await acdmToken.balanceOf(trade.address)).to.eq("0");

    let tokensAmount: string = "100000000";
    let tokenPrice: string = "100000000000000";
    let tradeAmount: number = 10000000;

    await mintAndApprove(user1, trade, tokensAmount);
    await mintAndApprove(user2, trade, tokensAmount);
    await mintAndApprove(owner, trade, tokensAmount);

    let u1tokenBalanceBefore = await acdmToken.balanceOf(user1.address);
    let u2tokenBalanceBefore = await acdmToken.balanceOf(user2.address);
    let ownerTokenBalanceBefore = await acdmToken.balanceOf(owner.address);

    await expect(trade.connect(user1).setOrder(tokensAmount, tokenPrice)).to.emit(trade, "OrderInitialized").withArgs(user1.address, "0", tokensAmount, tokenPrice);
    await trade.connect(user2).setOrder(tokensAmount, tokenPrice);
    await trade.connect(owner).setOrder(tokensAmount, tokenPrice);

    let order1 = await trade.getOrderById("0");
    let order2 = await trade.getOrderById("1");
    let order3 = await trade.getOrderById("2");

    let u1tokenBalanceAfter = await acdmToken.balanceOf(user1.address);
    let u2tokenBalanceAfter = await acdmToken.balanceOf(user2.address);
    let ownerTokenBalanceAfter = await acdmToken.balanceOf(owner.address);

    expect(String(u1tokenBalanceBefore)).to.eq(String(Number(order1.amount) + Number(u1tokenBalanceAfter)));
    expect(String(u2tokenBalanceBefore)).to.eq(String(Number(order2.amount) + Number(u2tokenBalanceAfter)));
    expect(String(u2tokenBalanceBefore)).to.eq(String(Number(order2.amount) + Number(u2tokenBalanceAfter)));

    let pay: string = String(tradeAmount*Number(order1.unitPrice));

    let roundBefore = await trade.tradeRound();
    let orderBefore = await trade.getOrderById("0");
    await trade.connect(user2).redeemOrder(tradeAmount, "0",{value:pay});
    let roundAfter = await trade.tradeRound();
    let orderAfter = await trade.getOrderById("0");

    expect(roundAfter.ethInTrade).to.eq(Number(roundBefore.ethInTrade) + Number(pay));
    expect(orderBefore.amount).to.eq(Number(orderAfter.amount) + Number(tradeAmount));

    let u1bb = String(await trade.balances(user1.address));
    let u2bb = String(await trade.balances(user2.address));

    orderBefore = await trade.getOrderById("1");
    await trade.connect(owner).redeemOrder(tradeAmount, "1",{value:pay});
    roundAfter = await trade.tradeRound();
    orderAfter = await trade.getOrderById("1");

    let u1ba = String(await trade.balances(user1.address));
    let u2ba = String(await trade.balances(user2.address));
    let refFee = getFeeAmount(pay, fee,"0");
    expect(calcDif(u2ba,u2bb)).to.eq(calcDif(pay,Number(refFee)));

    expect(roundAfter.ethInTrade).to.eq(Number(roundBefore.ethInTrade) + 2*Number(pay));
    expect(orderBefore.amount).to.eq(Number(orderAfter.amount) + Number(tradeAmount));

    await increaseTime(2*roundDuration);
    await trade.setSaleRound();



    expect(String(await trade.currentRound())).to.eq("0")
    let tradeRound = await trade.tradeRound();
    let saleRound = await trade.saleRound();
    expect(saleRound.tokenAmount).to.eq(pars(String(tradeRound.ethInTrade/saleRound.tokenPrice)));
    expect(saleRound.count).to.eq("2");



  });

let err_mess: string;

  describe("Testing DAO function`s", async()=>{
    it("Testing setMinQuorum function", async()=>{
      err_mess = "Error: Only chairman can add proposal!";
      let minQuorum: BigNumber = await dao.minimumQuorum();
      await dao.connect(chairman).setMinQuorum("50");
      expect(String(await dao.minimumQuorum())).to.eq("50");
      expect(minQuorum).not.to.eq(await dao.minimumQuorum());
      await expect(dao.connect(user1).setMinQuorum("50")).to.be.revertedWith(err_mess);
      err_mess = "Error: Invalid minimum quorum value!";
      await expect(dao.connect(chairman).setMinQuorum("101")).to.be.revertedWith(err_mess);
    })

    it("Testing setVoteDuration function", async()=>{
      await dao.connect(chairman).setVoteDuration("1");
      expect(await dao.voteDuration()).to.eq(1);
      err_mess = "Error: Only chairman can add proposal!";
      await expect(dao.connect(user1).setVoteDuration("50")).to.be.revertedWith(err_mess);
    })

    it("Testing setStakingAddress", async()=>{
      await dao.connect(chairman).setStakingAddress(user1.address);
      expect(await dao.staking()).to.eq(user1.address);
    })

    it("Testing setNewChairman function", async()=>{
      await dao.connect(chairman).setNewChairman(user1.address);
      expect(await dao.chairman()).to.eq(user1.address);
      err_mess = "Error: New chairman is zero address!";
      await expect(dao.connect(user1).setNewChairman(zA)).to.be.revertedWith(err_mess);
      err_mess = "Error: Address of new chairman is equal to old one`s address!";
      await expect(dao.connect(user1).setNewChairman(user1.address)).to.be.revertedWith(err_mess);
    })

    it("Testing addProposal function", async()=>{
      err_mess = "Error: Empty signature!";
      await expect(dao.connect(chairman).addProposal("0x", user1.address, "aaa")).to.be.revertedWith(err_mess);
      err_mess = "Error: Zero address of recepient!";
      await expect(dao.connect(chairman).addProposal("0x11", zA, "aaa")).to.be.revertedWith(err_mess);
      err_mess = "Error: Proposal with such a signature is already exists!";
      await dao.connect(chairman).addProposal("0x111111", user1.address, "aaa");
      await expect(dao.connect(chairman).addProposal("0x111111", user1.address, "aaa")).to.be.revertedWith(err_mess);
    })

    it("Testing vote fnction", async()=>{
      await dao.connect(chairman).addProposal("0x111111", user1.address, "aaa");
      err_mess = "Error: Your staking balance is equals to zero!";
      await expect(dao.connect(chairman).vote("1", true)).to.be.revertedWith(err_mess);
      err_mess = "Error: Can`t vote twice on the same proposal!";
      await dao.connect(user1).vote("1", true);
      await expect(dao.connect(user1).vote("1", true)).to.be.revertedWith(err_mess);
    })

    it("Testing finish proposal function", async()=>{
      err_mess = "Error: Can`t finish this proposal yet!";
      await dao.connect(chairman).addProposal("0x111111", user1.address, "aaa");
      await expect(dao.connect(user1).finish("1")).to.be.revertedWith(err_mess);
      await increaseTime(3*day);
      await dao.connect(user1).vote("1", true);
      await dao.connect(chairman).setMinQuorum("100");
      err_mess = "Error: Can`t finish this proposal while enough tokens not used in vote";
      await expect(dao.connect(user1).finish("1")).to.be.revertedWith(err_mess);
      await dao.connect(user2).vote("1", false);
      await dao.connect(chairman).setMinQuorum("40");
      err_mess = "Error: Votes are equal!";
      await expect(dao.connect(user1).finish("1")).to.be.revertedWith(err_mess);
      await dao.connect(owner).vote("1", false);
      await expect(dao.connect(user1).finish("1")).to.emit(dao, "ProposalFinished").withArgs("1", 1, user1.address);
    })



  })

  describe("Testing staking contract", async()=>{

    it("Testing stake function", async()=>{
      err_mess = "Error: Staking without allowance!";
      await expect(staking.connect(chairman).stake("100")).to.be.revertedWith(err_mess);
      await xxxToken.connect(owner).mint(user1.address, mintVal);
      await xxxToken.connect(user1).approve(staking.address, mintVal);
    })

    it("Testing claim function", async()=>{
      err_mess = "This user is not stakeholder!";
      await expect(staking.connect(chairman).claim()).to.be.revertedWith(err_mess);
      await increaseTime(3*day);
      await expect(staking.connect(user1).claim()).to.emit(staking, "Claim").withArgs(user1.address, "3000000000000000000");
    })

    it("Testing unstake function", async()=>{
      err_mess = "Error: Tokens locked!";
      await expect(staking.connect(user1).unstake("1")).to.be.revertedWith(err_mess);
      err_mess = "You have no such a big amount of stake tokens!";
      await increaseTime(3*day);
      await expect(staking.connect(user1).unstake("100000000000000000001")).to.be.revertedWith(err_mess);

    })

  })


  describe("Testing reverts with error", async()=>{



    it("Trying to buy zero tokens", async()=>{
      err_mess = "Error: Zero amount!";
      await expect(trade.connect(owner).buyTokens("0", {value: "1"})).to.be.revertedWith(err_mess);
    })

    it("Trying to buy tokens, sending not enough ethers", async()=>{
      err_mess = "Error: Not enought ethers to buy this amount of tokens!";
      await expect(trade.connect(owner).buyTokens("100", {value: "1"})).to.be.revertedWith(err_mess);
    })

    it("Trying to buy too big amount of tokens", async()=>{
      err_mess = "Error: Not enought tokens remain";
      let round = await trade.saleRound();
      await expect(trade.connect(owner).buyTokens(Number(round.tokenAmount)*2, {value: "1"})).to.be.revertedWith(err_mess);
    })

    it("Trying to register twice!", async()=>{
      err_mess = "Error: You`re already registered!";
      await trade.connect(owner).register(user1.address);
      await expect(trade.connect(owner).register(user1.address)).to.be.revertedWith(err_mess);
    })

    it("Trying to send our address as referal", async()=>{
      err_mess = "Error: Referal`s address equals to yours!";
      await expect(trade.connect(owner).register(owner.address)).to.be.revertedWith(err_mess);
    })

    it("Trying to switch rounds while time hasn't come!", async()=>{
      err_mess = "Error: It is not time yet for trade!";
      await expect(trade.setTradeRound()).to.be.revertedWith(err_mess);
    })

  })

});
