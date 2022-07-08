// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;


import "@openzeppelin/contracts/access/Ownable.sol";


abstract contract StakingManageable is Ownable {
    mapping (address => bool) private _admins;
    mapping (address => bool) private _stakingManagers;

    event AdminAdded(address indexed user);
    event AdminRemoved(address indexed user);
    event StakingManagerAdded(address indexed user);
    event StakingManagerRemoved(address indexed user);

    constructor() {
        setAdmin(_msgSender());
        setStakingManager(_msgSender());
    }


    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Manageable::onlyAdmin: caller is not admin");
        _;
    }

    modifier onlyStakingManager() {
        require(isStakingManager(_msgSender()), "Manageable::onlyStakingManager: caller is not staking manager");
        _;
    }

    function isAdmin(address user) public view returns (bool) {
        return _admins[user];
    }

    function isStakingManager(address user) public view returns (bool) {
        return _stakingManagers[user];
    }

    function setAdmin(address user) public onlyOwner {
        _admins[user] = true;
        emit AdminAdded(user);
    }

    function removeAdmin(address user) external onlyOwner {
        _admins[user] = false;
        emit AdminRemoved(user);
    }

    function setStakingManager(address user) public onlyAdmin {
        _stakingManagers[user] = true;
        emit StakingManagerAdded(user);
    }

    function removeStakingManager(address user) external onlyAdmin {
        _stakingManagers[user] = false;
        emit StakingManagerRemoved(user);
    }
}
