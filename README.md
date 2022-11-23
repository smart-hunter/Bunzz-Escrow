# EscrowByAgent

## Overview

This is an escrow module for freelancer service operated by agents.
The sender deposit money for recipient and set agent for the payment.
If the sender want to release the payment, then he can ask the agent to release the payment for the recipient.

Deployer will set the owner fee percent and agent fee percent. The fee percent and cancelLockTime are fixed values.

## How to use
1. Deploy this contract. (Anybody can deploy this contract for an escrow service and make money from this service)
2. Create an escrow pool with recipient, agent and amount
    - call ```depositByETH``` to deposit ETH
    - call ```deposit``` to deposit ERC20 token
        * can't use same address for recipient and agent. 
3. Once you (sender) allow the agent to release the payment (this option is outside of blockchain), the agent will release the payment.
    - call ```release``` by agent
        * ownerFee will be transferred to smart contract owner
        * agentFee will be transferred to the agent
4. Approve to cancel the payment when you want to cancel it.
    - call ```approveCancel```
        * sender, recipient and agent will approve for canceling
5. Cancel the payment
    - call ```cancel``` to cancel the payment
        This function works for these cases:
            1) recipient and sender accepted.
            2) sender accepted and recipient didn't 
                * need agreement of agent


## Functions

| Function Name | Action | Description                                   | Permission                   |
|:--------------|:-------|:----------------------------------------------|------------------------------|
| deposit       | write  | Deposit ERC20 token, and create a escrow pool | any                          |
| depositByETH  | write  | Deposit ETH, and create a escrow pool         | any                          |
| release       | write  | release payment by agent                      | onlyAgent                    |
| cancel        | write  | cancel payment                                | any                          |
| approveCancel | write  | approve to cancel payment                     | sender or recipient or agent |
| cancelable    | read   | if cancelable - return true, or return false  | any                          |


### Function I/O parameters
1) deposit
deposit ERC20 token and create an escrow pool

| name        |  type   | description                         | I/O |
|:------------|:-------:|:------------------------------------|:---:|
| _token      | IERC20  | ERC20 token address                 |  I  |
| _recipient  | address | recipient address                   |  I  |
| _agent      | address | agent address                       |  I  |
| _amount     | uint256 | token amount                        |  I  |
|             |         |                                     |     |
|             | uint256 | id of pool created by this function |  O  |

2) depositByETH - payable
deposit ETH and create an escrow pool

| name        |  type   | description                         | I/O |
|:------------|:-------:|:------------------------------------|:---:|
| _recipient  | address | recipient wallet address            |  I  |
| _agent      | address | agent address                       |  I  |
|             |         |                                     |     |
|             | uint256 | id of pool created by this function |  O  |

3) release - nonReentrant, onlyAgent
release the payment by the agent

| name       |  type   | description                       | I/O |
|:-----------|:-------:|:----------------------------------|:---:|
| _poolId    | uint256 | id of target pool                 |  I  |
|            |         |                                   |     |
|            |  bool   | return true if everything is fine |  O  |

4) cancel - nonReentrant
cancel the payment. Anyone can call this function.

| name       |  type   | description                       | I/O |
|:-----------|:-------:|:----------------------------------|:---:|
| _poolId    | uint256 | id of target pool                 |  I  |
|            |         |                                   |     |
|            |  bool   | return true if everything is fine |  O  |

5) approveCancel
approve for canceling the payment. The sender, recipient and agent can call this function.

| name       |  type   | description                       | I/O |
|:-----------|:-------:|:----------------------------------|:---:|
| _poolId    | uint256 | id of target pool                 |  I  |
|            |         |                                   |     |
|            |  bool   | return true if everything is fine |  O  |

6) cancelable
if cancelable - return true, or return false

| name       |  type   | description                                  | I/O |
|:-----------|:-------:|:---------------------------------------------|:---:|
| _poolId    | uint256 | id of target pool                            |  I  |
|            |         |                                              |     |
|            |  bool   | if cancelable - return true, or return false |  O  |


## Events
1) Deposit

| name      |      type       |
|:----------|:---------------:|
| sender    | address indexed |
| recipient | address indexed |
| agent     | address indexed |
| token     |     address     |
| amount    |     uint256     |
| createdAt |     uint256     |
| poolId    |     uint256     |


2) Release

| name      |      type       |
|:----------|:---------------:|
| recipient | address indexed |
| agent     | address indexed |
| poolId    |     uint256     |
| amount    |     uint256     |

3) Cancel

| name     |      type       |
|:---------|:---------------:|
| executor | address indexed |
| sender   | address indexed |
| poolId   |     uint256     |
| amount   |     uint256     |

4) ApproveCancel

| name     |      type       |
|:---------|:---------------:|
| executor | address indexed |
| poolId   |     uint256     |



## Parameters

##### _feePercent
Fee percent for smart contract owner
10000 means 100%
so if you want to set the fee percent to 5%, feePercent is 500

##### _agentFeePercent
Fee percent for pool agent
10000 means 100%
so if you want to set the fee percent to 5%, feePercent is 500

##### __cancelLockDays
Lock days for compulsory cancellation



## State Variables
struct type
```
struct Pool {
    address token;
    address sender;
    address recipient;
    address agent;
    uint64 createdAt;
    bool isReleased;
    uint256 amount;
}

struct RefundStatus {
    bool sender;
    bool recipient;
    bool agent;
}
```
Storage variables

| name             |                  type                   | description                      |
|:-----------------|:---------------------------------------:|:---------------------------------|
| poolCount        |             uint256 public              | number of total pools            |
| feePercent       |        uint256 public immutable         | fee for contract owner           |
| agentFeePercnet  |        uint256 public immutable         | fee for agent                    |
| cancelLockTime   |        uint256 public immutable         | lock time for force cancel       |
| pools            |     mapping(uint256 => Pool) public     | pool list by poolId              |
| refundStatusList | mapping(uint256 => RefundStatus) public | approve status for cancel        |

