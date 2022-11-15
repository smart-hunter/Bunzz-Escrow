// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of Refundable Escrow
 * @notice Require to use with Ownable contract
 */
interface IEscrowByAgent {

    event Deposit(address indexed sender, address indexed recipient, address indexed agent, address token, uint256 amount, uint256 createdAt, uint256 poolId);
    event Release(address indexed recipient, address agent, uint256 poolId, uint256 amount);
    event Refund(address executor, address sender, uint256 poolId, uint256 amount);
    event ApproveCancel(address executor, uint256 poolId);

    function deposit(IERC20 _token, address _recipient, address _agent, uint256 _amount) external returns (uint256);

    function depositByETH(address _recipient, address _agent) external payable returns (uint256);

    function release(uint256 _poolId) external returns (bool);

    function cancel(uint256 _poolId) external returns (bool);

    function approveCancel(uint256 _poolId) external returns (bool);
}
