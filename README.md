# DSwap-Contracts-V1

Basic info about swap contracts:
- All contracts for swaps use the same interface
- The difference between contracts is in used underlying libraries
- Libraries for swaps are provided in ./contracts/SwapContracts/

Layout of contracts:
- Tokens used by swap pair
- Parameters required for calculating swaps -> can be stored in separate contract
- Swaps are performed using calls for underlying libraries

Data:
- Tokens used by pair -> stored in array inside smart-contract, can be obtained through interface/call to public fields
- Pair parameters -> stored in pair/separate contract, may be represented as bytes and later be decoded
- Token balances -> requested per each transaction, so we can work with tokens that have fees on transfer

Functionality:
- Swap operations -> swap any of underlying tokens to another (if it is mathematically possible)
- If it's possible to calculate -> provide functionality to swap tokens to receive exact amount of tokens (i.e. swap N token1 to receive 1000 token2)
- If it's possible -> provide dry-run functions for swaps (for calculation of swap result without performing it, may be inconsistent for tokens with transfer fees)
- If it's possible -> allow flashloans

Info for interaction:
- All used interfaces are atomical interfaces -> they represent single piece of functionality, which will not be mixed

Misc:
- Contracts must consist of minimal amount of code and variables required for operating
- Each function of smart contract must be tested
- There must be minimal dependencies, every contract should be self-contained

Smart-contracts consist of 3 layers:
- External layer -> users use this layer to interact with smart-contracts
- Middle layer -> this layer performs checks (minimal output/deadlines/authority), token transfers and emits events
- Internal layers -> this layer calculates swap result, which is passed back to middle layer for further actions