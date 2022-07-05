# Errors

This file contains error descriptions and why they occure

## User errors

User may encounter [Lib Errors](#lib-errors), [Pool Errors](#pool-errors) and [Vault Errors](#vaults)

## Dev errors

Dev may encounter all of errors ¯\\\_(ツ)_/¯

## Lib errors

### HIKARU#200

Description:
- Error caused by token duplication inside provided token array

### HIKARU#201

Description:
- SafeERC20 call failed for some reason

### HIKARU#202 

Description:
- This error occures in transferFromUser() function of TokenUtils library for ERC20 token if balance after operation is lower than it was before transfer

### HIKARU#203

Description:
- This error occures in transferToUser() function of TokenUtils library for ERC20 token if balance after operation is greater than it was before transfer

### HIKARU#204

Description:
- Attempt of reentrancy attack was detected, mainly implemented for preventing reentrancy attacks using vault's flashloan function

### HIKARU#205

Description:
- Pool factory was not able to deploy new pool

### HIKARU#206

Description:
- Zero address was detected in unexpected place

### HIKARU#207

Description:
- Provided arrays has different lengths

## Access

### HIKARU#300

Description:
- Caller is not manager of called contract

### HIKARU#301

Description:
- Caller attempted to call function of smart contract that is only accessible to vault contract

### HIKARU#302 

Description:
- Caller attempted to call function of smart contract that is only accessible to factory contract

## Pool errors

### HIKARU#400

Description:
- Length of weights array differes from length of provided tokens array

### HIKARU#401

Description:
- Pool's amount of tokens limit exceeded

### HIKARU#402

Description:
- Weights cannot be lower than set number

### HIKARU#403

Description:
- Sum of weights must equal 1e18

### HIKARU#404

Description:
- Provided token address does not belong to pool

### HIKARU#405

Description:
- Inialization of pool must be done using all tokens presented in pool

### HIKARU#406

Description:
- User tried to swap token to itself

### HIKARU#407

Desctiption:
- User did not receive enough tokens as result of Sell tokens operation

### HIKARU#408

Description:
- User paid too much tokens as result of Buy tokens operation

### HIKARU#409

Description:
- User cannot sell more than 30% of pool's token balance 

### HIKARU#410

Description:
- User cannot buy more than 30% of pool's token balance

### HIKARU#411

Description:
- User cannot use more than 70% of pool's LP balance to exit


## Vaults

### HIKARU#500

Description:
- Vault does not implement required interface

### HIKARU#501

Description:
- Factory address in vault must not be set in order to call function

### HIKARU#502 

Description:
- Attempt to use invalid path for virtual swap

### HIKARU#503

Description:
- Provided pool address is not deployed by known factory

### HIKARU#504

Description:
- Deadline time passed


## Factory

### HIKARU#600

Description:
- During the creation of pool it was not registered in corresponding vault


## Fees

### HIKARU#700

Description:
- Attempt to set too high swap fee for pool

### HIKARU#701

Description:
- Attempt to set too high flashloan fee

### HIKARU#702

Description:
- Not enough fee was received as a result of flashloan

### HIKARU#703

Description:
- Attempt to withdraw too much fee from FeeReceiver contract
