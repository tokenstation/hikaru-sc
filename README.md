# Hikaru smart-contracts

This repository contains smart contracts for Hikaru Dex.

Hikaru finance is DeX platform that enables integration of any imaginable DeX project as long as it follows implements pre-defined interfaces.

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

Basic smart-contract system structure:

```
┌────────┐                     ┌────────────┐       Pool creation
│  User  │                     │Pool Factory├────────────────────────────────┐
└───┬────┘                     │  contract  │                                │
    │                          └─┬─────────▲┘                                │
    │ request                    │         │                                 │
    │   to            information│         │Checking                         │
    │ perform            about   │         │ wether                      ┌───▼───┐
    │operation            new    │         │  pool                       │ Pools │
    │                    pools   │         │   is                        └▲─────┬┘
    │                            │         │  from             calculation│     │calculation
    │                            │         │ known               request  │     │   result
    │                            │         │factory                       │     │
┌───▼────┐    user request      ┌▼─────────┴┐                             │     │
│ Router └──────────────────────►   Vault   └─────────────────────────────┘     │
│contract◄──────────────────────┐ contract  ◄───────────────────────────────────┘
└────────┘ user request result  └┬─────────▲┘
                                 │         │
                        transfers│         │balance
                                 │         │ info
                                 │         │
                                ┌▼─────────┴┐
                                │   TRC20   │
                                │   token   │
                                └───────────┘
```


### Pool contracts

Pool contracts are parameter storage and calculators of the system.
They implement required math and store parameters that are specific to the pool.

#### Pool componentes

Pools consist of 3 components:
```
┌──────────────────────┐
│    Pool's storage    │
│                      │
├──────────────────────┤
├──────────────────────┤
│  Pool's math library │
│                      │
├──────────────────────┤
├──────────────────────┤
│   Pool's layer for   │
│interacting with vault│
└──────────────────────┘
```

Where:
- Pool's storage -> storage that hold constant parameters that are set during pool creation process and parameters that can be changed (swap fee coefficient, manager address)
- Pool's math library -> library that implements calculations logic
- Pool's layer for interacting with vault -> this layer performs pre-checks, ensures that correct parameters are passed to math library and interacts with vault

#### Interaction with pool

All interactions with pool are done in following manner:
```
                                              Get required paramters    ┌──────────────┐
                                    ┌───────────────────────────────────►              │
                                    │                                   │Pool's storage│
                                    │       ┌───────────────────────────┤              │
                                    │       │    Return parameters      └──────────────┘
                                    │       │
┌─────┐    Calculation request    ┌─┴───────▼─┐
│     ├───────────────────────────►Interaction│
│Vault│                           │           │
│     ◄───────────────────────────┤   Layer   │
└─────┘    Calculation result     └─▲───────┬─┘
                                    │       │    Calculate with provided
                                    │       │    and checked parameters  ┌─────────────┐
                                    │       └────────────────────────────► Pool's math │
                                    │                                    │             │
                                    └────────────────────────────────────┤   library   │
                                                    Return calculation   └─────────────┘
                                                         results
```

Step-by-step description:
1. Valid request is received from Vault smart-contract
2. Interaction layer receives request and pre-processes it - checks that parameters are valid and brings them to the right form for math library
3. With known parameters math library performs calculations and returns results to interaction layer
4. Results are returned to the vault that requested calculations by interaction layer

#### Interactions with other contracts

Pools allow performing operations only through vault. If any other contract/user tries to call contract to perform operation - transaction will fail.

```
┌─────────────┐  Operation forbidden  ┌────┐
│ Random user ├──xxxxxxxxxxxxxxxxxxx──►    │
└─────────────┘                       │    │
                                      │    │
                                      │Pool│
┌─────────────┐                       │    │
│Corresponding│  Operation permitted  │    │
│    Vault    ├───────────────────────►    │
└─────────────┘                       └────┘
```

### Vault contracts

