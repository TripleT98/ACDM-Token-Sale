pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT


import "hardhat/console.sol";
import "./DAOable.sol";

contract Staking is DAOable{

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
    uint[2][] deposits;
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

  function stake(uint _amount) public {
    (bool success, bytes memory data) = stakingToken.call(abi.encodeWithSignature("allowance(address,address)", msg.sender, address(this)));
    uint allowanceAmount = abi.decode(data, (uint));
    require(allowanceAmount >= _amount, "Error: Staking token contract has no allowances to transfer this token amount from you!");
    (success,) = stakingToken.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender, address(this), _amount));
    require(success, "Error: Can`t transfer tokend from your address!");

    Stakeholder storage _current_stakeholder = stakeholders[msg.sender];

    if(!_current_stakeholder.isExist){
      _current_stakeholder.isExist = true;
    }

    _current_stakeholder.deposits.push([_amount, block.timestamp]);

    _current_stakeholder.stake += _amount;
    emit Stake(msg.sender, _amount, block.timestamp);
  }

  function claim() isStakeholderExist public {
    Stakeholder storage _stakeholder = stakeholders[msg.sender];

    uint[2][] storage deposits = _stakeholder.deposits;
    for(uint i = 0; i < deposits.length; i++){
      if(block.timestamp - deposits[i][1] >= freezeTime){
        uint reward_stack = (block.timestamp - deposits[i][1])/freezeTime;
        uint reward_percent = reward_stack*rewardShare;
        _stakeholder.reward += (deposits[i][0]/100)*reward_percent;
        deposits[i][1] = deposits[i][1] + (reward_stack*freezeTime);
      }else{
        break;
      }
    }
    require(_stakeholder.reward != 0, "Error: You have no reward tokens yet!");

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

  function _unstake(Stakeholder storage _stakeholder, uint _amount) internal {
    require(_stakeholder.stake >= _amount, "You have no such a big amount of stake tokens.");
    (,bytes memory data) = DAO.call(abi.encodeWithSignature("isOnVote(address)", msg.sender));
    bool isOnVote = abi.decode(data, (bool));
    require(!isOnVote, "Error: While you are in vote, u can`t get your tokens back!");
    (bool success,) = stakingToken.call(abi.encodeWithSignature("transfer(address,uint256)",msg.sender, _amount));
    require(success, "Error: Cant`t transfer yout tokens back to you!");
    _stakeholder.stake -= _amount;
    if(_stakeholder.stake != 0){
      uint[2][] storage deposits = _stakeholder.deposits;
      uint unstakedValue = _amount;
      int diff;
      for(uint i = deposits.length - 1; i >= 0; i--){
        diff = int(deposits[i][0] - unstakedValue);
        if(diff > 0){
          deposits[i][0] -= unstakedValue;
          break;
        }else{
          unstakedValue -= deposits[i][0];
          deposits.pop();
          if(diff == 0){
            break;
          }
        }
      }
    }else{
      delete _stakeholder.deposits;
    }
    emit Unstake(msg.sender, _amount, _stakeholder.stake);
  }

}
