// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/POHMock.sol";
import "../src/MarriageCertificate.sol";
import {IMarriageEvents} from "../src/IMarriageCertificate.sol";

import "../src/Container.sol";

contract MarriageCertificateTest is IMarriageEvents, Test {
    MarriageCertificate public mc;
    MarriageCertificate public mcf;

    POHMockTest public poh;
    POHMockTestFail public pohf;

    uint256 internal ownerPrivateKey;
    uint256 internal partner1PrivateKey;
    uint256 internal partner2PrivateKey;
    uint256 internal registrarPrivateKey;
    uint256 internal randomGuyPrivateKey;

    address ownerAddr;
    address partner1Addr;
    address partner2Addr;
    address randomGuyAddr;
    address registrarAddr;

    uint256 dateOfMarriage;

    // Testing for future date using vm.wrap
    uint256 wrapDate;

    function setUp() public {
        
        poh = new POHMockTest();
        pohf = new POHMockTestFail();
        mc = new MarriageCertificate(address(poh));
        mcf = new MarriageCertificate(address(pohf));

        ownerPrivateKey = 0x1111;
        partner1PrivateKey = 0x1234;
        partner2PrivateKey = 0x5678;

        randomGuyPrivateKey = 0x7890;

        registrarPrivateKey = 0x9999;

        ownerAddr = vm.addr(ownerPrivateKey);
        partner1Addr = vm.addr(partner1PrivateKey);
        partner2Addr = vm.addr(partner2PrivateKey);
        randomGuyAddr = vm.addr(randomGuyPrivateKey);
        registrarAddr = vm.addr(registrarPrivateKey);

        vm.label(ownerAddr, "Owner");
        vm.label(partner1Addr, "Partner1");
        vm.label(partner2Addr, "Partner2");
        vm.label(randomGuyAddr, "RandomGuy");
        vm.label(registrarAddr, "Registrar");

        dateOfMarriage = 1720436400; // Sample date

        wrapDate = dateOfMarriage + 1000;
    }

    // register marriage in future block timestamp.
    function _registerMarriage() private {
        vm.warp(wrapDate);
        
        vm.prank(partner1Addr);
        mc.requestMarriageRegistration(
            partner1Addr,
            partner2Addr,
            dateOfMarriage
        );
    }
    
    function _approveMarriage(address prankAddr, address partner) private {
        vm.prank(prankAddr);
        mc.partnerApproveMarriage(partner);
    }

    function testAuthRegisration() public {
        vm.prank(partner1Addr);
        mc.setAuth(registrarAddr);
        assertEq(mc.isRegistrarAdded(registrarAddr), true);
        vm.stopPrank();
    }

    function testSetAuthFail_UnAuthorizeAcesss() public {
        vm.prank(ownerAddr);
        mc.setAuth(registrarAddr);

        vm.prank(ownerAddr);
        mc.removeAuth(registrarAddr);

        vm.expectRevert(
            abi.encodeWithSelector(
                MarriageCertificate.UnAuthorizedAccess.selector,
                registrarAddr
            )
        );
        vm.prank(registrarAddr);
        mc.completeRegistration(partner1Addr, partner2Addr);
    }

    function testSetDemo() public {
        mc.setDemo(false);
        assertEq(mc.demo(), false);
    }

    function testSetDemoFail_UnAuthorizedAccess() public {
        mc.setDemo(false);
        vm.expectRevert(
            abi.encodeWithSelector(
                MarriageCertificate.UnAuthorizedAccess.selector,
                ownerAddr
            )
        );
       vm.prank(ownerAddr);
       mc.setAuth(registrarAddr);
    }    

    function testRequestMarriageRegistration() public {
        _registerMarriage();

        Register memory record = mc.getRecord(partner1Addr);

        assertEq(
            record.partner1,
            partner1Addr,
            "Partner1 address not correct."
        );
        assertEq(
            record.partner2,
            partner2Addr,
            "Partner2 address not correct."
        );
        assertEq(
            uint256(record.status),
            uint256(Status.Pending),
            "Marriage status incorrect."
        );
        assertEq(
            record.dateOfMarriage,
            dateOfMarriage,
            "Incorrect date of marriage."
        );
        assertEq(
            record.partner1Approve,
            true,
            "Partner1 should have approved."
        );
        assertEq(
            record.partner2Approve,
            false,
            "Partner2 should not have approved yet."
        );

        assertEq(
            mc.regNo(),
            1,
            "Registration number should increase accordingly"
        );
    }

    function testRequestMarriageRegistration_Emit() public {
        vm.expectEmit(true, true, true, true);
        emit RegistrationRequest(0, partner1Addr, partner2Addr, dateOfMarriage);
        _registerMarriage();
    }

    function testRequestMarriageRegistration_Fail_InValidDate() public {
        vm.prank(partner1Addr);
         vm.expectRevert(
            abi.encodeWithSelector(
                MarriageCertificate.InValidDate.selector,
                dateOfMarriage
            )
         );

        mc.requestMarriageRegistration(
            partner1Addr,
            partner2Addr,
            dateOfMarriage
        );
    }

    function testRequestMarriageRegistrationFail_InvalidIdPartner() public {
        // Future time
        vm.warp(wrapDate);

        vm.expectRevert(
            abi.encodeWithSelector(
                MarriageCertificate.InValidId.selector,
                partner1Addr
            )
        );
        vm.prank(partner1Addr);

        // POHMockTestFail contact.
        mcf.requestMarriageRegistration(
            partner1Addr,
            partner2Addr,
            dateOfMarriage
        );
    }

    function testPartnerApproveMarriage() public {
        _registerMarriage();
        _approveMarriage(partner2Addr, partner1Addr);
        Register memory record = mc.getRecord(partner1Addr);
        assertEq(
            record.partner2Approve,
            true,
            "Partner2 should have approved."
        );
    }

    function testPartnerApprovalMarriage_Emit() public {
        _registerMarriage();

        vm.expectEmit(true, true, true, false);
        emit Partner2Approved(0, partner1Addr, partner2Addr);
        _approveMarriage(partner2Addr, partner1Addr);
    }

    function testCompleteRegistration() public {
        _registerMarriage();

        _approveMarriage(partner2Addr, partner1Addr);
        
        vm.prank(partner1Addr);
        mc.setAuth(registrarAddr);

        vm.prank(registrarAddr);
        mc.completeRegistration(partner1Addr, partner2Addr);

        Register memory record = mc.getRecord(partner1Addr);
        
        assertEq(
            uint256(record.status),
            uint256(Status.Registered),
            "Marriage should be registered."
        );
        assertEq(
            record.registered,
            true,
            "Marriage should be marked as registered."
        );
        
        // Register number increases with value 1.
        assertEq(mc.regNo(), 1);

        //NFT certificate minted test.
        assertEq(mc.ownerOf(0), partner1Addr);
    }

    function testCompleteRegistrationFail_UnapprovedMarriage() public {
        _registerMarriage();

        vm.prank(ownerAddr);
        mc.setAuth(registrarAddr);

        vm.expectRevert(
            abi.encodeWithSelector(
                MarriageCertificate.InValidApproval.selector,
                partner1Addr
            )
        );
        vm.prank(registrarAddr);
        mc.completeRegistration(partner1Addr, partner2Addr);
    }

    function testCompleteRegistrationFail_InvalidRequest() public {
        _registerMarriage();

        vm.prank(partner2Addr);
        mc.partnerApproveMarriage(partner1Addr);

        vm.prank(ownerAddr);
        mc.setAuth(registrarAddr);

        vm.expectRevert(
            abi.encodeWithSelector(
                MarriageCertificate.InValidRequest.selector,
                partner1Addr,
                randomGuyAddr
            )
        );
        vm.prank(registrarAddr);
        mc.completeRegistration(partner1Addr, randomGuyAddr);
    }

    function testCompleteRegistrationFail_UnAuthorizedAccess() public {
        _registerMarriage();

        _approveMarriage(partner2Addr, partner1Addr);
     
        vm.prank(ownerAddr);
        mc.setAuth(registrarAddr);

        vm.expectRevert(
            abi.encodeWithSelector(
                MarriageCertificate.UnAuthorizedAccess.selector,
                randomGuyAddr
            )
        );
        vm.prank(randomGuyAddr);
        mc.completeRegistration(partner1Addr, partner2Addr);
    }
}
