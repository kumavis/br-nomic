/*
Aphex Protocol

Rules - contractual interface for the BoardRoom rules contract.
*/

pragma solidity ^0.4.4;

import "Rules.sol";
import "Board.sol";


contract OpenRules is Rules {
  modifier boardConfigured {
    if (address(board) != address(0)) { _; }
  }

  modifier onlyboard {
    if (msg.sender == address(board)) {
      _;
    } else {
      throw;
    }
  }

  modifier onlymember {
    if (members[msg.sender]) {
      _;
    } else {
      throw;
    }
  }

  function addMember(address _member) onlyboard {
    members[_member] = true;
    numMembers += 1;
  }

  function configureBoard(address _board) onlyboard {
    board = Board(_board);
  }

  function OpenRules() {
    board = Board(msg.sender);
    members[msg.sender] = true;
    members[0x70AD465E0BAB6504002ad58C744eD89C7DA38524] = true;
    numMembers = 2;
  }

  function canExecute(address _sender, uint256 _proposalID) onlymember boardConfigured public constant returns (bool) {
    return hasWon(_sender, _proposalID) && !hasFailed(_sender, _proposalID);
  }

  function hasWon(address _sender, uint256 _proposalID) boardConfigured public constant returns (bool) {
    uint256 yay = board.positionWeightOf(_proposalID, 1);
    uint256 nay = board.positionWeightOf(_proposalID, 0);

    return (yay > nay && yay > qourum);
  }

  function hasFailed(address _sender, uint256 _proposalID) boardConfigured public constant returns (bool) {
    return !hasWon(_sender, _proposalID) && now > (board.createdOn(_proposalID) + 1 weeks);
  }

  function canVote(address _sender, uint256 _proposalID, uint256 _position) onlymember boardConfigured public constant returns (bool) {
    if (!board.hasVoted(_proposalID, _sender)) {
      return true;
    }
  }

  function changeRules(uint256 _qourum) onlyboard {
    qourum = _qourum;
  }

  function canPropose(address _sender) onlymember boardConfigured public constant returns (bool) {
    return true;
  }

  function votingWeightOf(address _sender, uint256 _proposalID) onlymember boardConfigured public constant returns (uint256) {
    return 1;
  }

  uint256 public qourum = 2;
  uint256 public numMembers;
  mapping(address => bool) public members;

  Board public board;
}
