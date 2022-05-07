// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./DAOable.sol";
import "./ERC20.sol";
import "hardhat/console.sol";
contract TradeA is ReentrancyGuard, DAOable {

  address public ACDMToken;
  uint public roundDuration;
  Rounds public currentRound = Rounds.None;
  SaleRound public saleRound;
  TradeRound public tradeRound;
  uint public fee = 25;
  uint public ref1Fee = 5;
  uint public ref2Fee = 3;
  uint public orderId;
  uint public ACDMMultiplier;
  mapping(address=>uint) public balances;

  function setFee(uint _fee) public OnlyDAO {
    require(_fee < 500, "bidFee");
    fee = _fee;
  }

  function setRef1Fee(uint _fee) public OnlyDAO {
    require(_fee + ref2Fee < 100, "bidFee");
    ref1Fee = _fee;
  }

  function setRef2Fee(uint _fee) public OnlyDAO {
    require(_fee + ref1Fee < 100, "bidFee");
    ref2Fee = _fee;
  }

  mapping (address=>address) public referals;

  struct Order {
    address payable owner;
    uint256 amount;
    uint256 price;
    uint256 unitPrice;
  }

  struct SaleRound {
    uint count;
    uint256 endTime;
    uint256 tokenPrice;
    uint256 tokenAmount;
    uint256 unitPrice;
  }

  struct TradeRound {
    uint count;
    uint256 endTime;
    uint256 ethInTrade;
    mapping (uint256 => Order) orders;
  }

  enum Rounds{
    Sale,
    Trade,
    None
  }

  modifier OnlySaleRound(){
    require(currentRound == Rounds.Sale, "error_round");
    bool isSaleRound = saleRound.endTime >= block.timestamp;
    if(!isSaleRound && currentRound == Rounds.Sale){
      _setTradeRound();
    }else{
    _;
    }
  }

  modifier OnlyTradeRound(){
    require(currentRound == Rounds.Trade || currentRound == Rounds.None, "error_round");
    bool isTradeRound = tradeRound.endTime >= block.timestamp;
    if(!isTradeRound && currentRound == Rounds.Trade){
      _setSaleRound();
    }else{
    _;
    }
  }

  event OrderInitialized(address indexed owner, uint indexed id, uint amount, uint price);
  event Buy(address indexed owner, address indexed buyer, uint indexed id, uint amount, uint price);
  event OrderClosed(address indexed owner, uint id);
  event TokensBought(address indexed buyer, uint amount, uint price);
  event TradeRoundStarts(uint indexed count, uint startTime);
  event SaleRoundStarts(uint indexed count, uint startTime, uint tokensToSale, uint tokenPrice);
  event TradeRoundEnds(uint indexed count, uint endTime, uint ethInTrade);
  event SaleRoundEnds(uint indexed count, uint endTime, uint tokensNotSold);

  constructor(uint _roundDuration) DAOable() {
    roundDuration = _roundDuration;
    tradeRound.ethInTrade = 1 ether;
  }

  function getOrderById(uint _id) public view returns(Order memory){
    require(tradeRound.orders[_id].owner != address(0), "Not exist!");
    return tradeRound.orders[_id];
  }

  function setACDM(address _acdm) public {
    require(msg.sender == admin, "error_admin");
    ACDMToken = _acdm;
  }

  function withdrawEth() Reentrancy public  {
    require(balances[msg.sender] > 0, "error_zero");
    payable(msg.sender).transfer(balances[msg.sender]);
    balances[msg.sender] = 0;
  }

  function _setSaleRound() internal {
    if(currentRound == Rounds.None){
      require(ACDMToken != address(0), "error_zeroACDM");
      (bool success, bytes memory data) = ACDMToken.call(abi.encodeWithSignature("decimals()"));
      require(success, "error_decimals!");
      ACDMMultiplier = abi.decode(data, (uint));
      ACDMMultiplier = 10**ACDMMultiplier;
      saleRound.tokenPrice = 10000000000000 wei;
    }else{
      require(tradeRound.endTime <= block.timestamp, "error_time");
      saleRound.tokenPrice += (saleRound.tokenPrice/100)*3 + 4000000000000;

      emit TradeRoundEnds(tradeRound.count, block.timestamp, tradeRound.ethInTrade);
    }
      saleRound.endTime = block.timestamp + roundDuration;
      saleRound.tokenAmount = (tradeRound.ethInTrade/saleRound.tokenPrice)*ACDMMultiplier;
      saleRound.unitPrice = saleRound.tokenPrice / ACDMMultiplier;
      (bool success,) = ACDMToken.call(abi.encodeWithSignature("mint(address,uint256)", address(this), saleRound.tokenAmount));
      require(success, "error_sale");

      emit SaleRoundStarts(saleRound.count, block.timestamp, saleRound.tokenAmount, saleRound.tokenPrice);

      saleRound.count++;
      currentRound = Rounds.Sale;
  }

  function setSaleRound() OnlyTradeRound public {
    _setSaleRound();
  }

  function _setTradeRound() internal {
    require(saleRound.endTime <= block.timestamp, "error_time");
    (bool success,) = ACDMToken.call(abi.encodeWithSignature("burn(address,uint256)", address(this), saleRound.tokenAmount));
    require(success, "error_trade");
    tradeRound.endTime = block.timestamp + roundDuration;
    tradeRound.ethInTrade = 0;

    emit SaleRoundEnds(saleRound.count, block.timestamp, saleRound.tokenAmount);
    emit TradeRoundStarts(tradeRound.count, block.timestamp);

    tradeRound.count++;
    currentRound = Rounds.Trade;
  }

  function setTradeRound() OnlySaleRound public {
    _setTradeRound();
  }

  function register(address _referal) public {
    require(referals[msg.sender] == address(0), "error_register");
    require(msg.sender != _referal, "error_referal");
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
    require(_amount != 0, "error_zero");
    require(_oneTokenPrice != 0, "error_price");
    bool isTransferFromSuccessed = _transferFrom(msg.sender, address(this), _amount);
    require(isTransferFromSuccessed, "error_transfer");
    tradeRound.orders[orderId].amount = _amount;
    tradeRound.orders[orderId].price = _oneTokenPrice;
    tradeRound.orders[orderId].unitPrice = _oneTokenPrice / ACDMMultiplier;
    tradeRound.orders[orderId].owner = payable(msg.sender);
    emit OrderInitialized(msg.sender, orderId, _amount, _oneTokenPrice);
    orderId++;
  }

  function deleteOrder(uint _id) public {
    require(tradeRound.orders[_id].owner == msg.sender, "error_owner");
    delete tradeRound.orders[_id];
    emit OrderClosed(msg.sender, _id);
  }

  function redeemOrder(uint _amount, uint _id) OnlyTradeRound payable public {
    require(_amount != 0, "error_zero");
    Order storage currentOrder = tradeRound.orders[_id];
    require(currentOrder.owner != msg.sender, "error_redeem");
    require(currentOrder.amount >= _amount, "error_amountToken");
    uint totalPrice = currentOrder.unitPrice * _amount;
    require(msg.value >= totalPrice, "error_eth");
    uint overage = msg.value - totalPrice;
    require(_transfer(msg.sender, _amount), "error_transfer");
    currentOrder.amount -= _amount;
    if(overage != 0){
      balances[currentOrder.owner] += overage;
    }
    address ref1 = referals[msg.sender] == address(0)?DAO:referals[msg.sender];
    address ref2 = referals[ref1] == address(0)?DAO:referals[ref1];
      balances[ref1] += ((totalPrice/1000)*(fee));
      balances[ref2] += ((totalPrice/1000)*(fee));
    uint _fee = (totalPrice/1000)*(2*fee);
    balances[currentOrder.owner] += (totalPrice - _fee);
    tradeRound.ethInTrade += totalPrice;
    emit Buy(currentOrder.owner, msg.sender, _id, _amount, currentOrder.price);
    if(currentOrder.amount == 0){
      emit OrderClosed(currentOrder.owner, _id);
      delete tradeRound.orders[_id];
    }
  }

  function buyTokens(uint _amount) payable Reentrancy OnlySaleRound public {
    require(_amount != 0, "zero_amount");
    require(saleRound.tokenAmount >= _amount, "error_amountToken");
    uint totalPrice = _amount * saleRound.unitPrice;
    require(msg.value >= totalPrice, "error_amountETH");
    uint overage = msg.value - totalPrice;
    bool _success = _transfer(msg.sender, _amount);
    require(_success, "error_transfer");
    if(overage != 0){
      balances[msg.sender] += overage;
    }
    (address ref1, address ref2) = getReferals(msg.sender);
    if(ref1 != address(0)){
        balances[ref1] += ((totalPrice/100)*ref1Fee);
    }
    if(ref2 != address(0)){
        balances[ref2] += ((totalPrice/100)*ref2Fee);
    }
    saleRound.tokenAmount -= _amount;
    emit TokensBought(msg.sender, _amount, totalPrice);
  }



}
