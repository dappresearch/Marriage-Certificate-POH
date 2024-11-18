// SPDX-License-Identifier: No License
import {Register} from "./Container.sol";

pragma solidity ^0.8.20;

interface IMarriageCertificate {
    function requestMarriageRegistration(address partner1, address partner2, uint256 dateOfMarriage) external;
    function partnerApproveMarriage(address partner1) external; 
    function completeRegistration(address partner1, address partner2) external;
    function getRecord(address partner) external view returns (Register memory);
}

interface IMarriageEvents {
    event Partner2Approved(
        uint256 indexed registrationNumber,
        address indexed partner1,
        address partner2
    );

    event RegistrationRequest(
        uint256 indexed registrationNum,
        address indexed partner1,
        address indexed partner2,
        uint256 dateOfMarriage
    );

    event RegistrationCompleted(
        uint256 indexed registrationNum,
        address indexed partner1,
        address indexed partner2
    );
}


