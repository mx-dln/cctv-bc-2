# ==============================================================================
# CCTV Hyperledger Fabric Gateway Launcher for Windows PowerShell
# ==============================================================================
# This script auto-detects your Ubuntu WSL username and environment,
# sets all necessary Fabric gRPC environment variables, and launches the gateway.
# ==============================================================================

param(
    [string]$Distro = "Ubuntu",
    [string]$LinuxUser = "",
    [string]$Port = "8787",
    [string]$PeerEndpoint = "localhost:7051",
    [string]$PeerHostAlias = "peer0.org1.example.com",
    [string]$MspId = "Org1MSP",
    [string]$Channel = "mychannel",
    [string]$Chaincode = "cctv-custody"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Starting CCTV Hyperledger Fabric Gateway (Windows Host)  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Detect Ubuntu username if not provided
if (-not $LinuxUser) {
    try {
        $LinuxUser = (wsl -d $Distro whoami).Trim()
        Write-Host "[+] Detected WSL ($Distro) user: $LinuxUser" -ForegroundColor Green
    } catch {
        $LinuxUser = "michael"
        Write-Host "[-] Could not auto-detect WSL user. Falling back to default: $LinuxUser" -ForegroundColor Yellow
    }
} else {
    Write-Host "[*] Using specified WSL user: $LinuxUser" -ForegroundColor Green
}

# 2. Build paths to the Fabric crypto material inside WSL
$wslBase = "\\wsl.localhost\$Distro\home\$LinuxUser\fabric-samples\test-network\organizations\peerOrganizations\org1.example.com"
$tlsCert = "$wslBase\peers\peer0.org1.example.com\tls\ca.crt"
$certDir = "$wslBase\users\Admin@org1.example.com\msp\signcerts"
$keyDir  = "$wslBase\users\Admin@org1.example.com\msp\keystore"

# 3. Verify that the files exist in WSL
Write-Host "[*] Checking Fabric crypto materials in WSL..." -ForegroundColor DarkGray
if (-not (Test-Path $tlsCert)) {
    Write-Host "[!] WARNING: TLS CA cert not found at $tlsCert" -ForegroundColor Yellow
    Write-Host "    Ensure Ubuntu WSL has fabric-samples running: ./network.sh up createChannel -ca" -ForegroundColor Yellow
}
if (-not (Test-Path $certDir)) {
    Write-Host "[!] WARNING: Admin signcerts directory not found at $certDir" -ForegroundColor Yellow
}
if (-not (Test-Path $keyDir)) {
    Write-Host "[!] WARNING: Admin keystore directory not found at $keyDir" -ForegroundColor Yellow
}

# 4. Set environment variables
$env:FABRIC_TLS_CERT_PATH   = $tlsCert
$env:FABRIC_CERT_DIRECTORY  = $certDir
$env:FABRIC_KEY_DIRECTORY   = $keyDir
$env:FABRIC_PEER_ENDPOINT   = $PeerEndpoint
$env:FABRIC_PEER_HOST_ALIAS = $PeerHostAlias
$env:FABRIC_MSP_ID          = $MspId
$env:FABRIC_CHANNEL         = $Channel
$env:FABRIC_CHAINCODE       = $Chaincode
$env:PORT                   = $Port

Write-Host "[+] Environment configured:" -ForegroundColor Green
Write-Host "    - Port: $env:PORT"
Write-Host "    - Peer: $env:FABRIC_PEER_ENDPOINT ($env:FABRIC_PEER_HOST_ALIAS)"
Write-Host "    - Channel: $env:FABRIC_CHANNEL | Chaincode: $env:FABRIC_CHAINCODE"
Write-Host "    - TLS Cert: $env:FABRIC_TLS_CERT_PATH"
Write-Host "----------------------------------------------------------"

# 5. Launch Node gateway
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

if (-not (Test-Path "node_modules")) {
    Write-Host "[*] Installing node modules for gateway..." -ForegroundColor Yellow
    npm install
}

Write-Host "[*] Launching Gateway Server..." -ForegroundColor Cyan
npm start
