// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";

contract Trade is ReentrancyGuard {

  address public ACDMToken;
  uint public roundDuration;
  Rounds public currentRound;
  SaleRound public saleRound;
  TradeRound public tradeRound;
  uint public ref1Fee = 3;
  uint public ref2Fee = 2;
  uint public fee = 3;
  uint256 orderId;


  mapping (address=>address) public referals;

  struct Order {
    address payable owner;
    uint256 amount;
    uint256 price;
  }

  struct SaleRound {
    uint256 endTime;
    uint256 tokenPrice;
    uint256 tokenAmount;
  }

  struct TradeRound {
    uint256 endTime;
    uint256 ethInTrade;
    mapping (uint256 => Order) orders;
  }

  enum Rounds{
    Sale,
    Trade
  }

  modifier OnlySaleRound(){
    require(currentRound == Rounds.Sale, "Error: Current round is sale round!");
    bool isSaleRound = saleRound.endTime >= block.timestamp;
    if(!isSaleRound){
      setTradesRound();
      revert("Error: Sale round is already finished!");
    }
    _;
  }

  modifier OnlyTradeRound(){
    require(currentRound == Rounds.Trade, "Error: Current round is trade round!");
    bool isTradeRound = tradeRound.endTime >= block.timestamp;
    if(!isTradeRound){
      setSaleRound();
      revert("Error: Trade round is already finished!");
    }
    _;
  }

  event OrderInitialized(address indexed owner, uint indexed id, uint amount, uint price);
  event Buy(address indexed owner, address indexed buyer, uint indexed id, uint amount, uint price);
  event OrderClosed(address indexed owner, uint id);

  constructor(address _ACDMToken, uint _roundDuration){
    ACDMToken = _ACDMToken;
    roundDuration = _roundDuration;
    currentRound = Rounds.Sale;
    tradeRound.ethInTrade = 1 ether;
    saleRound.tokenPrice = 1000000000000 wei;
    saleRound.endTime = block.timestamp + _roundDuration;
    saleRound.tokenAmount = tradeRound.ethInTrade/saleRound.tokenPrice;
    (bool success,) = ACDMToken.call(abi.encodeWithSignature("mint(address,uint256)", address(this), saleRound.tokenAmount));
    require(success, "Error: Can`t mint tokens to this address!");
  }

  function setSaleRound() OnlyTradeRound internal {
    require(tradeRound.endTime >= block.timestamp, "Error: It is not time yet!");
    currentRound = Rounds.Sale;
    saleRound.endTime = block.timestamp + roundDuration;
    saleRound.tokenPrice += (saleRound.tokenPrice/100)*3 + 400000000000;
    saleRound.tokenAmount = tradeRound.ethInTrade/saleRound.tokenPrice;
    (bool success,) = ACDMToken.call(abi.encodeWithSignature("mint(address,uint256)", address(this), saleRound.tokenAmount));
    require(success, "Error: Can`t set sale round!");
  }

  function setTradesRound() OnlySaleRound internal {
    require(saleRound.endTime >= block.timestamp, "Error: It is not time yet!");
    (bool success,) = ACDMToken.call(abi.encodeWithSignature("burn(address,uint256)", address(this), saleRound.tokenAmount));
    require(success, "Error: Can`t set trage round!");
    currentRound = Rounds.Trade;
    tradeRound.endTime = block.timestamp + roundDuration;
    tradeRound.ethInTrade = 0;
  }

  function register(address _referal) public {
    require(referals[msg.sender] == address(0), "Error: You`re already registered!");
    require(referals[msg.sender] != _referal, "Error: Referal`s address equals to yours!");
    referals[msg.sender] = _referal;
  }

  function _transferFrom(address _from, address _to, uint _amount) internal returns(bool success) {
    (success, ) = ACDMToken.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _amount));
  }

  function _transfer(address _to, uint _amount) internal returns(bool success) {
    (success, ) = ACDMToken.call(abi.encodeWithSignature("transfer(address,uint256)", _to, _amount));
  }

  function getReferals(address _user) view public returns(address _referal1, address _referal2) {
    _referal1 = referals[_user];
    _referal2 = referals[_referal1];
  }

  function setOrder(uint _amount, uint _oneTokenPrice) OnlyTradeRound public {
    require(_amount != 0, "Error: Zero amount!");
    require(_oneTokenPrice != 0, "Error: Zero token price!");
    bool isTransferFromSuccessed = _transferFrom(msg.sender, address(this), _amount);
    require(isTransferFromSuccessed, "Error: transferFrom failed!");
    tradeRound.orders[orderId].amount = _amount;
    tradeRound.orders[orderId].price = _oneTokenPrice;
    tradeRound.orders[orderId].owner = payable(msg.sender);
    emit OrderInitialized(msg.sender, orderId, _amount, _oneTokenPrice);
    orderId++;
  }

  function deleteOrder(uint _id) public {
    require(tradeRound.orders[_id].owner == msg.sender, "Error: You`re not owner of this order!");
    delete tradeRound.orders[_id];
    emit OrderClosed(msg.sender, _id);
  }

  function buyOrder(uint _amount, uint _id) Reentrancy OnlyTradeRound payable public {
    require(_amount != 0, "Error: Zero amount!");
    Order storage currentOrder = tradeRound.orders[_id];
    require(currentOrder.amount >= _amount, "Error: To low order`s amount!");
    uint totalPrice = currentOrder.price * currentOrder.amount;
    require(msg.value >= totalPrice, "Error: Not enought ether!");
    uint overage = msg.value - totalPrice;
    require(_transfer(msg.sender, _amount), "Error: Transfer error!");
    currentOrder.amount -= _amount;
    if(overage != 0){
      payable(msg.sender).call{value:overage}("");
    }
    uint _fee = (totalPrice/100)*fee;
    currentOrder.owner.transfer(totalPrice - _fee);
    tradeRound.ethInTrade += totalPrice;
    emit Buy(currentOrder.owner, msg.sender, _id, _amount, currentOrder.price);
    if(currentOrder.amount == 0){
      delete tradeRound.orders[_id];
      emit OrderClosed(currentOrder.owner, _id);
    }
  }

  function buyTokens(uint _amount) payable Reentrancy OnlySaleRound public {
    require(_amount != 0, "Error: Zero amount!");
    require(saleRound.tokenAmount >= _amount, "Error: Not enought tokens remain!");
    uint totalPrice = _amount * saleRound.tokenPrice;
    require(msg.value >= totalPrice, "Error: Not enought ethers to buy this amount of tokens!");
    bool _success = _transfer(msg.sender, _amount);
    require(_success, "Error: Can`t transfer tokens!");
    (address ref1, address ref2) = getReferals(msg.sender);
    if(ref1 == address(0) && ref2 == address(0)){

    }else if(ref1 != address(0) && ref2 == address(0)){
      payable(ref1).transfer((msg.value/100)*(ref1Fee + ref2Fee));
    }else{
      payable(ref1).transfer((msg.value/100)*(ref1Fee));
      payable(ref2).transfer((msg.value/100)*(ref2Fee));
    }
    saleRound.tokenAmount -= _amount;
  }

}
