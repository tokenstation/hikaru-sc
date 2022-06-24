// SPDX-License-Identifier: GPL-3.0-or-later
// @author tokenstation.dev

pragma solidity 0.8.6;

// The purpose of this contract is not to cause conflicts with tronbox
// I've got some ideas for tronbox patches but don't want to make any promises in advance

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  constructor() {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}