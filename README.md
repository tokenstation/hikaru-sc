# Hikaru smart-contracts

This repository contains smart contracts for Hikaru Dex.

## Repository structure

This repository contains following:
- Smart contracts:
    - [Router for interaction with the system](./contracts/Router/)
    - [Factories for creating new pools](./contracts/Factories/)
    - [Pool contracts](./contracts/SwapContracts/)
    - [Vault contracts](./contracts/Vaults/)
    - [Utility contracts](./contracts/utils/)
    - [Contracts for tests](./contracts/tests/)

- Tests for smart contracts:
    - [Initialization tests](./test/1_initializationTests/)
    - [Setters tests](./test/2_accessTests/)
    - [Functionality tests](./test/3_operationTests/)
    
## Basic smart contracts information

### Pool contracts

These contracts present smart-contracts for calculation of operations

### Vault contracts

These contracts store tokens for pools that vault represents

### Factory contracts

These contracts are used for creating of new pool contracts

### Router contracts

These contracts are used for users to interact with the system

## Operation flow

```

                       ┌─────────────┐  ┌────────────┐
                       │             │  │Pool1 type 1│
                    ┌──►Vault type 1 ├──►...         │
                    │  │             │  │PoolN type 1│
                    │  ├─────────────┤  ├────────────┤
┌──────┐   ┌──────┐ │  ├─────────────┤  ├────────────┤
│      │   │      │ │  │             │  │Pool1 type 2│
│ User ├───►Router├─┼──►Vault type 2 ├──►...         │
│      │   │      │ │  │             │  │PoolN type 2│
└──────┘   └──────┘ │  ├─────────────┤  ├────────────┤
                    │  ├─────────────┤  ├────────────┤
                    │  │             │  │Pool1 type 3│
                    └──►Vault type 3 ├──►...         │
                       │             │  │PoolN type 3│
                       └─────────────┘  └────────────┘
```

User perspective:
1. User sets allowances for tokens to router
2. User calls router to perform operation
3. Router checks if Vault can perform selected operation using IERC165
4. Router transfers tokens from user
5. If necessary router performs calculations for operation
6. Router calls vault with receiver set to msg.sender so user will receive operation result tokens