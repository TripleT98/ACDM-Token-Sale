//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";


contract Adminable{

  mapping (address => bool) public admins;

  constructor(){
    admins[msg.sender] = true;
  }

  modifier onlyAdmin(){
    require(admins[msg.sender], "Only Admin has access to this method!");
    _;
  }

  function addAdmin(address _newAdmin) public onlyAdmin{
    admins[_newAdmin] = true;
  }

}


contract MyERC20 is Adminable{

  string public name;
  string public symbol;
  uint public decimals;
  uint public totalSuply;

  mapping (address => uint) private _balances;
  mapping (address => mapping(address => uint)) private _allowances;

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);

  constructor(string memory _name, string memory _symbol, uint _decimals){
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }

  function mint(address _to, uint _value)
    public
    onlyAdmin
    {
      totalSuply += _value;
      _balances[_to] += _value;
      emit Transfer(address(0), _to, _value);
    }

  function burn(address _from, uint _value)
    public
    {
      require(msg.sender == _from || admins[msg.sender], "You cant burn tokens from this address!");
      require(_balances[_from] >= _value, "You haven't such a big amount of tokens to burn!");
      totalSuply -= _value;
      _balances[_from] -= _value;
      emit Transfer(_from, address(0), _value);
    }

  function balanceOf(address _owner) public view returns(uint){
    uint balance = _balances[_owner];
    return balance;
  }

  function transfer(address _to, uint _value)
   external
   returns(bool)
   {
    require(_balances[msg.sender] >= _value, "You have not enough MyERC20 tokens to transfer!");
    _balances[msg.sender] -= _value;
    _balances[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

 function transferFrom(address _from, address _to, uint _value)
  public
  returns(bool)
  {
    require(_allowances[_from][_to] >= _value, "You have not allowances to withdraw this amount of tokens!");
    require(_balances[_from] >= _value, "Address you want to withdraw from has not enough tokens!");
    _allowances[_from][_to] -= _value;
    _balances[_from] -= _value;
    _balances[_to] += _value;
    emit Transfer(_from, _to, _value);
    return true;
 }

  function approve(address _to, uint _value) public returns(bool){
    require(_balances[msg.sender] >= _value, "You have not enough MyERC20 tokens to approve!");
    _allowances[msg.sender][_to] += _value;
    emit Approval(msg.sender, _to, _value);
    return true;
  }

 function allowance(address _owner, address _spender) public view returns(uint){
   uint remaining = _allowances[_owner][_spender];
   return remaining;
 }

 function increaseAllowance(address _spender, uint _value)
    public
 {
    require(_balances[msg.sender] >= _value + _allowances[msg.sender][_spender], "Not enough tokens to allow!");
    _allowances[msg.sender][_spender] += _value;
    emit Approval(msg.sender, _spender, allowance(msg.sender, _spender));
 }

 function decreaseAllowance(address _spender, uint _value)
    public
 {
    require(_allowances[msg.sender][_spender] >= _value, "Allowance is less than zero!");
    _allowances[msg.sender][_spender] -= _value;
    emit Approval(msg.sender, _spender, allowance(msg.sender, _spender));
 }
}
