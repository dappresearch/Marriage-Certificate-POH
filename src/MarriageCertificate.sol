// SPDX-License-Identifier: No License
pragma solidity ^0.8.20;

import "./IMarriageCertificate.sol";
import "./CertNFT.sol";
import "./Container.sol";

/**
 * @dev This contract demonstrates the simplicity of the marriage registration process
 * without the need for central government identification and organization. For 
 * identity verification, it leverages the decentralized identity protocol, Proof 
 * of Humanity (https://proofofhumanity.id/). Both applicants are required to have a valid ID.
 * 
 * Upon successful registration, a marriage certificate is provided in the form of an NFT.
 * 
 * This contract is for demonstration purposes only, some caveats:-
 * - There is no way to remove marriage registration details.
 * - Using msg.sender is not the right way to approve marriage, future contract will implement signature verfication 
 *   method for approval.
 * 
 * Registration Process:
 * 
 * 1. Three addresses are needed: partner one, partner two, and the registrar.
 * 2. First, add a registrar through `setAuth(address newRegistrar)`. The registrar
 *    will be responsible for approving the marriage. This contract allows anyone to add
 *    a new registrar.
 * 3. Partner one should call `requestMarriageRegistration(address partner1, address partner2, uint256 dateOfMarriage)`, 
 *    where `partner1` is the caller's address, `partner2` is the person whom `partner1` is marrying, and `dateOfMarriage` 
 *    is provided in Unix timestamp format.
 * 4. Partner two should call `partnerApproveMarriage(address partner1)`, where `partner1` should 
 *    have already called `requestMarriageRegistration`.
 * 5. Finally, with the registered registrar's address as the caller, call `completeRegistration(address partner1, address partner2)`.
 * 6. The certificate will be minted as an NFT to the `partner1` address..
 */

interface POH {
    function isRegistered(address _submissionID) external view returns (bool);
}

