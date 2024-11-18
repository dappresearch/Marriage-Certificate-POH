#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

source "$DIR/../.env"

POHMOCK=$(forge create \
    --rpc-url ${SEPOLIA_RPC_URL} \
    --private-key ${PRIVATE_KEY} \
    src/POHMock.sol:POHMockTest
)

POHMOCK_ADDRESS=$(echo "$POHMOCK" | grep "Deployed to:" | awk '{print $3}')
echo "POHMOCK deployed at ${POHMOCK_ADDRESS}"

echo "Deploying MarriageCerticate at Sepolia Network"

MARRIAGE_CERTIFICATE=$(forge create \
    --rpc-url ${SEPOLIA_RPC_URL} \
    --private-key ${PRIVATE_KEY} \
    src/MarriageCertificate.sol:MarriageCertificate \
    --constructor-args ${POHMOCK_ADDRESS})

MARRIAGE_CERTIFICATE_ADDRESS=$(echo "$MARRIAGE_CERTIFICATE" | grep "Deployed to:" | awk '{print $3}')
echo "MarriageCertificate deployed at ${MARRIAGE_CERTIFICATE_ADDRESS}"

