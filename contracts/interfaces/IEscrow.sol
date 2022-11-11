// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of Refundable Escrow
 * @notice Require to use with Ownable contract
 */
interface IEscrow {
    function deposit(IERC20 _token, address _recipient, uint256 _amount, uint256 _expiration) external returns (uint256);
    function withdraw(uint256 _poolId) external returns (bool);
}
