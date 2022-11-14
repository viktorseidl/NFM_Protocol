/**
 *Submitted for verification at polygonscan.com on 2022-11-13
 Polygon Mainnet: 0xC769e60e172aA0AfB5097F5d94a1DDCD4942c797
 */

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.13;

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// @title This is a placeholder contract that will take the place of the original contract while it is still being created.
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract DaoYield {
    uint256 public timer;

    constructor() {
        timer = block.timestamp + (3600 * 24 * 30 * 12 * 15);
    }

    function _trackingBlocker() public view returns (uint256) {
        return timer;
    }
}
