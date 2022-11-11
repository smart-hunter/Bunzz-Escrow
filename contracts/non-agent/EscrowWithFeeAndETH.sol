//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IEscrowWithFee.sol";
import "./Escrow.sol";
import "./EscrowWithETH.sol";

contract EscrowWithFeeAndETH is Ownable, EscrowWithETH {

    uint256 public immutable feePercent; // percent * 100

    constructor(uint256 _feePercent) {
        require(_feePercent < 10000, "feePercent invalid");
        feePercent = _feePercent;
    }

    function _withdraw(uint256 _poolId) internal virtual override returns (bool) {
        require(_poolId < poolCount, "poolId invalid");
        Pool memory pool = pools[_poolId];

        require(msg.sender == pool.recipient, "don't have permission");
        require(block.timestamp > pool.expiration, "can't withdraw yet");
        require(pool.active, "already withdrawn");

        uint256 fee = pool.amount * feePercent / 10000;
        require(IERC20(pool.token).transfer(msg.sender, pool.amount - fee), "transfer failed");
        require(IERC20(pool.token).transfer(owner(), fee), "transfer failed - fee");

        if (pool.token != address(0x0)) {
            require(IERC20(pool.token).transfer(msg.sender, pool.amount - fee), "transfer failed");
            require(IERC20(pool.token).transfer(_collector(_poolId), fee), "transfer failed - fee");
        } else {
            (bool sent1, ) = payable(msg.sender).call{value: (pool.amount - fee)}("");
            (bool sent2, ) = payable(_collector(_poolId)).call{value: (fee)}("");
            require(sent1 && sent2, "Failed to send Ether");
        }

        pools[_poolId].active = false;

        emit Withdraw(msg.sender, _poolId, pool.amount);
        return true;
    }

    function _collector(uint256 _poolId) internal view virtual returns (address) {
        return owner();
    }
}