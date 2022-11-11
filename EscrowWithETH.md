# EscrowPackage
Provides different types of Escrow capabilities.


- [Escrow](https://github.com/smart-ticky/Bunzz-Escrow/blob/main/README.md): As the simplest Escrow format, only Sender and Recipient exist. By default, support only ERC20 token.
- [EscrowWithFee](https://github.com/smart-ticky/Bunzz-Escrow/blob/main/EscrowWithFee.md): Transaction fee exists.
- [EscrowWithETH](#EscrowWithETH): support both of ERC20 tokens and ETH (native token of target EVM network). no fees.
- [EscrowWithFeeAndETH](https://github.com/smart-ticky/Bunzz-Escrow/blob/main/EscrowWithFeeAndETH.md): support both of ERC20 tokens and ETH (native token of target EVM network). Transaction fee exists.

- [EscrowByOwner](https://github.com/smart-ticky/Bunzz-Escrow/blob/main/EscrowByOwner.md): inherited EscrowWithFeeAndETH and the transaction is handled by the contact owner.
- [EscrowByAgent](https://github.com/smart-ticky/Bunzz-Escrow/blob/main/EscrowByAgent.md): Sender specifies the agent who processes the transaction.

## EscrowWithETH
support both of ERC20 tokens and ETH (native token of target EVM network). no fees.

### Module Description
Sender creates a pool depositing coins to into escrow contract with expiration time.
After the expiration time, the recipient can withdraw the money.

### Features
- sender creates a pool depositing tokens into escrow contact
- after the expiration time, the recipient can withdraw the money

### Properties

#### Variables
Pool struct type
```
struct Pool {
    address token;
    address sender;
    address recipient;
    bool active;
    uint256 amount;
    uint256 expiration;
}
```
Storage variables

| name      |              type               | description                 |
|:----------|:-------------------------------:|:----------------------------|
| poolCount |         uint256 public          | number of total pools       |
| pools     | mapping(uint256 => Pool) public | pool list by poolId         |


#### Functions

| Function Name     | Action  |                                   Description | Permission          |
|:------------------|:-------:|----------------------------------------------:|---------------------|
| deposit           |  write  | Deposit ERC20 token, and create a escrow pool | any                 |
| depositByETH      |  write  |         Deposit ETH, and create a escrow pool | any                 |
| withdraw          |  write  |        Withdraw token from target escrow pool | onlyRecipientOfPool |


##### Function I/O parameters
1) deposit

| name        |  type   | description                        | I/O |
|:------------|:-------:|:-----------------------------------|:---:|
| _token      | IERC20  | ERC20 token address                |  I  |
| _recipient  | address | recipient wallet address           |  I  |
| _amount     | uint256 | token amount                       |  I  |
| _expiration | uint256 | timestamp of expiration range      |  I  |
|             |         |                                    |     |
|             | uint256 | id of pool created by this funcion |  O  |

2) depositByETH - payable

| name        |  type   | description                        | I/O |
|:------------|:-------:|:-----------------------------------|:---:|
| _recipient  | address | recipient wallet address           |  I  |
| _expiration | uint256 | timestamp of expiration range      |  I  |
|             |         |                                    |     |
|             | uint256 | id of pool created by this funcion |  O  |

3) withdraw - nonReentrant

| name       |  type   | description                       | I/O |
|:-----------|:-------:|:----------------------------------|:---:|
| _poolId    | uint256 | id of target pool                 |  I  |
|            |         |                                   |     |
|            |  bool   | return true if everything is fine |  O  |


#### Main Flow
1. create a pool calling deposit function with the detail values (recipient, amount, expiration range)
2. once the expiration time is over, the recipient can withdraw the money from the escrow pool

