pragma solidity ^0.8.0;


contract CreatePair{

address public factory;

constructor(address _factory){
  factory = _factory;
}

function createPair(address token1, address token2) external returns (address){
   (bool success, bytes memory data) = factory.call(abi.encodeWithSignature("createPair(address,address)", token1,token2));
   return abi.decode(data, (address));
}

function addLiquidityETH(
  address token,
  uint amountTokenDesired,
  uint amountTokenMin,
  uint amountETHMin,
  address to,
  uint deadline
  )
  external payable
  {
   address v2routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
   (bool success,) = v2routerAddress.call(abi.encodeWithSignature("addLiquidityETH(address,uint256,uint256,uin256,address,uint256)", token,
   amountTokenDesired,
   amountTokenMin,
   amountETHMin,
   to,
   deadline));
 }
}
