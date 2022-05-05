// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract DAO {

    address public chairman;
    address public staking;
    address public stakingTokenAddress;
    uint id = 1;
    uint public voteDuration;
    uint public minimumQuorum = 40;
    mapping (address => uint) public feeEth;

    struct Proposal{
        bytes signature;
        address recepient;
        string description;
        uint256 rejectVotes;
        uint256 resolveVotes;
        uint256 startTime;
        uint256 duration;
        mapping (address => uint256) voters;
    }

    enum Status{
        Resolved,
        Rejected,
        ExecutionFail
    }

    mapping (address => uint) public lastVoteForUser;
    mapping (uint => Proposal) public proposals;
    mapping (bytes => uint) public signatureToId;

    event ProposalFinished(uint indexed id, Status status, address finisher);

    modifier isExist(uint _id){
        require(proposals[_id].signature.length != 0, "Error: This proposal doesn`t exist!");
        _;
    }

    modifier OnlyChairman(){
      require(msg.sender == chairman, "Error: Only chairman can add proposal!");
      _;
    }

    function setMinQuorum(uint _val) OnlyChairman public {
      require(_val <= 100 && _val != 0, "Error: Invalid minimum quorum value!");
      minimumQuorum = _val;
    }

    function setVoteDuration(uint _val) OnlyChairman public {
      voteDuration = _val;
    }

    function setStakingAddress(address _staking) OnlyChairman public {
      staking = _staking;
    }

    function setNewChairman(address _newChairman) OnlyChairman public {
      require(_newChairman != address(0), "Error: New chairman is zero address!");
      require(_newChairman != chairman, "Error: Address of new chairman is equal to old one`s address!");
      chairman = _newChairman;
    }

    constructor(address _chairman, uint _voteDuration){
        chairman = _chairman;
        voteDuration = _voteDuration;
    }

    function _getTotalSuply() internal returns (uint){
      bytes memory data;
      uint totalSuply;
      if(stakingTokenAddress == address(0)){
        (,data) = staking.call(abi.encodeWithSignature("stakingToken()"));
        stakingTokenAddress = abi.decode(data, (address));
      }
      (,data) = stakingTokenAddress.call(abi.encodeWithSignature("totalSuply()"));
      totalSuply = abi.decode(data, (uint));
      return totalSuply;
    }

    function addProposal(bytes calldata _signature, address _recepient, string calldata _description) OnlyChairman public {
        require(_signature.length != 0, "Error: Empty signature!");
        require(_recepient != address(0), "Error: Zero address of recepient!");
        require(signatureToId[_signature] == 0, "Error: Proposal with such a signature is already exists!");
        Proposal storage currentProposal = proposals[id];
        currentProposal.signature = _signature;
        currentProposal.startTime = block.timestamp;
        currentProposal.recepient = _recepient;
        currentProposal.description = _description;
        currentProposal.duration = voteDuration;
        signatureToId[_signature] = id;
        id++;
    }


    function vote(uint _id, bool _vote) isExist(_id) public {
        (bool success, bytes memory data) = staking.call(abi.encodeWithSignature("getStake(address)", msg.sender));
        uint _stakingAmount = abi.decode(data, (uint));
        require(_stakingAmount > 0, "Error: Your staking balance is equals to zero!");
        Proposal storage currentProposal = proposals[_id];
        require(currentProposal.voters[msg.sender] == 0, "Error: Can`t vote twice on the same proposal!");
        if(_vote){
            currentProposal.resolveVotes += _stakingAmount;
        }else{
            currentProposal.rejectVotes += _stakingAmount;
        }
        currentProposal.voters[msg.sender] += _stakingAmount;
        uint freezeTime = currentProposal.startTime + currentProposal.duration;
        if(freezeTime > lastVoteForUser[msg.sender]){
          lastVoteForUser[msg.sender] = freezeTime;
        }
    }

    function _execute(Proposal storage _proposal) internal returns (bool success){
        (success,) = _proposal.recepient.call{value:0}(_proposal.signature);
    }

    function finish(uint _id) isExist(_id) public {
        Proposal storage currentProposal = proposals[_id];
        require(currentProposal.startTime + currentProposal.duration <= block.timestamp, "Error: Can`t finish this proposal yet!");
        require(currentProposal.resolveVotes != currentProposal.rejectVotes, "Error: Votes are equal!");
        uint totalSuply;
        totalSuply = _getTotalSuply();
        require(currentProposal.resolveVotes + currentProposal.rejectVotes >= (totalSuply/100)*minimumQuorum, "Error: Can`t finish this proposal while enough tokens not used in vote");
        if(currentProposal.resolveVotes > currentProposal.rejectVotes){
            bool success = _execute(currentProposal);
            Status isExecute = success?Status.Resolved:Status.ExecutionFail;
            emit ProposalFinished(_id, isExecute, msg.sender);
        }else{
            emit ProposalFinished(_id, Status.Rejected, msg.sender);
        }
        delete proposals[_id];

    }

    fallback () payable external {
      feeEth[msg.sender] += msg.value;
    }

}
