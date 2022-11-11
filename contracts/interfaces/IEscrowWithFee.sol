// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of Refundable Escrow
 * @notice Require to use with Ownable contract
 */
interface IEscrowWithFee {
    // prefer: 10% = 1000 => percent * 100
    function feePercent() external view returns (uint256);
}
