//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IEscrowByAgent.sol";


contract EscrowByAgent is Ownable, ReentrancyGuard, IEscrowByAgent {

    using SafeERC20 for IERC20;

    struct Pool {
        address token;
        address sender;
        address recipient;
        uint64 expiration;
        bool active;
        uint256 amount;
    }

    // use struct to decrease storage size
    struct RefundStatus {
        bool sender;
        bool recipient;
    }

    uint256 public poolCount = 0;
    uint256 public immutable feePercent;
    mapping(uint256 => Pool) public pools;
    mapping(uint256 => address) public agents;
    mapping(uint256 => RefundStatus) public refundStatusList;


    modifier onlyAgent(uint256 _poolId) {
        require(agents[_poolId] == msg.sender, "not agent");
        _;
    }

    modifier onlyPoolOwner(uint256 _poolId) {
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

    function withdraw(uint256 _poolId) external onlyAgent(_poolId) override nonReentrant returns (bool) {
        return _withdraw(_poolId);
    }

    function setAgent(uint256 _poolId, address _agent) external override onlyPoolOwner(_poolId) returns (bool) {
        return _setAgent(_poolId, _agent);
    }

    function refund(uint256 _poolId) external override nonReentrant returns (bool) {
        require(_poolId < poolCount, "poolId invalid");
        RefundStatus memory refundStatus = refundStatusList[_poolId];
        require(refundStatus.recipient, "recipient didn't allow");
        Pool memory pool = pools[_poolId];
        require(msg.sender == pool.sender || refundStatus.sender, "sender didn't allow");
        require(pool.amount > 0 && pool.active, "no money in pool");

        if (pool.token != address(0x0)) {
            IERC20(pool.token).safeTransfer(msg.sender, pool.amount);
        } else {
            (bool sent, ) = payable(msg.sender).call{value: (pool.amount)}("");
            require(sent, "Failed to send Ether");
        }

        pools[_poolId].active = false;
        pools[_poolId].amount = 0;

        emit Refund(msg.sender, pool.sender, _poolId, pool.amount);
        return true;
    }

    function allowRefund(uint256 _poolId) external override returns (bool) {
        require(_poolId < poolCount, "poolId invalid");
        Pool memory pool = pools[_poolId];
        RefundStatus storage refundStatus = refundStatusList[_poolId];
        if (msg.sender == pool.recipient) {
            require(!refundStatus.recipient, "already done");
            refundStatus.recipient = true;
        } else if (msg.sender == pool.sender) {
            require(!refundStatus.sender, "already done");
            refundStatus.sender = true;
        } else {
            revert("no permission");
        }
        emit AllowRefund(msg.sender, _poolId);
        return true;
    }

    function _setAgent(uint256 _poolId, address _agent) internal returns (bool) {
        require(_agent != address(0x0), "agent invalid");
        require(agents[_poolId] != _agent, "same agent");
        agents[_poolId] = _agent;

        emit SetAgent(_poolId, _agent);
        return true;
    }

    function _deposit(IERC20 _token, address _recipient, uint256 _amount, uint256 _expiration) internal returns (uint256) {
        require(_amount > 0, "amount invalid");
        require(_recipient != address(0x0), "recipient invalid");
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        Pool memory pool = Pool(
            address(_token),
            msg.sender,
            _recipient,
            uint64(block.timestamp + _expiration),
            true,
            _amount
        );
        uint256 poolId = poolCount;
        pools[poolId] = pool;
        emit Deposit(msg.sender, _recipient, address(_token), _amount, block.timestamp + _expiration, poolId);
        ++ poolCount;
        return poolId;
    }

    function _depositByETH(address _recipient, uint256 _expiration) internal returns (uint256) {
        require(msg.value > 0, "amount invalid");
        require(_recipient != address(0x0), "recipient invalid");
        Pool memory pool = Pool(
            address(0x0),
            msg.sender,
            _recipient,
            uint64(block.timestamp + _expiration),
            true,
            msg.value
        );
        uint256 poolId = poolCount;
        pools[poolId] = pool;
        emit DepositByETH(msg.sender, _recipient, msg.value, block.timestamp + _expiration, poolId);
        ++ poolCount;
        return poolId;
    }

    function _withdraw(uint256 _poolId) internal returns (bool) {
        require(_poolId < poolCount, "poolId invalid");
        Pool memory pool = pools[_poolId];

        require(block.timestamp > pool.expiration, "can't withdraw yet");
        require(pool.amount > 0, "no money in pool");
        require(pool.active, "already withdrawn");

        uint256 fee = pool.amount * feePercent / 10000;

        if (pool.token != address(0x0)) {
            IERC20(pool.token).safeTransfer(msg.sender, pool.amount - fee);
            IERC20(pool.token).safeTransfer(_collector(_poolId), fee);
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