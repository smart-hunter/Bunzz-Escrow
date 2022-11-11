//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../non-agent/EscrowWithFeeAndETH.sol";


contract EscrowByAgent is EscrowWithFeeAndETH {
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

    constructor(uint256 _feePercent) EscrowWithFeeAndETH(_feePercent) {
    }

    function depositByETHWithAgent(address _recipient, uint256 _expiration, address _agent) external virtual payable returns (uint256) {
        require(_agent != address(0x0), "agent invalid");
        uint256 _poolId = _depositByETH(_recipient, _expiration);
        agents[_poolId] = _agent;
        return _poolId;
    }

    function depositWithAgent(IERC20 _token, address _recipient, uint256 _amount, uint256 _expiration, address _agent) external virtual returns (uint256) {
        require(_agent != address(0x0), "agent invalid");
        uint256 _poolId = _deposit(_token, _recipient, _amount, _expiration);
        agents[_poolId] = _agent;
        return _poolId;
    }

    function setAgent(uint256 _poolId, address _agent) external onlyPoolOwner(_poolId) returns (bool) {
        require(_agent != address(0x0), "agent invalid");
        require(agents[_poolId] != _agent, "same agent");
        agents[_poolId] = _agent;
        return true;
    }

    function withdraw(uint256 _poolId) external override onlyAgent(_poolId) nonReentrant returns (bool) {
        return _withdraw(_poolId);
    }

    function _collector(uint256 _poolId) internal view override returns (address) {
        return agents[_poolId];
    }
}