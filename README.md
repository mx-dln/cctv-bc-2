# CCTV Blockchain Chain-of-Custody System

> An enterprise-grade, tamper-evident Chain-of-Custody prototype for CCTV surveillance footage using **Hyperledger Fabric 2.5**, **SHA-256 Cryptographic Hashing**, and **Laravel 11 / Inertia React**.

---

## 📖 Complete Documentation & Installation Guides
* 🚀 **[Comprehensive AI & Human Installation Guide](COMPREHENSIVE_AI_INSTALLATION_GUIDE.md)**: Full step-by-step installation instructions for Docker Desktop, WSL2, Hyperledger Fabric, Go Chaincode, Node Gateway, and Laravel on any computer.
* 📋 **[User Manual](USER_MANUAL.txt)**: End-to-end user manual, panel defense script, and demonstration workflow.
* ⚙️ **[Hyperledger Detailed Install Notes](HYPERLEDGER_INSTALL_GUIDE.txt)**: Technical log and step-by-step notes for Hyperledger Fabric test network setup.
* 🤖 **[OpenCode Automation Run Prompt](OPENCODE_RUN_PROMPT.txt)**: Single-prompt runbook for AI coding assistants.
* 🏛️ **[Architecture & Defense Audit](docs/architecture-audit.md)**: Academic capstone evaluation and requirement compliance audit.

---

## 🏗️ System Architecture

```
Authorized CCTV Footage (MP4 / USB / Mock / DVR)
           │
           ▼
Off-Chain Local Private Storage (storage/app/private/cctv_footage)
           │
           ├─► SHA-256 Video Digest
           ├─► SHA-256 Custody Metadata Digest
           │
           ▼
Node.js Fabric Gateway API (Port 8787 via gRPC / TLS)
           │
           ▼
Hyperledger Fabric 2.5 (Channel: 'mychannel', Chaincode: 'cctv-custody')
           │
           ▼
Evidence Verification & Tamper Detection (Bit-level Integrity Validation)
```

### Core Architecture Principles
1. **Off-Chain Media Storage**: Video footage is securely retained in private local storage. Full video files are **never** stored directly on the blockchain ledger to prevent network bloat and consensus degradation.
2. **On-Chain Cryptographic Proof**: Hyperledger Fabric commits immutable evidence logs including:
   - Unique Record ID & Event ID
   - SHA-256 Hash of footage content & metadata
   - Camera ID, timestamp, and responsible operator
   - Fabric Transaction ID (`tx_id`) and Block Number
3. **Deterministic Verification**: When verifying evidence, the system recalculates the SHA-256 hash of the stored or uploaded comparison file and checks it against the Fabric ledger. Any alteration triggers an immediate **Tampered** alert.

---

## ⚡ Quick Start Checklist

### 1. Prerequisites
* Windows 10/11 with WSL2 (Ubuntu) enabled
* Docker Desktop with WSL2 integration turned on
* Node.js v18+ / v20+, PHP 8.2+, Composer 2.x

### 2. Start Hyperledger Fabric in Ubuntu WSL
```bash
wsl -d Ubuntu -- bash -lc "cd ~/fabric-samples/test-network && ./network.sh up createChannel -ca"
```

### 3. Deploy CCTV Chaincode
```powershell
wsl -d Ubuntu -- bash -lc "cd ~/fabric-samples/test-network && bash /mnt/c/Users/micha/OneDrive/Documents/Sites/cctv-bc/hyperledger/deploy-chaincode.sh"
```

### 4. Start Node.js Fabric Gateway (Windows PowerShell)
```powershell
cd hyperledger\gateway
.\start-gateway.ps1
```
*Health check:* `curl.exe http://127.0.0.1:8787/health`

### 5. Start Laravel Application (Windows PowerShell)
```powershell
composer install
npm install
php artisan migrate:fresh --seed
php artisan cctv:discover-cameras
npm run build
php artisan serve --host=127.0.0.1 --port=8011
```

Access application at: **`http://127.0.0.1:8011`**  
Default Login: `admin@ficobank.com` | Password: `password`

---

## 🛡️ Key Features
* **Evidence Registration**: Upload CCTV MP4 files or capture via controlled sources. Automatic SHA-256 calculation and Hyperledger Fabric commit.
* **Integrity Verification**: 1-click comparison between stored media and blockchain ledger proof.
* **Tamper Detection**: Upload altered or suspect video files to test and prove bit-level alteration detection.
* **Audit Trail & Logging**: Complete activity audit trail tracking logins, evidence access, downloads, and report generation.
* **Camera Management**: Supports mock camera simulation for controlled demos and physical DVR/NVR/ONVIF discovery.
