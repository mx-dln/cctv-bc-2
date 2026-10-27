# CCTV Blockchain Chain-of-Custody: Comprehensive Installation & Deployment Guide
> **Target Audience**: Human Engineers, Evaluators, and Autonomous AI Coding Agents (Antigravity, OpenCode, Claude Code, Cursor, Copilot).  
> **Environment**: Windows 10/11 64-bit + Ubuntu WSL2 + Docker Desktop + Hyperledger Fabric 2.5 + Laravel 11.

---

## Table of Contents
1. [System Architecture Overview](#1-system-architecture-overview)
2. [Prerequisites & System Requirements](#2-prerequisites--system-requirements)
3. [Phase 1: Windows Subsystem for Linux (WSL2) Setup](#3-phase-1-windows-subsystem-for-linux-wsl2-setup)
4. [Phase 2: Docker Desktop ("Docket") & WSL2 Integration](#4-phase-2-docker-desktop-docket--wsl2-integration)
5. [Phase 3: Hyperledger Fabric 2.5 Installation inside Ubuntu WSL](#5-phase-3-hyperledger-fabric-25-installation-inside-ubuntu-wsl)
6. [Phase 4: CCTV Custody Chaincode Deployment](#6-phase-4-cctv-custody-chaincode-deployment)
7. [Phase 5: Node.js Fabric Gateway Setup (Windows Host)](#7-phase-5-nodejs-fabric-gateway-setup-windows-host)
8. [Phase 6: Laravel Application Setup & Configuration](#8-phase-6-laravel-application-setup--configuration)
9. [Phase 7: Daily Startup Runbook (4-Step Sequential Guide)](#9-phase-7-daily-startup-runbook-4-step-sequential-guide)
10. [Phase 8: End-to-End Demonstration & Verification Flow](#10-phase-8-end-to-end-demonstration--verification-flow)
11. [Phase 9: Comprehensive Troubleshooting Encyclopedia](#11-phase-9-comprehensive-troubleshooting-encyclopedia)
12. [Phase 10: Defense Q&A and Conceptual Guide](#12-phase-10-defense-qa-and-conceptual-guide)
13. [Phase 11: Copy-Paste Master Prompt for AI Agents](#13-phase-11-copy-paste-master-prompt-for-ai-agents)

---

## 1. System Architecture Overview

The system establishes an immutable, tamper-evident Chain-of-Custody for surveillance footage.

### Core Architecture Principle
* **Off-Chain Storage**: Full CCTV video footage remains in local or private storage (`storage/app/private/cctv_footage`). Large media files are **never** stored directly on the blockchain ledger.
* **On-Chain Cryptographic Proof**: Hyperledger Fabric stores the immutable custody proof:
  * Record ID & Event ID
  * SHA-256 digest of raw video content
  * SHA-256 digest of custody metadata (camera reference, timestamps, operator identity)
  * Fabric Transaction ID (`tx_id`) & Block Number

```
+-----------------------------------------------------------------------------------+
|                                  WINDOWS HOST                                     |
|                                                                                   |
|  +--------------------+         +---------------------+        +---------------+  |
|  |   CCTV Sources     |         |     Laravel 11      |        | Private Video |  |
|  | - Uploaded MP4     | ======> |  - Inertia / React  | =====> | Storage       |  |
|  | - USB / Controlled |         |  - SHA-256 Digester |        | (Off-chain)   |  |
|  | - Mock / DVR       |         +----------+----------+        +---------------+  |
|  +--------------------+                    |                                      |
|                                            | HTTP (JSON REST)                     |
|                                            v                                      |
|                                 +---------------------+                           |
|                                 | Node Fabric Gateway |                           |
|                                 | (Port 8787)         |                           |
|                                 +----------+----------+                           |
+--------------------------------------------|--------------------------------------+
                                             | gRPC / TLS
                                             | (via \\wsl.localhost\Ubuntu\)
+--------------------------------------------|--------------------------------------+
|                           UBUNTU WSL2 / DOCKER ENGINE                             |
|                                            v                                      |
|                                 +---------------------+                           |
|                                 | peer0.org1 (7051)   |                           |
|                                 | Hyperledger Fabric  |                           |
|                                 +----------+----------+                           |
|                                            |                                      |
|                                            v                                      |
|                                 +---------------------+                           |
|                                 | cctv-custody        |                           |
|                                 | Go Chaincode        |                           |
|                                 +---------------------+                           |
+-----------------------------------------------------------------------------------+
```

---

## 2. Prerequisites & System Requirements

### Hardware Requirements
* **CPU**: 64-bit x86_64 Intel/AMD processor with **Virtualization (VT-x / AMD-V)** enabled in BIOS/UEFI.
* **RAM**: Minimum 8 GB (16 GB strongly recommended; Docker + WSL + Node + Laravel utilize ~4-6 GB).
* **Storage**: Minimum 20 GB free disk space (SSD recommended).

### Windows Host Software to Install
1. **Git for Windows**: [https://git-scm.com/download/win](https://git-scm.com/download/win)
2. **Docker Desktop**: [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)
3. **Node.js LTS (v18.x or v20.x)**: [https://nodejs.org/](https://nodejs.org/) (Includes `npm`)
4. **PHP 8.2+ or 8.3+**: [https://windows.php.net/download/](https://windows.php.net/download/) or via [Laravel Herd](https://herd.laravel.com/windows)
   * Required PHP Extensions in `php.ini`:
     * `curl`
     * `fileinfo`
     * `mbstring`
     * `openssl`
     * `pdo_sqlite`
     * `sqlite3`
     * `gd`
5. **Composer 2.x**: [https://getcomposer.org/download/](https://getcomposer.org/download/)

---

## 3. Phase 1: Windows Subsystem for Linux (WSL2) Setup

### 3.1 Install WSL2 and Ubuntu
Open **Windows PowerShell** as Administrator and run:
```powershell
wsl --install -d Ubuntu
```
* If prompted to reboot Windows, restart your computer.
* When the Ubuntu terminal launches, create your Linux user and password:
  * Example username: `michael` (or your choice; the gateway launcher script auto-detects it).

### 3.2 Update and Install Dependencies inside Ubuntu WSL
In Windows PowerShell, launch Ubuntu:
```powershell
wsl -d Ubuntu
```
Inside the Ubuntu terminal, execute:
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl jq golang-go build-essential
```

**Verify tools:**
```bash
git --version
curl --version
jq --version
go version
```

> **Why these dependencies are required**:
> * `git`: Clones Hyperledger repository and fabric-samples.
> * `curl`: Downloads official Fabric install scripts and binaries.
> * `jq`: Required by Fabric test network channel configuration scripts.
> * `golang-go`: Compiles the `cctv-custody` Go smart contract.

---

## 4. Phase 2: Docker Desktop ("Docket") & WSL2 Integration

### 4.1 Enable WSL2 Integration in Docker Desktop
1. Launch **Docker Desktop** on Windows.
2. Open **Settings** (gear icon) -> **General**:
   * Check **"Use the WSL 2 based engine"**.
3. Open **Settings** -> **Resources** -> **WSL Integration**:
   * Turn **ON**: *"Enable integration with my default WSL distro"*.
   * Turn **ON**: *"Ubuntu"* (under Additional distributions).
4. Click **Apply & restart**. Wait until the Docker status indicator turns solid green ("Engine running").

### 4.2 Verify Docker from Windows PowerShell
```powershell
docker --version
docker compose version
docker info
docker run --rm hello-world
```
*Expected: "Hello from Docker!" message.*

### 4.3 Verify Docker inside Ubuntu WSL
```powershell
wsl -d Ubuntu -- docker ps
```
*Expected: Header columns `CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES` with zero errors.*

---

## 5. Phase 3: Hyperledger Fabric 2.5 Installation inside Ubuntu WSL

> **CRITICAL RULE**: Do **NOT** clone or execute Hyperledger Fabric inside `/mnt/c/...` or `C:\Windows\System32`. It **must** reside inside the Linux filesystem home directory (`~/fabric-samples`).

### 5.1 Clone Fabric Samples and Download Binaries
Inside Ubuntu WSL (`wsl -d Ubuntu`):
```bash
cd ~
git clone https://github.com/hyperledger/fabric-samples.git
cd fabric-samples
curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh
chmod +x install-fabric.sh
./install-fabric.sh docker binary
```

Verify downloaded Docker images:
```bash
docker images | grep hyperledger
```
*Expected images include:*
* `ghcr.io/hyperledger/fabric-peer:2.5.x`
* `ghcr.io/hyperledger/fabric-orderer:2.5.x`
* `ghcr.io/hyperledger/fabric-ccenv:2.5.x`
* `ghcr.io/hyperledger/fabric-baseos:2.5.x`
* `ghcr.io/hyperledger/fabric-ca:1.5.x`

### 5.2 Start the Test Network with Channel & Certificate Authorities
Inside Ubuntu WSL:
```bash
cd ~/fabric-samples/test-network
./network.sh down
./network.sh up createChannel -ca
```

*Expected output ending lines:*
```
Channel 'mychannel' created
Anchor peer set for org 'Org1MSP'
Anchor peer set for org 'Org2MSP'
Channel 'mychannel' joined
```

Verify running containers:
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```
*Required containers running:*
* `peer0.org1.example.com`
* `peer0.org2.example.com`
* `orderer.example.com`
* `ca_org1`
* `ca_org2`
* `ca_orderer`

---

## 6. Phase 4: CCTV Custody Chaincode Deployment

The Go chaincode is located in the Windows repository at:
`hyperledger/chaincode/cctv-custody-go`

### 6.1 Automated Deployment (Recommended)
From Windows PowerShell, you can run the deployment helper inside WSL in one command (replace `<PATH_TO_PROJECT>` with your Windows path, e.g., `/mnt/c/Users/...`):

```powershell
wsl -d Ubuntu -- bash -lc "cd ~/fabric-samples/test-network && bash /mnt/c/Users/micha/OneDrive/Documents/Sites/cctv-bc/hyperledger/deploy-chaincode.sh"
```

### 6.2 Manual Step-by-Step Deployment (Alternative)
Inside Ubuntu WSL:
```bash
# 1. Create target chaincode folder in fabric-samples
mkdir -p ~/fabric-samples/cctv-chaincode
rm -rf ~/fabric-samples/cctv-chaincode/cctv-custody-go

# 2. Copy chaincode from Windows mount (adjust path to match your Windows project location)
cp -r /mnt/c/Users/micha/OneDrive/Documents/Sites/cctv-bc/hyperledger/chaincode/cctv-custody-go ~/fabric-samples/cctv-chaincode/

# 3. Clean and verify Go dependencies
cd ~/fabric-samples/cctv-chaincode/cctv-custody-go
go mod tidy

# 4. Deploy chaincode to mychannel
cd ~/fabric-samples/test-network
CGO_ENABLED=0 ./network.sh deployCC \
  -ccn cctv-custody \
  -ccp ../cctv-chaincode/cctv-custody-go \
  -ccl go \
  -ccv 1.0 \
  -ccs 1
```

*Expected output lines:*
```
Chaincode definition committed on channel 'mychannel'
Query chaincode definition successful on peer0.org1
Query chaincode definition successful on peer0.org2
Chaincode initialization is not required
```

---

## 7. Phase 5: Node.js Fabric Gateway Setup (Windows Host)

The Laravel web app communicates with Hyperledger Fabric through an Express.js Gateway running on Windows. The gateway reads TLS certificates directly from WSL via the `\\wsl.localhost\Ubuntu` network share.

### 7.1 Install Gateway Dependencies
Open **Windows PowerShell** and navigate to the gateway directory:
```powershell
cd hyperledger\gateway
npm install
```

### 7.2 Launch the Gateway
You can start the gateway using the automated PowerShell script:
```powershell
.\start-gateway.ps1
```
*(The script automatically queries WSL for the active Linux user, sets all 10 environment variables, and executes `npm start`).*

Alternatively, you can manually set the environment variables and run:
```powershell
$LinuxUser = (wsl -d Ubuntu whoami).Trim()
$wslOrg = "\\wsl.localhost\Ubuntu\home\$LinuxUser\fabric-samples\test-network\organizations\peerOrganizations\org1.example.com"

$env:FABRIC_TLS_CERT_PATH   = "$wslOrg\peers\peer0.org1.example.com\tls\ca.crt"
$env:FABRIC_CERT_DIRECTORY  = "$wslOrg\users\Admin@org1.example.com\msp\signcerts"
$env:FABRIC_KEY_DIRECTORY   = "$wslOrg\users\Admin@org1.example.com\msp\keystore"
$env:FABRIC_PEER_ENDPOINT   = "localhost:7051"
$env:FABRIC_PEER_HOST_ALIAS = "peer0.org1.example.com"
$env:FABRIC_MSP_ID          = "Org1MSP"
$env:FABRIC_CHANNEL         = "mychannel"
$env:FABRIC_CHAINCODE       = "cctv-custody"
$env:PORT                   = "8787"

npm start
```

*Expected output:*
```
CCTV Fabric gateway listening on http://127.0.0.1:8787
```
> **Keep this PowerShell terminal open.**

### 7.3 Test Gateway Health
In a **second Windows PowerShell terminal**, test the health endpoint:
```powershell
curl.exe http://127.0.0.1:8787/health
```

*Expected JSON response:*
```json
{"available":true,"gateway":"Hyperledger Fabric","channel":"mychannel","chaincode":"cctv-custody"}
```

---

## 8. Phase 6: Laravel Application Setup & Configuration

### 8.1 Install PHP & Node Dependencies
In Windows PowerShell, from the project root:
```powershell
composer install
npm install
```

### 8.2 Environment Configuration (.env)
If `.env` does not exist, copy from `.env.example`:
```powershell
Copy-Item .env.example .env
```

Ensure the following critical values are set in `.env`:
```ini
APP_NAME="CCTV Blockchain Chain-of-Custody"
APP_ENV=local
APP_DEBUG=true
APP_URL=http://127.0.0.1:8011

DB_CONNECTION=sqlite
FILESYSTEM_DISK=local

# CCTV & Blockchain Settings
CCTV_PROVIDER=mock
HASH_ALGORITHM=sha256
BLOCKCHAIN_SIMULATE=false
BLOCKCHAIN_PEER_ENDPOINT=127.0.0.1:8787
BLOCKCHAIN_CHANNEL=mychannel
BLOCKCHAIN_CHAINCODE=cctv-custody
BLOCKCHAIN_PEER_NODE=peer0.org1.example.com

# Video Upload Constraints
CCTV_UPLOAD_MEMORY_LIMIT=1024M
CCTV_UPLOAD_MAX_FILESIZE=1024M
CCTV_UPLOAD_POST_MAX_SIZE=1050M
```

### 8.3 Generate App Key, Initialize Database, and Discover Cameras
```powershell
# 1. Generate app encryption key
php artisan key:generate

# 2. Ensure SQLite database file exists
if (-not (Test-Path database\database.sqlite)) {
    New-Item -ItemType File -Path database\database.sqlite
}

# 3. Run database migrations & seed default users
php artisan migrate:fresh --seed

# 4. Create public storage symlink
php artisan storage:link

# 5. Populate mock surveillance cameras
php artisan cctv:discover-cameras

# 6. Clear cached configurations
php artisan optimize:clear

# 7. Compile frontend assets
npm run build
```

---

## 9. Phase 7: Daily Startup Runbook (4-Step Sequential Guide)

Whenever you boot the computer to demonstrate or develop the application, execute these 4 steps in order:

### Step 1: Start Docker Desktop
Launch Docker Desktop from the Windows Start menu. Wait for the status indicator to turn solid green ("Engine running").

### Step 2: Confirm or Start Fabric in WSL
In Windows PowerShell:
```powershell
wsl -d Ubuntu -- bash -lc "cd ~/fabric-samples/test-network && docker ps"
```
*If peer/orderer containers are stopped, bring them up:*
```powershell
wsl -d Ubuntu -- bash -lc "cd ~/fabric-samples/test-network && ./network.sh up createChannel -ca"
```

### Step 3: Start Node Fabric Gateway
In Windows PowerShell (Terminal 1):
```powershell
cd hyperledger\gateway
.\start-gateway.ps1
```
*Confirm output: `CCTV Fabric gateway listening on http://127.0.0.1:8787`.*

### Step 4: Start Laravel Application Server
In Windows PowerShell (Terminal 2):
```powershell
php artisan serve --host=127.0.0.1 --port=8011
```
Open your browser to:
👉 **[http://127.0.0.1:8011](http://127.0.0.1:8011)**

---

## 10. Phase 8: End-to-End Demonstration & Verification Flow

### 10.1 Default System Credentials
* **URL**: `http://127.0.0.1:8011/login`
* **Email**: `admin@ficobank.com`
* **Password**: `password`

### 10.2 Register and Commit Evidence
1. Navigate to **Evidence Register** in the top navigation.
2. Select any Camera from the dropdown (e.g., `CAM-001 (Main Lobby)`).
3. Under **CCTV footage file**, upload any MP4 video file (keep it small, e.g., 5-20 MB for quick hashing).
4. Fill in recording details:
   * **Filename**: `evidence_lobby_sample.mp4`
   * **Resolution**: `1920x1080`
   * **Date / Time**: Current date/time
5. Click **Register, Hash, and Commit**.
6. **Verify Result**: The record appears in the register table with status **Fabric: committed**.

### 10.3 Inspect Blockchain Proof
1. Navigate to **Fabric Ledger** (or **Blockchain**).
2. Locate the registered evidence entry.
3. Confirm the **Transaction ID** is a 64-character hexadecimal string generated by Hyperledger Fabric (e.g., `4790104d2665818ffad85784aa1f3a00afa29b5b6433982861508c05f4d07b22`) and a valid Block Number (e.g., `13`).
   *(It must NOT be a simulated `TX-...` placeholder).*

### 10.4 Verify Stored Original Evidence
1. Navigate to **Evidence Verification**.
2. Find the registered evidence and click **Verify Stored Original**.
3. **Verify Result**: The badge displays **Verified** (green). The recalculated SHA-256 hash matches the blockchain-recorded hash exactly.

### 10.5 Demonstrate Tamper Detection
1. In **Evidence Verification**, on the same record, locate the **Upload comparison video** field.
2. Select a modified, trimmed, or entirely different MP4 video file.
3. Click **Compare**.
4. **Verify Result**: The badge displays **Tampered** (red) with an explicit integrity mismatch alert showing differing hash digests.

---

## 11. Phase 9: Comprehensive Troubleshooting Encyclopedia

### Issue 1: `failed to connect to the docker API at npipe:////./pipe/docker_engine`
* **Cause**: Docker Desktop is not running or still initializing.
* **Fix**: Start Docker Desktop and wait 30 seconds until the engine icon is solid green.

### Issue 2: `fatal: could not create work tree dir 'fabric-samples': Permission denied`
* **Cause**: Attempting to run `git clone` inside `C:\Windows\System32` or an unauthorized directory.
* **Fix**: Run `cd ~` inside Ubuntu WSL before cloning.

### Issue 3: Fabric fails with `/etc/hyperledger/fabric/msp does not exist`
* **Cause**: Fabric was started inside `/mnt/c/...` across the Windows filesystem boundary.
* **Fix**: Fabric test-network **must** be executed in the native Linux path: `~/fabric-samples/test-network`.

### Issue 4: `jq: command not found` or `go: command not found` in WSL
* **Cause**: Missing Linux development packages.
* **Fix**: Inside Ubuntu WSL, run:
  ```bash
  sudo apt update && sudo apt install -y jq golang-go
  ```

### Issue 5: Fabric Gateway fails with `FABRIC_TLS_CERT_PATH is required` or `No identity file found`
* **Cause**: The gateway script is pointing to a non-existent WSL user folder, or the Fabric network has not created its certificates yet.
* **Fix**:
  1. Ensure `./network.sh up createChannel -ca` completed successfully in WSL.
  2. Run `.\start-gateway.ps1`, which automatically auto-detects the active WSL user.

### Issue 6: Evidence status shows `Fabric: pending`
* **Cause**: Laravel recorded the evidence locally, but the Fabric Gateway was unavailable, stopped, or chaincode was not committed.
* **Fix**:
  1. Start the Node Gateway (`.\start-gateway.ps1`).
  2. Verify health: `curl.exe http://127.0.0.1:8787/health`.
  3. In the Evidence Register, click the **Commit** button on the pending record to retry the Fabric submission.

### Issue 7: Camera list is empty
* **Cause**: Surveillance cameras have not been seeded into the database.
* **Fix**: Run in Windows PowerShell:
  ```powershell
  php artisan cctv:discover-cameras
  ```

### Issue 8: Large video upload fails (HTTP 413 or Post Too Large)
* **Cause**: PHP upload limits in `php.ini` or `.user.ini` are smaller than the file size.
* **Fix**: In `.env`, ensure `CCTV_UPLOAD_MAX_FILESIZE=1024M` and `CCTV_UPLOAD_POST_MAX_SIZE=1050M`. If running under Laravel Herd, update Herd's active `php.ini` (`upload_max_filesize = 1024M`, `post_max_size = 1050M`, `memory_limit = 1024M`).

---

## 12. Phase 10: Defense Q&A and Conceptual Guide

### Q1: Why not store the entire video on the blockchain?
> **Answer**: Video files are large (megabytes to gigabytes). Blockchains are distributed ledgers duplicated across every participating node; storing bulk multimedia directly on-chain degrades network throughput, bloats storage, and causes consensus bottlenecks.  
> The cryptographically sound and industry-standard architecture is **off-chain storage with on-chain verification**: video files reside in secure private storage, while their cryptographic SHA-256 fingerprint, custody metadata, and transaction proof are recorded immutably on Hyperledger Fabric. Any alteration to even a single pixel in the video produces a completely different hash digest, triggering an immediate tampering alert.

### Q2: Is a physical DVR / NVR strictly required to run this prototype?
> **Answer**: No. The prototype enforces the core chain-of-custody process: intake of authorized footage bytes -> off-chain storage -> SHA-256 hashing -> Fabric ledger commit -> integrity verification. For testing and demonstration, footage can be uploaded directly as CCTV MP4 files, captured via USB/controlled camera, or generated by the included Mock Provider. In an enterprise production deployment, the intake layer connects directly to physical NVR/DVR storage or RTSP/ONVIF streams.

### Q3: How does the system detect tampering?
> **Answer**: Through deterministic SHA-256 hashing. When an evidence file is first registered, the system computes `SHA-256(RawVideoContent)` and `SHA-256(CustodyMetadata)`, binding them into a custody record stored on Hyperledger Fabric. During verification, the system re-computes the hash of the file currently in storage and compares it with the immutable value on the ledger. If even 1 byte was altered, truncated, or re-encoded, the hashes will not match, flagging the evidence as **Tampered**.

---

## 13. Phase 11: Copy-Paste Master Prompt for AI Agents

When deploying this project on a brand new machine using an autonomous AI coding assistant (such as Antigravity, OpenCode, Claude Code, or Cursor), copy and paste the master prompt below:

```markdown
You are deploying and verifying the CCTV Blockchain Chain-of-Custody project end to end on this computer.

Project Details:
- Architecture: Off-chain Video Storage + SHA-256 Hashing + Hyperledger Fabric 2.5 + Node Gateway + Laravel 11.
- Location: Current project root directory.

Execute the following sequential deployment and validation tasks:

1. System & Docker Checks:
   - Verify Docker Desktop is running: `docker --version`, `docker info`.
   - Verify WSL2 is accessible: `wsl -d Ubuntu -- uname -a`.
   - Verify Docker is operational inside Ubuntu WSL: `wsl -d Ubuntu -- docker ps`.

2. Hyperledger Fabric Network (inside Ubuntu WSL):
   - Check if `~/fabric-samples/test-network` exists. If not, clone `https://github.com/hyperledger/fabric-samples.git` and install binaries via `install-fabric.sh docker binary`.
   - Start the network with Certificate Authorities: `./network.sh up createChannel -ca`.
   - Verify essential containers are running: `peer0.org1.example.com`, `peer0.org2.example.com`, `orderer.example.com`, `ca_org1`.

3. Deploy CCTV Chaincode:
   - Sync `hyperledger/chaincode/cctv-custody-go` to `~/fabric-samples/cctv-chaincode/cctv-custody-go`.
   - Run `go mod tidy` in the chaincode directory.
   - Deploy chaincode to channel `mychannel`: `./network.sh deployCC -ccn cctv-custody -ccp ../cctv-chaincode/cctv-custody-go -ccl go`.

4. Start Node.js Fabric Gateway:
   - Navigate to `hyperledger/gateway`.
   - Install dependencies: `npm install`.
   - Run `hyperledger/gateway/start-gateway.ps1` in the background (or execute `npm start` with the WSL certificates mapped).
   - Verify health check synchronously: `curl.exe http://127.0.0.1:8787/health` must return `{"available":true,...}`.

5. Configure & Build Laravel Application:
   - Run `composer install` and `npm install`.
   - Ensure `.env` exists with `BLOCKCHAIN_SIMULATE=false`, `BLOCKCHAIN_PEER_ENDPOINT=127.0.0.1:8787`, `CCTV_PROVIDER=mock`, `DB_CONNECTION=sqlite`.
   - Run `php artisan key:generate`.
   - Run `php artisan migrate:fresh --seed`.
   - Run `php artisan storage:link`.
   - Run `php artisan cctv:discover-cameras`.
   - Run `npm run build`.

6. Run Quality Verification:
   - Run test suite: `php artisan test --compact`.
   - Run type check: `npm run types:check`.

Report back when all services are healthy and ready for live demonstration.
```
