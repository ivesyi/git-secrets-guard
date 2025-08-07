#!/bin/bash

# Installation script for Git pre-commit hooks
# This script sets up the secret detection hook in your Git repository

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Git Secret Detection Hook Installer ===${NC}"
echo ""

# Function to install hook in a git repository
install_hook() {
    local REPO_PATH=$1
    local HOOK_SCRIPT=$2
    
    if [ ! -d "$REPO_PATH/.git" ]; then
        echo -e "${YELLOW}Initializing Git repository in $REPO_PATH...${NC}"
        cd "$REPO_PATH"
        git init
    fi
    
    # Create hooks directory if it doesn't exist
    mkdir -p "$REPO_PATH/.git/hooks"
    
    # Copy the hook script
    cp "$HOOK_SCRIPT" "$REPO_PATH/.git/hooks/pre-commit"
    
    # Make it executable
    chmod +x "$REPO_PATH/.git/hooks/pre-commit"
    
    echo -e "${GREEN}✅ Pre-commit hook installed in $REPO_PATH${NC}"
}

# Check if check-secrets.sh exists
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOOK_SCRIPT="$SCRIPT_DIR/check-secrets.sh"

if [ ! -f "$HOOK_SCRIPT" ]; then
    echo -e "${RED}❌ Error: check-secrets.sh not found in $SCRIPT_DIR${NC}"
    echo "Please ensure check-secrets.sh is in the same directory as this installer."
    exit 1
fi

# Make the hook script executable
chmod +x "$HOOK_SCRIPT"

# Ask user what to do
echo "How would you like to install the secret detection hook?"
echo ""
echo "1) Install in current directory ($(pwd))"
echo "2) Install in a specific repository"
echo "3) Install globally (for all new repositories)"
echo "4) Show manual installation instructions"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        install_hook "$(pwd)" "$HOOK_SCRIPT"
        ;;
    2)
        read -p "Enter the full path to your Git repository: " REPO_PATH
        if [ -d "$REPO_PATH" ]; then
            install_hook "$REPO_PATH" "$HOOK_SCRIPT"
        else
            echo -e "${RED}❌ Error: Directory $REPO_PATH does not exist${NC}"
            exit 1
        fi
        ;;
    3)
        echo -e "${BLUE}Setting up global Git hooks...${NC}"
        
        # Create global hooks directory
        GLOBAL_HOOKS_DIR="$HOME/.git-templates/hooks"
        mkdir -p "$GLOBAL_HOOKS_DIR"
        
        # Copy hook to global template
        cp "$HOOK_SCRIPT" "$GLOBAL_HOOKS_DIR/pre-commit"
        chmod +x "$GLOBAL_HOOKS_DIR/pre-commit"
        
        # Configure Git to use the template
        git config --global init.templatedir "$HOME/.git-templates"
        
        echo -e "${GREEN}✅ Global Git hooks configured${NC}"
        echo -e "${YELLOW}Note: This will only affect new repositories. For existing repos, run:${NC}"
        echo "  git init"
        echo "in each repository to apply the template."
        ;;
    4)
        echo -e "${BLUE}Manual Installation Instructions:${NC}"
        echo ""
        echo "1. Copy the hook script to your repository:"
        echo "   cp $HOOK_SCRIPT /path/to/your/repo/.git/hooks/pre-commit"
        echo ""
        echo "2. Make it executable:"
        echo "   chmod +x /path/to/your/repo/.git/hooks/pre-commit"
        echo ""
        echo "3. That's it! The hook will run automatically before each commit."
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}=== Additional Configuration ===${NC}"
echo ""
echo "The hook is now installed and will check for:"
echo "  • LLM API keys (OpenAI, Claude, Gemini, etc.)"
echo "  • Cloud service credentials (AWS, Azure, GCP)"
echo "  • Database passwords and connection strings"
echo "  • Private keys and certificates"
echo "  • Personal information (ID numbers, phone numbers)"
echo ""
echo -e "${YELLOW}To test the hook:${NC}"
echo "  1. Create a test file with a fake API key"
echo "  2. Try to commit it"
echo "  3. The hook should block the commit"
echo ""
echo -e "${YELLOW}To bypass the hook (use with caution):${NC}"
echo "  git commit --no-verify"
echo ""
echo -e "${GREEN}Done! Your repository is now protected against accidental secret commits.${NC}"
