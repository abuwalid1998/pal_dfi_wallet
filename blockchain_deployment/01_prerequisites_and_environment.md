# 01 - Prerequisites & Environment Setup

This document specifies the software requirements and installation procedures for deploying the Hyperledger Fabric 2.5 blockchain network for PAL-DFI.

---

## 1. Operating System & Hardware Requirements

- **Supported OS**: Ubuntu 22.04 LTS / 24.04 LTS, Debian 12, or Windows 11 with WSL2 (Ubuntu 22.04).
- **CPU**: 4 vCPUs minimum (8 vCPUs recommended for production consortium).
- **RAM**: 8 GB RAM minimum (16 GB recommended).
- **Disk Storage**: 50 GB free NVMe/SSD storage.

---

## 2. Software Dependencies

### A. Git & cURL
```bash
sudo apt-get update
sudo apt-get install -y git curl jq build-essential
```

### B. Docker Engine & Docker Compose v2
Hyperledger Fabric nodes run as containerized microservices.
```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Allow current user to run Docker without sudo:
sudo usermod -aG docker $USER
newgrp docker
```

### C. Go Programming Language (v1.22+)
Required for compiling and executing chaincode.
```bash
wget https://go.dev/dl/go1.22.5.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
source ~/.bashrc
go version
```

### D. Node.js & npm (v18+ LTS)
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
node --version
npm --version
```

---

## 3. Hyperledger Fabric 2.5 Binaries & Docker Images

Download the official Fabric 2.5.9 LTS binaries and Docker images:
```bash
mkdir -p ~/paldfi-fabric && cd ~/paldfi-fabric
curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh
chmod +x install-fabric.sh

# Download Fabric 2.5.9 and Fabric CA 1.5.10
./install-fabric.sh --fabric-version 2.5.9 --ca-version 1.5.10 binary docker

# Add binaries to system PATH:
echo 'export PATH=$PATH:$HOME/paldfi-fabric/bin' >> ~/.bashrc
source ~/.bashrc

# Verify binary availability:
peer version
orderer version
fabric-ca-client version
```
