# EscrowByAgent

The agent will release the payment with the approval of the sender after the expiration time.

## Module Description
This is an escrow module for freelancer service operated by agents.
It can also be used for commerce.
Proceed with the necessary agreements outside the blockchain.

``
For example, you can assume that the client is hiring a freelancer for a project.
For fairness, the client and freelancer select the agent and the client deposits the amount to the escrow contract.
Now the freelancer is free to start working.
If the freelancer has done the task correctly, the client asks the agent to release the payment.
When the agent releases, the amount is sent to the freelancer and some fees are sent to the agent and smart contract owner.
If the client is not satisfied with the result of the freelancer, the client can cancel the payment.
If the freelancer agrees, it can be refunded immediately.
Otherwise, the agent may agree to examine the process and cancel the payment.
But the money will be locked for 3 months because freelancer didn't agree.
``

## Features 
- sender creates a pool depositing tokens into escrow contact
- after the expiration time, if the client says "OK" for payment release, the agent release the payment
- agentFee will be sent to agent address and the serviceFee will be sent to contract owner.
- sender can cancel the payment before agent release the payment.

## Properties

### Variables
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

### Functions

| Function Name | Action  | Description                                   | Permission                   |
|:--------------|:-------:|:----------------------------------------------|------------------------------|
| deposit       |  write  | Deposit ERC20 token, and create a escrow pool | any                          |
| depositByETH  |  write  | Deposit ETH, and create a escrow pool         | any                          |
| release       |  write  | release payment by agent                      | onlyAgent                    |
| cancel        |  write  | cancel payment                                | any                          |
| approveCancel |  write  | approve to cancel payment                     | sender or recipient or agent |


##### Function I/O parameters
1) deposit

| name        |  type   | description                         | I/O |
|:------------|:-------:|:------------------------------------|:---:|
| _token      | IERC20  | ERC20 token address                 |  I  |
| _recipient  | address | recipient address                   |  I  |
| _agent      | address | agent address                       |  I  |
| _amount     | uint256 | token amount                        |  I  |
|             |         |                                     |     |
|             | uint256 | id of pool created by this function |  O  |

2) depositByETH - payable

| name        |  type   | description                         | I/O |
|:------------|:-------:|:------------------------------------|:---:|
| _recipient  | address | recipient wallet address            |  I  |
| _agent      | address | agent address                       |  I  |
|             |         |                                     |     |
|             | uint256 | id of pool created by this function |  O  |

3) release - nonReentrant, onlyAgent

| name       |  type   | description                       | I/O |
|:-----------|:-------:|:----------------------------------|:---:|
| _poolId    | uint256 | id of target pool                 |  I  |
|            |         |                                   |     |
|            |  bool   | return true if everything is fine |  O  |

4) cancel - nonReentrant

| name       |  type   | description                       | I/O |
|:-----------|:-------:|:----------------------------------|:---:|
| _poolId    | uint256 | id of target pool                 |  I  |
|            |         |                                   |     |
|            |  bool   | return true if everything is fine |  O  |

5) approveCancel

| name       |  type   | description                       | I/O |
|:-----------|:-------:|:----------------------------------|:---:|
| _poolId    | uint256 | id of target pool                 |  I  |
|            |         |                                   |     |
|            |  bool   | return true if everything is fine |  O  |


#### Main Flow
1. when deploying this contract, set the fee percent and cancelLockDays.
2. create a pool calling deposit function with the detail values
3. when the sender asks the agent to release the payment, the agent will release the payment, and the fees will be sent to smart contract owner and agent.

4. if sender (client) wants to cancel the payment, then the sender need to obtain the consent of the recipient.
5. otherwise, if agent checks the process and allows the sender to cancel the payment, then the payment is able to be canceled in three months.
