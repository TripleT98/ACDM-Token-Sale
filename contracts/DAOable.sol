pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

contract DAOable{

  address DAO;

  modifier OnlyDAO(){
    require(msg.sender == DAO, "Error: This function accessed only for DAO!");
    _;
  }

  constructor(address _DAO){
    DAO = _DAO;
  }

}
