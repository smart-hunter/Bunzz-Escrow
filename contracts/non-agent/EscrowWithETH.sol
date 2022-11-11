//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IEscrowWithETH.sol";
import "./Escrow.sol";


contract EscrowWithETH is Escrow, IEscrowWithETH, ReentrancyGuard {

    function depositByETH(address _recipient, uint256 _expiration) external override payable returns (uint256) {
        require(msg.value > 0, "amount invalid");
        require(_recipient != address(0x0), "recipient invalid");
        Pool memory pool = Pool(
            address(0x0),
            msg.sender,
            _recipient,
            true,
            msg.value,
            block.timestamp + _expiration
        );
        uint256 poolId = poolCount;
        pools[poolId] = pool;
        emit DepositByETH(msg.sender, _recipient, msg.value, block.timestamp + _expiration, poolId);
        poolCount ++;
        return poolId;
    }

    function withdraw(uint256 _poolId) external virtual override nonReentrant returns (bool) {
        return _withdraw(_poolId);
    }

    function _withdraw(uint256 _poolId) internal virtual override returns (bool) {
        require(_poolId < poolCount, "poolId invalid");
        Pool memory pool = pools[_poolId];

        require(msg.sender == pool.recipient, "don't have permission");
        require(block.timestamp > pool.expiration, "can't withdraw yet");
        require(pool.active, "already withdrawn");

        if (pool.token != address(0x0)) {
            require(IERC20(pool.token).transfer(msg.sender, pool.amount), "transfer failed");
        } else {
            (bool sent, ) = payable(msg.sender).call{value: pool.amount}("");
            require(sent, "Failed to send Ether");
        }

        pools[_poolId].active = false;

        emit Withdraw(msg.sender, _poolId, pool.amount);
        return true;
    }

}