//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../non-agent/EscrowWithFeeAndETH.sol";


 contract EscrowByOwner is EscrowWithFeeAndETH {
    constructor(uint256 _feePercent) EscrowWithFeeAndETH(_feePercent) {
    }

    function withdraw(uint256 _poolId) external override onlyOwner nonReentrant returns (bool) {
        return _withdraw(_poolId);
    }
}
