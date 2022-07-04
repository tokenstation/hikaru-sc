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

Pool contracts are smart-contracts that implement:
- Calculations for pool operations (swaps/joins/exits)
- Liquidity pool ownership via LP tokens

### Interactions with other contracts

Pools allow performing operations only through vault. If any other contract/user tries to call contract to perform operation - transaction will fail.

```
┌─────────────┐     Operation forbidden  ┌────┐
│ Random user ├─────xxxxxxxxxxxxxxxxxxx──►    │
└─────────────┘                          │    │
                                         │    │
                                         │Pool│
┌─────────────┐                          │    │
│Corresponding│     Operation permitted  │    │
│    Vault    ├──────────────────────────►    │
└─────────────┘                          └────┘
```

### Vault contracts

Vault contracts are smart-contracts intended for:
- Performing operations with vault's pools
- Act as token storage for pools

### Interactions with other contracts

While processing operations vaults perform following operations:
- Transfer tokens to/from user
- Calls pool to calculate operation result
- Transfer tokens to/from user (as operation result)

```
┌─────┐   Calculation request to pool   ┌────┐
│     ├─────────────────────────────────►    │
│Vault│                                 │Pool│
│     ◄─────────────────────────────────┤    │
└┬───▲┘        Calculation result       └────┘
 │   │
 │   │         token balances           ┌─────┐
 │   └──────────────────────────────────┤     │
 │                                      │ERC20│
 │          transfer operations         │token│
 └──────────────────────────────────────►     │
                                        └─────┘
```

Vaults can only interact with pools that were created by corresponding factories. \
For example: 
- Weighted Vault cannot interact with NewType Pools which were created by factory other than Weighted Pool Factory.

### Factory contracts

Factory contracts are used to:
- Create new pool contracts
- Track what pool contracts belong to factory

### Interations with other contracts

Factory must call Vault contract to register created pool

```
┌───────┐    New pool registration   ┌─────┐
│Factory├────────────────────────────►Vault│
└───────┘                            └─────┘
```


### Router contracts

Router contracts are used as single entry point for users to intract with system, reducing amount of required approvals for tokens and performing required checks.

### Operations flow

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


## Misc info

There are specific tweaks in system to operate with tokens that implement comission on transfers.

To deal with the problem of difference in passed parameter and real transfer sum, contracts use calculated values as results of token transfers:
- If transferFrom() is called than received amount is calculated as:
```
    receivedAmount = balanceAfter - balanceBefore
```
- If transfer() is called than transferred amount is calculated as:
```
    transferredAmount = balanceBefore - balanceAfter
```

You will need to account for this when using tokens with comissions.