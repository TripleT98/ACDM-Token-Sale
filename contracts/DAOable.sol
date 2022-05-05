pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

contract DAOable{
  address public admin;
  address DAO;

  modifier OnlyDAO(){
    require(msg.sender == DAO, "Error: This function accessed only for DAO!");
    _;
  }

  constructor(){
    admin = msg.sender;
  }

  function setDAO(address _DAO) public {
    require(admin == msg.sender, "Error: Only admin has access!");
    DAO = _DAO;
  }

}
