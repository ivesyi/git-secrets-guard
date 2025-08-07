#!/bin/bash

# Quick start script for git-secrets-guard
# This script helps you quickly protect your Git repositories

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Git Secrets Guard - Quick Start    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Show ASCII art logo
cat << "EOF"
    🔐 Git Secrets Guard
    Protecting your secrets, one commit at a time
EOF

echo ""
echo -e "${GREEN}This tool will help you prevent accidentally committing:${NC}"
echo "  ✓ API Keys (OpenAI, Claude, Google, Azure, etc.)"
echo "  ✓ Database passwords"
echo "  ✓ Private keys and certificates"
echo "  ✓ Personal information"
echo ""

# Run the installer
./install-git-hooks.sh
