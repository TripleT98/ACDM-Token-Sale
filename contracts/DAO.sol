// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract DAO {

    address public chairman;
    address public staking;
    address public stakingTokenAddress;
    uint id = 1;
    uint public vote_duration;
    uint public minimumQuorum = 40;

    struct Proposal{
        bytes signature;
        address recepient;
        string description;
        uint256 reject_votes;
        uint256 resolve_votes;
        uint256 start_time;
        uint256 duration;
        mapping (address => uint256) voters;
    }

    enum Status{
        Resolved,
        Rejected,
        ExecutionFail
    }

    mapping (address => uint[]) public userToVotes;
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
      vote_duration = _val;
    }

    function setStakingAddress(address _staking) OnlyChairman public {
      staking = _staking;
    }

    function setNewChairman(address _newChairman) OnlyChairman public {
      require(_newChairman != address(0), "Error: New chairman is zero address!");
      require(_newChairman != chairman, "Error: Address of new chairman is equal to old one`s address!");
      chairman = _newChairman;
    }

    constructor(address _chairman, uint _vote_duration){
        chairman = _chairman;
        vote_duration = _vote_duration;
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
        Proposal storage current_proposal = proposals[id];
        current_proposal.signature = _signature;
        current_proposal.start_time = block.timestamp;
        current_proposal.recepient = _recepient;
        current_proposal.description = _description;
        current_proposal.duration = vote_duration;
        signatureToId[_signature] = id;
        id++;
    }


    function vote(uint _id, bool _vote) isExist(_id) public {
        (,bytes memory data) = staking.call(abi.encodeWithSignature("getStake(address)", msg.sender));
        uint _stakingAmount = abi.decode(data, (uint));
        require(_stakingAmount > 0, "Error: Your staking balance is equals to zero!");
        Proposal storage current_proposal = proposals[_id];
        if(_vote){
            current_proposal.resolve_votes += _stakingAmount;
        }else{
            current_proposal.reject_votes += _stakingAmount;
        }
        current_proposal.voters[msg.sender] += _stakingAmount;
        userToVotes[msg.sender].push(_id);
    }

    function _execute(Proposal storage _proposal) internal returns (bool success){
        (success,) = _proposal.recepient.call{value:0}(_proposal.signature);
    }

    function finish(uint _id) isExist(_id) public {
        Proposal storage current_proposal = proposals[_id];
        require(current_proposal.start_time + current_proposal.duration <= block.timestamp, "Error: Can`t finish this proposal yet!");
        require(current_proposal.resolve_votes != current_proposal.reject_votes, "Error: Can`t finish this proposal while `resolve votes` amount is equals to `reject votes` amount!");
        uint totalSuply;
        totalSuply = _getTotalSuply();
        require(current_proposal.resolve_votes + current_proposal.reject_votes >= (totalSuply/100)*minimumQuorum, "Error: Can`t finish this proposal while enough tokens not used in vote");
        if(current_proposal.resolve_votes > current_proposal.reject_votes){
            bool success = _execute(current_proposal);
            if(success){
                emit ProposalFinished(_id, Status.Resolved, msg.sender);
            }else{
                emit ProposalFinished(_id, Status.ExecutionFail, msg.sender);
            }
        }else{
            emit ProposalFinished(_id, Status.Rejected, msg.sender);
        }
        delete proposals[_id];

    }

    function isOnVote(address _voter) public returns(bool){
        uint[] storage votes = userToVotes[_voter];
        for(uint i = 0; i < votes.length; i++){
            if(proposals[votes[i]].recepient == address(0)){
                uint el = votes[i];
                votes[i] = votes[votes.length - 1];
                votes[votes.length - 1] = el;
                votes.pop();
            }
        }
        return votes.length == 0;
    }

}
