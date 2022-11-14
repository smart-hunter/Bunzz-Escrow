//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IEscrowByAgent.sol";


contract EscrowByAgent is Ownable, ReentrancyGuard, IEscrowByAgent {

    struct Pool {
        address token;
        address sender;
        address recipient;
        bool active;
        uint256 amount;
        uint256 expiration;
    }

    // use struct to decrease storage size
    struct Refundable {
        bool sender;
        bool recipient;
    }

    uint256 public poolCount = 0;
    uint256 public immutable feePercent;
    mapping(uint256 => Pool) public pools;
    mapping(uint256 => address) public agents;

    modifier onlyAgent(uint256 _poolId) {
        require(agents[_poolId] == msg.sender, "not agent");
        _;
    }

    modifier onlyPoolOwner(uint256 _poolId) {
        require(_poolId < poolCount, "poolId invalid");
        require(pools[_poolId].sender == msg.sender, "no permission");
        _;
    }

    constructor(uint256 _feePercent) {
        require(_feePercent < 10000, "feePercent invalid");
        feePercent = _feePercent;
    }

    function depositByETH(address _recipient, uint256 _expiration, address _agent) external override payable returns (uint256) {
        require(_agent != address(0x0), "agent invalid");
        uint256 _poolId = _depositByETH(_recipient, _expiration);
        _setAgent(_poolId, _agent);
        return _poolId;
    }

    function deposit(IERC20 _token, address _recipient, uint256 _amount, uint256 _expiration, address _agent) external override returns (uint256) {
        require(_agent != address(0x0), "agent invalid");
        uint256 _poolId = _deposit(_token, _recipient, _amount, _expiration);
        _setAgent(_poolId, _agent);
        return _poolId;
    }

    function setAgent(uint256 _poolId, address _agent) external override onlyPoolOwner(_poolId) returns (bool) {
        return _setAgent(_poolId, _agent);
    }

    function _setAgent(uint256 _poolId, address _agent) internal returns (bool) {
        require(_agent != address(0x0), "agent invalid");
        require(agents[_poolId] != _agent, "same agent");
        agents[_poolId] = _agent;

        emit SetAgent(_poolId, _agent);
        return true;
    }

    function withdraw(uint256 _poolId) external onlyAgent(_poolId) override nonReentrant returns (bool) {
        return _withdraw(_poolId);
    }

    function _deposit(IERC20 _token, address _recipient, uint256 _amount, uint256 _expiration) internal returns (uint256) {
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

    function _depositByETH(address _recipient, uint256 _expiration) internal returns (uint256) {
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

    function _withdraw(uint256 _poolId) internal returns (bool) {
        require(_poolId < poolCount, "poolId invalid");
        Pool memory pool = pools[_poolId];

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

        emit Withdraw(pool.recipient, msg.sender, _poolId, pool.amount);
        return true;
    }

    function _collector(uint256 _poolId) internal view returns (address) {
        return agents[_poolId];
    }
}