// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of Refundable Escrow
 * @notice Require to use with Ownable contract
 */
interface IEscrowByAgent {

    event Deposit(address indexed sender, address indexed recipient, address indexed token, uint256 amount, uint256 expiration, uint256 poolId);
    event DepositByETH(address indexed sender, address indexed recipient,uint256 amount, uint256 expiration, uint256 poolId);
    event Withdraw(address indexed recipient, address agent, uint256 poolId, uint256 amount);
    event SetAgent(uint256 pooId, address agent);
    event Refund(address executor, address sender, uint256 poolId, uint256 amount);
    event AllowRefund(address executor, uint256 poolId);

    function deposit(IERC20 _token, address _recipient, uint256 _amount, uint256 _expiration, address _agent) external returns (uint256);

    function depositByETH(address _recipient, uint256 _expiration, address _agent) external payable returns (uint256);

    function withdraw(uint256 _poolId) external returns (bool);

    function setAgent(uint256 _poolId, address _agent) external returns (bool);

    function refund(uint256 _pooId) external returns (bool);

    function allowRefund(uint256 _poolId) external returns (bool);
}
