/*
Aphex Protocol

Rules - contractual interface for the BoardRoom rules contract.
*/

pragma solidity ^0.4.4;


contract Rules {
  function canExecute(address _sender, uint256 _proposalID) public constant returns (bool);
  function canVote(address _sender, uint256 _proposalID, uint256 _position) public constant returns (bool);
  function canPropose(address _sender) public constant returns (bool);
  function votingWeightOf(address _sender, uint256 _proposalID) public constant returns (uint256);
}
