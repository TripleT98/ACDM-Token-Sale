pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT


import "hardhat/console.sol";
import "./DAOable.sol";
import "./ReentrancyGuard.sol";


contract Staking is DAOable, ReentrancyGuard{

  address public stakingToken;
  address public rewardToken;

  uint public freezeTime = 259200;
  uint public rewardShare = 3;

  modifier isStakeholderExist(){
    require(stakeholders[msg.sender].isExist, "Error: This user is not stakeholder!");
    _;
  }

  function setFreezeTime(uint _freezeTime) OnlyDAO public {
    freezeTime = _freezeTime;
  }

  function setRewardShare(uint _rewardShare) OnlyDAO public {
    rewardShare = _rewardShare;
  }

  struct Stakeholder{
    uint256 stake;
    uint256 reward;
    uint256 timestamp;
    bool isExist;
  }

  event Stake(address indexed stakeholder, uint amount, uint timestamp);
  event Unstake(address indexed stakeholder, uint amount, uint remain);
  event Claim(address indexed stakeholder, uint amount);

  mapping (address=>Stakeholder) public stakeholders;

  constructor(address XXXToken, address ACDMToken, address _DAO) DAOable(_DAO) {
    stakingToken = XXXToken;
    rewardToken = ACDMToken;
  }

  function getStake(address _stakeholder) view public returns(uint) {
    return stakeholders[_stakeholder].stake;
  }

  function stake(uint _amount) public Reentrancy {
    (bool success, bytes memory data) = stakingToken.call(abi.encodeWithSignature("allowance(address,address)", msg.sender, address(this)));
    uint allowanceAmount = abi.decode(data, (uint));
    require(allowanceAmount >= _amount, "Error: Staking token contract has no allowances to transfer this token amount from you!");
    (success,) = stakingToken.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender, address(this), _amount));
    require(success, "Error: Can`t transfer tokend from your address!");

    Stakeholder storage _current_stakeholder = stakeholders[msg.sender];

    if(!_current_stakeholder.isExist){
      _current_stakeholder.isExist = true;
    }

    _current_stakeholder.stake += _amount;
    _current_stakeholder.timestamp = block.timestamp;
    emit Stake(msg.sender, _amount, block.timestamp);
  }

  function claim() Reentrancy isStakeholderExist public {
    Stakeholder storage _stakeholder = stakeholders[msg.sender];

    require(_stakeholder.stake > 0, "Your stake is equals to zero!");

    uint reward_stack = (block.timestamp - _stakeholder.timestamp)/freezeTime;
    uint reward_percent = reward_stack*rewardShare;
    _stakeholder.reward = (_stakeholder.stake/100)*reward_percent;
    _stakeholder.timestamp = _stakeholder.timestamp + (reward_stack*freezeTime);

    (bool success,) = rewardToken.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _stakeholder.reward));
    require(success, "Error: Can`t transfer tokens to your address!");
    _stakeholder.reward = 0;
    emit Claim(msg.sender, _stakeholder.reward);
  }

  function unstake(uint _amount) isStakeholderExist public {
    Stakeholder storage stakeholder = stakeholders[msg.sender];
    _unstake(stakeholder, _amount);
  }

  function unstakeAll() isStakeholderExist public {
    Stakeholder storage stakeholder = stakeholders[msg.sender];
    _unstake(stakeholder, stakeholder.stake);
  }

  function _unstake(Stakeholder storage _stakeholder, uint _amount) Reentrancy internal {
    require(_stakeholder.stake >= _amount, "You have no such a big amount of stake tokens.");
    (,bytes memory data) = DAO.call(abi.encodeWithSignature("lastVoteForUser(address)", msg.sender));
    uint onVoting = abi.decode(data, (uint));
    require(onVoting >= block.timestamp, "Error: While you are in vote, u can`t get your tokens back!");
    (bool success,) = stakingToken.call(abi.encodeWithSignature("transfer(address,uint256)",msg.sender, _amount));
    require(success, "Error: Cant`t transfer yout tokens back to you!");
    _stakeholder.stake -= _amount;
    emit Unstake(msg.sender, _amount, _stakeholder.stake);
  }

}
