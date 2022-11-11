# EscrowPackage
Provides different types of Escrow capabilities.


- [Escrow](https://github.com/smart-ticky/Bunzz-Escrow/blob/main/README.md): As the simplest Escrow format, only Sender and Recipient exist. By default, support only ERC20 token.
- [EscrowWithFee](#EscrowWithFee): Transaction fee exists.
- [EscrowWithETH](https://github.com/smart-ticky/Bunzz-Escrow/blob/main/EscrowWithETH.md): support both of ERC20 tokens and ETH (native token of target EVM network). no fees.
- [EscrowWithFeeAndETH](https://github.com/smart-ticky/Bunzz-Escrow/blob/main/EscrowWithFeeAndETH.md): support both of ERC20 tokens and ETH (native token of target EVM network). Transaction fee exists.

- [EscrowByOwner](https://github.com/smart-ticky/Bunzz-Escrow/blob/main/EscrowByOwner.md): inherited EscrowWithFeeAndETH and the transaction is handled by the contact owner.
- [EscrowByAgent](https://github.com/smart-ticky/Bunzz-Escrow/blob/main/EscrowByAgent.md): Sender specifies the agent who processes the transaction.

## EscrowWithFee
Transaction fee exists.
<br />
```Support only ERC20 token.```

### Module Description
Sender creates a pool depositing coins to into escrow contract with expiration time.
After the expiration time, the recipient can withdraw the money.
When the recipient withdraw the money from escrow contract, he would pay some percent of th money as a transaction fee.

### Features
- when deploying contract, deployer will set the transaction fee percent, which can't be changed in the future.
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

| name         |              type               | description           |
|:-------------|:-------------------------------:|:----------------------|
| poolCount    |         uint256 public          | number of total pools |
| pools        | mapping(uint256 => Pool) public | pool list by poolId   |
| feePercent   |    uint256 public immutable     | fee percent           |


#### Functions

| Function Name | Action  |                                   Description | Permission          |
|:--------------|:-------:|----------------------------------------------:|---------------------|
| deposit       |  write  | Deposit ERC20 token, and create a escrow pool | any                 |
| withdraw      |  write  |        Withdraw token from target escrow pool | onlyRecipientOfPool |


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

2) withdraw

| name       |  type   | description                       | I/O |
|:-----------|:-------:|:----------------------------------|:---:|
| _poolId    | uint256 | id of target pool                 |  I  |
|            |         |                                   |     |
|            |  bool   | return true if everything is fine |  O  |


#### Main Flow
1. when deploying this contract, set the fee percent.
2. create a pool calling deposit function with the detail values (recipient, amount, expiration range)
3. once the expiration time is over, the recipient can withdraw the money from the escrow pool. recipient will pay some of the money as a transaction fee.
4. the transaction fee will be sent to owner of contract.

