#!/usr/bin/env bash
# ==============================================================================
# CCTV Chaincode Deployment Helper for Ubuntu WSL
# ==============================================================================
# Run this script inside Ubuntu WSL:
#   cd ~/fabric-samples/test-network
#   bash /path/to/cctv-bc/hyperledger/deploy-chaincode.sh
# Or from the project directory inside WSL:
#   ./hyperledger/deploy-chaincode.sh
# ==============================================================================

set -euo pipefail

# Directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHAINCODE_SRC="${SCRIPT_DIR}/chaincode/cctv-custody-go"

# Fabric samples path in user home
FABRIC_DIR="${HOME}/fabric-samples"
TEST_NET_DIR="${FABRIC_DIR}/test-network"
DEST_CHAINCODE_DIR="${FABRIC_DIR}/cctv-chaincode"

echo "=========================================================="
echo " Deploying CCTV Custody Chaincode to Hyperledger Fabric   "
echo "=========================================================="

if [ ! -d "${TEST_NET_DIR}" ]; then
  echo "[-] ERROR: fabric-samples not found at ${FABRIC_DIR}."
  echo "    Please run the fabric-samples installation first."
  exit 1
fi

echo "[*] Step 1: Syncing chaincode to WSL home directory..."
mkdir -p "${DEST_CHAINCODE_DIR}"
rm -rf "${DEST_CHAINCODE_DIR}/cctv-custody-go"
cp -r "${CHAINCODE_SRC}" "${DEST_CHAINCODE_DIR}/"

echo "[*] Step 2: Preparing Go dependencies..."
cd "${DEST_CHAINCODE_DIR}/cctv-custody-go"
go mod tidy

echo "[*] Step 3: Deploying chaincode to channel 'mychannel'..."
cd "${TEST_NET_DIR}"
export CGO_ENABLED=0
./network.sh deployCC \
  -ccn cctv-custody \
  -ccp ../cctv-chaincode/cctv-custody-go \
  -ccl go \
  -ccv 1.0 \
  -ccs 1

echo "=========================================================="
echo "[+] CCTV Custody Chaincode deployed successfully!"
echo "=========================================================="
