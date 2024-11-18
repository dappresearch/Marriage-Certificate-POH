// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract POHMockTest {
    function isRegistered(address user) external pure returns (bool) {
        user;
        return true;
    }
}

contract POHMockTestFail {
    function isRegistered(address user) external pure returns (bool) {
        user;
        return false;
    }
}