
RPC_URL=http://localhost:8545
PRIVATE_KEY='0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'

echo "Deploying POHMock at Anvil"

POHMOCK=$(forge create \
    --rpc-url ${RPC_URL} \
    --private-key ${PRIVATE_KEY} \
    src/POHMock.sol:POHMockTest
)

POHMOCK_ADDRESS=$(echo "$POHMOCK" | grep "Deployed to:" | awk '{print $3}')
echo "POHMOCK deployed at ${POHMOCK_ADDRESS}"

echo "Deploying MarriageCerticate at Anvil"

MARRIAGE_CERTIFICATE=$(forge create \
    --rpc-url ${RPC_URL} \
    --private-key ${PRIVATE_KEY} \
    src/MarriageCertificate.sol:MarriageCertificate \
    --constructor-args ${POHMOCK_ADDRESS})

MARRIAGE_CERTIFICATE_ADDRESS=$(echo "$MARRIAGE_CERTIFICATE" | grep "Deployed to:" | awk '{print $3}')
echo "MarriageCertificate deployed at ${MARRIAGE_CERTIFICATE_ADDRESS}"

