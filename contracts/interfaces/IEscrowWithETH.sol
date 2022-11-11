// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of Refundable Escrow
 * @notice Require to use with Ownable contract
 */
interface IEscrowWithETH {
    event DepositByETH(address indexed sender, address indexed recipient,uint256 amount, uint256 expiration, uint256 poolId);

    function depositByETH(address _recipient, uint256 _expiration) external payable returns (uint256);
}
