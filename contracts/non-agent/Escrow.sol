//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IEscrow.sol";


contract Escrow is IEscrow {

    struct Pool {
        address token;
        address sender;
        address recipient;
        bool active;
        uint256 amount;
        uint256 expiration;
    }

    uint256 public poolCount = 0;
    mapping(uint256 => Pool) public pools;

    event Deposit(address indexed sender, address indexed recipient, address indexed token, uint256 amount, uint256 expiration, uint256 poolId);
    event Withdraw(address indexed recipient, uint256 poolId, uint256 amount);

    function deposit(IERC20 _token, address _recipient, uint256 _amount, uint256 _expiration) external override virtual returns (uint256) {
        return _deposit(_token, _recipient, _amount, _expiration);
    }

    function withdraw(uint256 _poolId) external virtual override returns (bool) {
        return _withdraw(_poolId);
    }

    function _withdraw(uint256 _poolId) internal virtual returns (bool) {
        require(_poolId < poolCount, "poolId invalid");
        Pool memory pool = pools[_poolId];

        require(msg.sender == pool.recipient, "don't have permission");
        require(block.timestamp > pool.expiration, "can't withdraw yet");
        require(pool.active, "already withdrawn");

        require(IERC20(pool.token).transfer(msg.sender, pool.amount), "transfer failed");
        pools[_poolId].active = false;

        emit Withdraw(msg.sender, _poolId, pool.amount);
        return true;
    }

    function _deposit(IERC20 _token, address _recipient, uint256 _amount, uint256 _expiration) internal virtual returns (uint256) {
        require(_amount > 0, "amount invalid");
        require(_recipient != address(0x0), "recipient invalid");
        _token.transferFrom(msg.sender, address(this), _amount);
        Pool memory pool = Pool(
            address(_token),
            msg.sender,
            _recipient,
            true,
            _amount,
            block.timestamp + _expiration
        );
        uint256 poolId = poolCount;
        pools[poolId] = pool;
        emit Deposit(msg.sender, _recipient, address(_token), _amount, block.timestamp + _expiration, poolId);
        poolCount ++;
        return poolId;
    }
}