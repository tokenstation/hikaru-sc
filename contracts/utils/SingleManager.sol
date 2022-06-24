// SPDX-License-Identifier: GPL-3.0-or-later
// @title Contract with simple rights regulation
// @author tokenstation.dev

pragma solidity 0.8.6;

contract SingleManager {

    event ManagerChanged(address newManager);

    address public manager;

    constructor(
        address manager_
    ) {
        manager = manager_;
    }

    /**
     * @notice Set new manager
     * @param manager_ New manager address
     */
    function _setManager(
        address manager_
    )
        internal 
    {
        manager = manager_;
        emit ManagerChanged(manager_);
    }

    /**
     * @notice Set new manager
     * @param manager_ New manager address
     */
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
            msg.sender == manager,
            "Only manager can execute this function."
        );
        _;
    }
}