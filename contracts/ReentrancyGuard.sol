// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract ReentrancyGuard{

  uint private _status;
  uint private constant _ENTERED = 1;
  uint private constant _NOT_ENTERED = 2;

  constructor(){
    _status = _NOT_ENTERED;
  }

  modifier Reentrancy(){
    require(_status == _NOT_ENTERED, "Error: ReentrancyGuard");
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
  }

}
