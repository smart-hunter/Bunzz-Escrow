//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../non-agent/EscrowWithFeeAndETH.sol";


contract EscrowByAgent is EscrowWithFeeAndETH {
    mapping(uint256 => address) public agents;

    modifier onlyAgent(uint256 _poolId) {
        require(agents[_poolId] == msg.sender, "not agent");
        _;
    }

    constructor(uint256 _feePercent) EscrowWithFeeAndETH(_feePercent) {
    }

    function withdraw(uint256 _poolId) external override onlyAgent(_poolId) nonReentrant returns (bool) {
        return _withdraw(_poolId);
    }

    function _collector(uint256 _poolId) internal view override returns (address) {
        return agents[_poolId];
    }
}