// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// This contract is the same as Ownable except for naming

pragma solidity ^0.8.0;

import { Context } from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Manageable is Context {
    address private _manager;

    event ManagerChanged(address indexed previousManager, address indexed newManager);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(
        address manager_
    ) {
        _changeManager(manager_);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyManager() {
        _checkManager();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkManager() internal view virtual {
        require(manager() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceManager() public virtual onlyManager {
        _changeManager(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function changeManager(address manager_) public virtual onlyManager {
        require(manager_ != address(0), "Ownable: new owner is the zero address");
        _changeManager(manager_);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _changeManager(address newOwner) internal virtual {
        address oldOwner = _manager;
        _manager = newOwner;
        emit ManagerChanged(oldOwner, newOwner);
    }
}