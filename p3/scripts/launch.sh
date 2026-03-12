#!/bin/bash

set -e

BLUE='\033[0;34m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}=== Step 1: Install ===${RESET}"
bash "$SCRIPT_DIR/install.sh"

echo -e "${BLUE}=== Step 2: Setup ===${RESET}"
bash "$SCRIPT_DIR/setup.sh"

echo -e "${BLUE}=== Step 3: Deploy ===${RESET}"
bash "$SCRIPT_DIR/deploy.sh"
