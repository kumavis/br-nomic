/*
Aphex Protocol

BoardRoom - a standard BoardRoom contract controller.
*/

pragma solidity ^0.4.4;

import "Rules.sol";
import "Proxy.sol";
import "Board.sol";


contract BoardRoom is Board {

  modifier canpropose() {
    if(rules.canPropose(msg.sender)) {
      _;
    } else { throw; }
  }

  modifier canvote (uint256 _proposalID, uint256 _position) {
    if(rules.canVote(msg.sender, _proposalID, _position)) {
      _;
    } else { throw; }
  }

  modifier canexecute(uint256 _proposalID) {
    if(rules.canExecute(msg.sender, _proposalID)) {
      _;
    } else { throw; }
  }

  modifier onlyself() {
    if(msg.sender == address(this)) {
      _;
    } else { throw; }
  }

  function () payable public {}

  function BoardRoom(address _rules) {
    rules = Rules(_rules);
  }

  function newProposal(string _name,
    address _proxy,
    uint256 _debatePeriod,
    address _destination,
    uint256 _value,
    bytes _calldata)
    canpropose
    returns (uint256 proposalID) {
    proposalID = proposals.length++;
    Proposal p = proposals[proposalID];
    p.name = _name;
    p.destination = _destination;
    p.value = _value;
    p.proxy = _proxy;
    p.debatePeriod = _debatePeriod;
    p.created = now;
    p.calldata = _calldata;
    p.from = msg.sender;
    p.nonce = nonces[msg.sender];
    nonces[msg.sender] += 1;
    ProposalCreated(proposalID, _destination, _value);
  }

  function vote(uint256 _proposalID, uint256 _position) canvote(_proposalID, _position) returns (uint256 voterWeight) {
    voterWeight = rules.votingWeightOf(msg.sender, _proposalID);
    proposals[_proposalID].votes[msg.sender] = Vote({
      position: _position,
      weight: voterWeight,
      created: now
    });
    proposals[_proposalID].voters.push(msg.sender);
    proposals[_proposalID].positions[_position] += voterWeight;
    VoteCounted(_proposalID, _position, msg.sender);
  }

  function execute(uint256 _proposalID) canexecute(_proposalID) {
    Proposal p = proposals[_proposalID];
    if(!p.executed) {
      p.executed = true;
      if(p.proxy != address(0)) {
        Proxy(p.proxy).forward_transaction(p.destination, p.value, p.calldata);
      } else {
        if(!p.destination.call.value(p.value)(p.calldata)){
          throw;
        }
      }

      ProposalExecuted(_proposalID, msg.sender);
    }
  }

  function changeRules(address _rules) onlyself {
    rules = Rules(_rules);
  }

  function numProposals() constant returns (uint256) {
    return uint256(proposals.length);
  }

  function positionWeightOf(uint256 _proposalID, uint256 _position) constant returns (uint256) {
    return proposals[_proposalID].positions[_position];
  }

  function voteOf(uint256 _proposalID,
    address _voter)
    constant
    returns (uint256 position,
      uint256 weight,
      uint256 created) {
    Vote v = proposals[_proposalID].votes[_voter];
    position = v.position;
    weight = v.weight;
    created = v.created;
  }

  function voterAddressOf(uint256 _proposalID, uint256 _voteID) constant returns (address) {
    return proposals[_proposalID].voters[_voteID];
  }

  function numVoters(uint256 _proposalID) constant returns (uint256) {
    return proposals[_proposalID].voters.length;
  }

  function hasVoted(uint256 _proposalID, address _voter) constant returns (bool) {
    if(proposals[_proposalID].votes[_voter].created > 0) {
      return true;
    }
  }

  function executed(uint256 _proposalId) public constant returns (bool) {
    return proposals[_proposalId].executed;
  }

  function destinationOf(uint256 _proposalId) public constant returns (address) {
    return proposals[_proposalId].destination;
  }

  function proxyOf(uint256 _proposalId) public constant returns (address) {
    return proposals[_proposalId].proxy;
  }

  function valueOf(uint256 _proposalId) public constant returns (uint256) {
    return proposals[_proposalId].value;
  }

  function nonceOf(uint256 _proposalId) public constant returns (uint256) {
    return proposals[_proposalId].nonce;
  }

  function debatePeriodOf(uint256 _proposalId) public constant returns (uint256) {
    return proposals[_proposalId].debatePeriod;
  }

  function calldataOf(uint256 _proposalId) public constant returns (bytes) {
    return proposals[_proposalId].calldata;
  }

  function signatureOf(uint256 _proposalId) public constant returns (bytes4) {
    bytes4 signature;
    bytes memory b = proposals[_proposalId].calldata;
    assembly { signature := mload(add(b, 0x20)) }

    return signature;
  }

  function byteOf(uint256 _proposalId, uint256 _position) public constant returns (bytes1) {
    return proposals[_proposalId].calldata[_position];
  }

  function createdOn(uint256 _proposalId) public constant returns (uint256) {
    return proposals[_proposalId].created;
  }

  function createdBy(uint256 _proposalId) public constant returns (address) {
    return proposals[_proposalId].from;
  }

  struct Proposal {
    string name;
    address destination;
    address proxy;
    uint256 value;
    bool executed;
    bytes calldata;
    uint256 debatePeriod;
    uint256 created;
    address from;
    uint256 nonce;
    mapping(uint256 => uint256) positions;
    mapping(address => Vote) votes;
    address[] voters;
  }

  struct Vote {
    uint256 position;
    uint256 weight;
    uint256 created;
  }

  mapping(address => uint256) public nonces;
  Proposal[] public proposals;
  Rules public rules;
}
