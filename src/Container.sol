// SPDX-License-Identifier: No License
pragma solidity ^0.8.20;

enum Status {
    None,
    Pending,
    Registered
}

struct Register {
    uint256 dateOfMarriage;
    address partner1;
    address partner2;
    Status status;
    bool partner1Approve;
    bool partner2Approve;
    bool registered;
}
