/*
Aphex Protocol

Board - a standard BoardRoom contract interface.
*/

pragma solidity ^0.4.4;


contract Board {
  function newProposal(string _name, address _proxy, uint256 _debatePeriod, address _destination, uint256 _value, bytes _calldata) public returns (uint256 proposalID) {}
  function vote(uint256 _proposalID, uint256 _position) public returns (uint256 voteWeight) {}
  function execute(uint256 _proposalID, bytes _calldata) public {}
  function changeRules(address _rules) public {}

  function voterAddressOf(uint256 _proposalID, uint256 _voteID) public constant returns (address) {}
  function numVoters(uint256 _proposalID) public constant returns (uint256) {}
  function positionWeightOf(uint256 _proposalID, uint256 _position) public constant returns (uint256) {}
  function voteOf(uint256 _proposalID, address _voter) public constant returns (uint256, uint256, uint256) {}
  function hasVoted(uint256 _proposalID, address _voter) public constant returns (bool) {}

  function executed(uint256 _proposalID) public constant returns (bool) {}
  function destinationOf(uint256 _proposalID) public constant returns (address) {}
  function proxyOf(uint256 _proposalID) public constant returns (address) {}
  function valueOf(uint256 _proposalID) public constant returns (uint256) {}
  function nonceOf(uint256 _proposalID) public constant returns (uint256) {}
  function hashOf(uint256 _proposalID) public constant returns (bytes32) {}
  function debatePeriodOf(uint256 _proposalID) public constant returns (uint256) {}
  function createdOn(uint256 _proposalID) public constant returns (uint256) {}
  function createdBy(uint256 _proposalID) public constant returns (address) {}
  function nonces(address _voter) public constant returns (uint256) {}

  event ProposalCreated(uint256 _proposalID, address _destination, uint256 _value);
  event VoteCounted(uint256 _proposalID, uint256 _position, address _voter);
  event ProposalExecuted(uint256 _proposalID, address _sender);
}
