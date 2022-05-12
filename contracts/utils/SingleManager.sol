// SPDX-License-Identifier: GPL-3.0-or-later
// @title Interface for obtaining token info from contracts
// @author tokenstation.dev

pragma solidity 0.8.13;

contract SingleManager {

    event ManagerChanged(address newManager);

    address public manager;

    constructor(
        address manager_
    ) {
        manager = manager_;
    }

    function _setManager(
        address manager_
    )
        internal 
    {
        manager = manager_;
        emit ManagerChanged(manager_);
    }

    function setManager(
        address manager_
    )
        external
        onlyManager
    {
        _setManager(manager_);
    }

    modifier onlyManager() {
        require(
            msg.sender == manager_,
            "Only manager can execute this function."
        );
    }
}