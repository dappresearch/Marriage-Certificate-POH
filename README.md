## MARRIAGE-CERTIFICATE-POH

This contract demonstrates the simplicity of the marriage registration process
without the need for central government identification and organization. For 
identity verification, it leverages the decentralized identity protocol, Proof 
of Humanity (https://proofofhumanity.id/). Both applicants are required to have a valid ID.
 
Upon successful registration, a marriage certificate is provided in the form of an NFT.
This contract is for demonstration purposes only, some caveats:-
There is no way to remove marriage registration details.
Using msg.sender is not the right way to approve marriage, future contract will implement signature verfication 
method for approval.

### Build and Test

```shell
$ forge build
$ forge test
```
### Local testnet deployment

```shell
$ anvil
$ forge script script/MarriageCertificate.s.sol:AnvilMyScript --fork-url http://localhost:8545 --broadcast
```
OR

```shell
$ anvil
$ chomd +x deployInAnvil.sh
$ ./deployInAnvil.sh
```

### Sepolia network deployment
- Check example.env
- Create .env at root folder and structure variables according to example.env

```shell
$ chmod +x deploySepolia.sh
$ sounce .env
$ forge script script/MarriageCertificate.s.sol:SepoliaMyScript --rpc-url $SEPOLIA_RPC_URL --broadcast
```

 ### Registration Process:
 
 1. Three addresses are needed: partner one, partner two, and the registrar.
 2. First, add a registrar through `setAuth(address newRegistrar)`. The registrar
    will be responsible for approving the marriage. This contract allows anyone to add
    a new registrar.
 3. Partner one should call `requestMarriageRegistration(address partner1, address partner2, uint256 dateOfMarriage)`, 
    where `partner1` is the caller's address, `partner2` is the person whom `partner1` is marrying, and `dateOfMarriage` 
    is provided in Unix timestamp format.
 4. Partner two should call `partnerApproveMarriage(address partner1)`, where `partner1` should 
    have already called `requestMarriageRegistration`.
 5. Finally, with the registered registrar's address as the caller, call `completeRegistration(address partner1, address partner2)`.
 6. The certificate will be minted as an NFT to the `partner1` address..


