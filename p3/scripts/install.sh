#!/bin/bash

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
ORANGE='\033[38;5;208m'
RESET='\033[0m'

echo -e "${BLUE}=== Installing dependencies... ===${RESET}"

# Docker

if ! command -v docker &>/dev/null; then
    echo -e "${ORANGE}Starting Docker installation...${RESET}"

    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl gnupg lsb-release

    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    sudo systemctl enable docker
    sudo systemctl start docker

    echo -e "${GREEN}Docker installed: $(docker --version)${RESET}"
else
    echo -e "${GREEN}Docker already installed: $(docker --version)${RESET}"
fi

# Kube
echo -e "${ORANGE}Starting kubectl installation...${RESET}"

KUBECTL_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)

curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    -o /tmp/kubectl
sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
rm /tmp/kubectl

echo -e "${GREEN}kubectl installed: $(kubectl version --client)${RESET}"

# K3D
echo -e "${ORANGE}Starting K3d installation...${RESET}"

curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo -e "${GREEN}K3d installed: $(k3d version | head -1)${RESET}"

# ARGOCD

echo -e "${ORANGE}Starting ArgoCD CLI installation...${RESET}"

ARGOCD_VERSION=$(curl -fsSL https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)

curl -fsSL "https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-amd64" \
    -o /tmp/argocd
sudo install -m 0755 /tmp/argocd /usr/local/bin/argocd
rm /tmp/argocd

echo -e "${GREEN}ArgoCD CLI installed: $(argocd version --client)${RESET}"

echo -e "${BLUE}=== Installations completed ===${RESET}"

# add user at the end to prevent crash
sudo usermod -aG docker "$USER"