contract MarriageCertificate is IMarriageCertificate, IMarriageEvents, CertNFT {
        event AuthorizeRegistrar(
        address indexed registrar,
        address indexed authorizer
    );
    
    POH private immutable poh;

    uint256 public regNo;

    // For demonstartion propose.
    bool public demo = true;

    Status constant defaultChoice = Status.None;

    constructor(address proofofhumanity) {
        poh = POH(proofofhumanity);
    }

    error InValidAddress(address participant);
    error InValidApproval(address partner);
    error InValidId(address poh);
    error InValidDate(uint256 date);
    error UnAuthorizedAccess(address caller);
    error InValidRegistrationStatus(address partner1);
    error InCompleteApproval(address partner1);
    error InValidRequest(address partner1, address partner2);

    mapping(address => uint256) private _registerNo;
    mapping(uint256 => Register) private _registerData;
    mapping(address => bool) private _registrars;

    modifier onlyAuthorized() {
        if (!_registrars[_msgSender()]) {
            revert UnAuthorizedAccess(_msgSender());
        }
        _;
    }
    
    function _validateId(address partner1, address partner2) private view {
        if (!poh.isRegistered(partner1)) {
            revert InValidId(partner1);
        } else if (!poh.isRegistered(partner2)) {
            revert InValidId(partner2);
        }
    }

    // If set to true only owner can add new registrar.
    function setDemo(bool change) external onlyOwner {
        demo = change;
    }

    // Add new registrar. 
    function setAuth(address newRegistrar) external {
        if (!demo && _msgSender() != owner()) {
            revert UnAuthorizedAccess(_msgSender());
        }
        _registrars[newRegistrar] = true;
        emit AuthorizeRegistrar(newRegistrar, _msgSender());
    }

    function removeAuth(address newRegistrar) external {
        if (!demo && _msgSender() != owner()) {
            revert UnAuthorizedAccess(_msgSender());
        }
        _registrars[newRegistrar] = false;
    }

    function isRegistrarAdded(address registrar) external view returns (bool){
        return _registrars[registrar];
    }

    function _checkRegistrationStatus(
        Register memory reg
    ) private pure returns (bool) {
        if (reg.status == Status.Registered) {
            revert InValidRegistrationStatus(reg.partner1);
        }
        
        return true;
    }
    
    /**
     * @dev Provide address of two applicants `partner1` and `partner2
     * with `dateOfMarriage` for marriage registration request. 
     * `partner1` address should be the caller address. 
     *  Ensure `partner1` and `partner2 has both valid Id at 
     *  https://proofofhumanity.id/
     */
    function requestMarriageRegistration(address partner1, address partner2, uint256 dateOfMarriage) external {
        if (partner1 == address(0) || partner2 == address(0)) {
            revert InValidAddress(address(0));
        }

        if(dateOfMarriage > block.timestamp) {
            revert InValidDate(dateOfMarriage);
        }

        // Ensure both applicants has valid proof of humanity ID.
        // https://proofofhumanity.id/
        _validateId(partner1, partner2);
        
        // Ensure partner1 is calling this method.
        if (_msgSender() != partner1) {
            revert UnAuthorizedAccess(_msgSender());
        }

        // Load registration data with partner1 address.
        uint256 partner1RegNo = _registerNo[partner1];
        Register storage reg = _registerData[partner1RegNo];

        // Has valid regisration status.
        _checkRegistrationStatus(reg);

        reg.partner1 = partner1;
        reg.partner1Approve = true;

        reg.partner2 = partner2;
        reg.status = Status.Pending;
        reg.dateOfMarriage = dateOfMarriage;

        // By default partner1 address will used to store regitration details.
        _registerNo[partner1] = regNo;

       unchecked {
            regNo++;
        }

        emit RegistrationRequest(_registerNo[_msgSender()], partner1, partner2, reg.dateOfMarriage);
    }
    
    function partnerApproveMarriage(address partner1) external {
        // Get the registration number of partner1.
        uint256 partner1RegNo = _registerNo[partner1];

        // Load the register information.
        Register storage reg = _registerData[partner1RegNo];

        // Has valid proof of humanity id
        // https://proofofhumanity.id/
        _validateId(_msgSender(), reg.partner1);

        // Registartion status should be set to pending.
        _checkRegistrationStatus(reg);

        // Caller should match the address of partner2 added by partner1.
        if (_msgSender() != reg.partner2 || partner1 != reg.partner1) {
            revert UnAuthorizedAccess(_msgSender());
        }

        // Partner1 should have requested the marriage registration.
        if (!reg.partner1Approve) {
            revert InCompleteApproval(partner1);
        }

        // Partner2 registration approval.
        reg.partner2Approve = true;

        // Register number will be same for partner1 and partner2.
        _registerNo[_msgSender()] = partner1RegNo;

        emit Partner2Approved(_registerNo[_msgSender()], reg.partner1, _msgSender());
    }

    function completeRegistration(
        address partner1,
        address partner2
    ) external onlyAuthorized {
        _validateId(partner1, partner2);

        // Get the registration number of partner1.
        uint256 partner1RegNo = _registerNo[partner1];

        Register storage reg = _registerData[partner1RegNo];

        _checkRegistrationStatus(reg);

        if (reg.partner1 != partner1 || reg.partner2 != partner2) {
            revert InValidRequest(partner1, partner2);
        }

        if (!(reg.partner1Approve && reg.partner2Approve)) {
            revert InValidApproval(partner1);
        }

        reg.status = Status.Registered;
        reg.registered = true;

        // Mint the nft certificate to `partner1` address.
        _mintCert(partner1);

        emit RegistrationCompleted(partner1RegNo, partner1, partner2); // Emit event on completion
    }

    function getRecord(
        address partner
    ) external view returns (Register memory) {
        // Get the registration number of partner1.
        uint256 partner1RegNo = _registerNo[partner];
        Register storage reg = _registerData[partner1RegNo];
        return reg;
    }
    
    // This is demo version, so there is no way to remove marriage registration process.
    // However future version will include below methods for removal request.
    // function requestMarriageRemoval() external {}
    // function finalizeMarriageRemoval(address partner1, address partner2) external onlyAuthorized {}
}