Vault contracts are token-storages for pools and are gateways to interact with pools.

#### Vault components

Developed vault consists of:
```
┌────────────────┐
│ Vault's storage│
├────────────────┤
├────────────────┤
│ Pool's balances│
│     storage    │
├────────────────┤
├────────────────┤
│ Layer for pools│
│   interaction  │
├────────────────┤
├────────────────┤
│ Layer for user │
│   interaction  │
├────────────────┤
├────────────────┤
│   Flashloans   │
└────────────────┘
```

Where:
- Vault's storage -> stores vault-specific variables
- Pool's balance storage -> stores and modifies pool balances
- Layer for pools interaction -> implements interaction with pools for performing calculations
- Layer for user interaction -> implmenets interaction with users via [standart interfaces](./contracts/Vaults/interfaces/)
- Flashloans -> vault allows users to use this tool using [implemented interfaces](./contracts/Vaults/Flashloan/interfaces/)

#### Vaults as tokens storages

Vaults track and store balances of pools, so in vault's token balance consists of pool's token balances:
```
┌────────────────────────────┐
│                 ┌───────┐  │
│                 │ Pool1 │  │
│                 │virtual│  │
│                 │ token │  │
│                 │balance│  │
│                 ├───────┤  │
│                 │ Pool2 │  │
│                 │virtual│  │
│   Vault         │ token │  │
│   token         │balance│  │
│  balance        ├───────┤  │
│                 │ ..... │  │
│                 ├───────┤  │
│                 │ PoolN │  │
│                 │virtual│  │
│                 │ token │  │
│                 │balance│  │
│                 └───────┘  │
└────────────────────────────┘
```

Pools in this system have virtual tokens balances, but it may depend on implementation.

#### Interaction with other contracts

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


Vaults can only interact with pools that were created by known factory:
```
    ┌───────┐    Pool creation
    │Unknown├───────────────────────┐
    │facotry│                       │
    └───────┘                       │
                                    │
                               ┌────▼────┐
                               │Pool from│
                   ┌─xxxxxxxxx─► unknown │
                   │           │ factory │
                   │           └─────────┘
    ┌───────┐      │
    │ Vault ├──────┤
    └───┬───┘      │
        │          │
  Pool  │          │           ┌─────────┐
 origin │          │           │Pool from│
 check  │          └───────────►  known  │
        │                      │ factory │
        │                      └────▲────┘
    ┌───▼───┐                       │
    │ Known │    Pool creation      │
    │factory├───────────────────────┘
    └───────┘
```

### Pool factory contracts

Pool factory contracts are contracts that create new pools and can confirm that pool was deployed by factory.

#### Interations with other contracts

When new pool is created, factory calls vault to register new pool. During this call vault performs necessary preparations for pool to function correctly.

```
┌───────┐    New pool registration   ┌─────┐
│Factory├────────────────────────────►Vault│
└───────┘                            └─────┘
```


### Router contracts

Router contracts are used as single entry point for users to intract with system, reducing amount of required approvals for tokens and performing required checks.

#### Operations flow

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

```
       balanceOf() ┌─────┐  balanceOf()
    ┌──────────────┤ERC20├───────────────┐
    │              │token│               │
    │              └──┬──┘               │
    │                 │                  │
    │                 │                  │
    │                 │                  │
┌───▼───┐             ▼              ┌───▼───┐
│Initial│     transfer operation     │ Final │
│ token ├────────────────────────────► token │
│balance│   (transferFrom/tranfer)   │balance│
└───┬───┘                            └───┬───┘
    │                                    │
    │               ┌───┐                │
    └───────────────►-/+◄────────────────┘
                    └─┬─┘
                      │
            ┌─────────▼──────────┐
            │received/transferred│
            │  amount of tokens  │
            └────────────────────┘
```

## Error description

You can find smart contract error descriptions here: [Errors](./contracts/utils/Errors/README.md)