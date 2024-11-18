// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/MarriageCertificate.sol";
import "../src/POHMock.sol";

import {Register} from "../src/Container.sol";
/**
 * @dev This script is for local testnet deployment through anvil. 
 *  Create .env at the root directory and create four keys,
 *  OWNER, PARTNER_ONE, PARTNER_TWO, and REGISTRAR.
 *  Assign each of the keys with differnt private key through anvil.
 *  
 */
contract AnvilMyScript is Script {
    MarriageCertificate public mc;
    POHMockTest public poh;
    uint256 senderPrivateKey;
    uint256 dateOfMarriage = 1720436400;
    address partnerOne = vm.addr(vm.envUint("PARTNER_ONE"));
    address partnerTwo = vm.addr(vm.envUint("PARTNER_TWO"));
    address registrar = vm.addr(vm.envUint("REGISTRAR"));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("OWNER");
        vm.startBroadcast(deployerPrivateKey);
        poh = new POHMockTest();
        mc = new MarriageCertificate(address(poh));
        vm.stopBroadcast();

        senderPrivateKey = vm.envUint("PARTNER_ONE");
        vm.startBroadcast(senderPrivateKey);
        mc.setAuth(vm.addr(vm.envUint("REGISTRAR")));
        mc.requestMarriageRegistration(partnerOne, partnerTwo, dateOfMarriage);
        vm.stopBroadcast();

        senderPrivateKey = vm.envUint("PARTNER_TWO");
        vm.startBroadcast(senderPrivateKey);
        mc.partnerApproveMarriage(partnerOne);
        vm.stopBroadcast();

        senderPrivateKey = vm.envUint("REGISTRAR");
        vm.startBroadcast(senderPrivateKey);
        mc.completeRegistration(partnerOne, partnerTwo);

        Register memory reg = mc.getRecord(partnerOne);
        
        console.log(
            "dateOfMarriage: %s, partner1: %s, partner2: %s",
            reg.dateOfMarriage,
            reg.partner1,
            reg.partner2
        );

        console.log(
            "status: %s, partner1Approve: %s, partner2Approve: %s",
            reg.dateOfMarriage,
            reg.partner1Approve,
            reg.partner2Approve
        );

        console.log("registered: %s", reg.registered);
        console.log("ownerOf id 0 %s", mc.ownerOf(0));

        vm.stopBroadcast();
    }
}

contract SepoliaMyScript is Script {
    MarriageCertificate public mc;
    POHMockTest public poh;
    uint256 dateOfMarriage = 1720436400;
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        poh = new POHMockTest();
        mc = new MarriageCertificate(address(poh));
        console.log("contract address %s", address(mc));
        vm.stopBroadcast();
    }
}
