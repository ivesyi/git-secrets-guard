#!/bin/bash

# One-line installer for git-secrets-guard
# Usage: 
#   curl -sSL https://raw.githubusercontent.com/ivesyi/git-secrets-guard/main/install.sh | bash
#   wget -qO- https://raw.githubusercontent.com/ivesyi/git-secrets-guard/main/install.sh | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
REPO_URL="https://github.com/ivesyi/git-secrets-guard"
REPO_RAW_URL="https://raw.githubusercontent.com/ivesyi/git-secrets-guard/main"
INSTALL_DIR="$HOME/.git-secrets-guard"
GLOBAL_HOOKS_DIR="$HOME/.git-templates/hooks"

# Functions
print_banner() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                ║${NC}"
    echo -e "${CYAN}║     ${BOLD}🔐 Git Secrets Guard Installer${NC}${CYAN}            ║${NC}"
    echo -e "${CYAN}║                                                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_dependencies() {
    local missing_deps=()
    
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        missing_deps+=("curl or wget")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo "Please install the missing dependencies and try again."
        exit 1
    fi
}

download_file() {
    local url=$1
    local output=$2
    
    if command -v curl &> /dev/null; then
        curl -sSL "$url" -o "$output"
    elif command -v wget &> /dev/null; then
        wget -q "$url" -O "$output"
    else
        print_error "Neither curl nor wget is available"
        return 1
    fi
}

install_for_current_repo() {
    if [ ! -d .git ]; then
        print_warning "Current directory is not a Git repository"
        read -p "Initialize a Git repository here? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git init
            print_success "Git repository initialized"
        else
            print_info "Skipping current repository installation"
            return
        fi
    fi
    
    # Install hook in current repository
    cp "$INSTALL_DIR/check-secrets.sh" .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    print_success "Hook installed in current repository"
}

install_globally() {
    # Create global hooks directory
    mkdir -p "$GLOBAL_HOOKS_DIR"
    
    # Copy hook to global template
    cp "$INSTALL_DIR/check-secrets.sh" "$GLOBAL_HOOKS_DIR/pre-commit"
    chmod +x "$GLOBAL_HOOKS_DIR/pre-commit"
    
    # Configure Git to use the template
    git config --global init.templatedir "$HOME/.git-templates"
    
    print_success "Global Git hooks configured"
    print_info "New repositories will automatically have the hook installed"
    print_info "For existing repositories, run 'git init' to apply the template"
}

main() {
    print_banner
    
    echo -e "${BOLD}Protecting your code from accidental secret commits${NC}"
    echo ""
    
    # Check dependencies
    print_info "Checking dependencies..."
    check_dependencies
    print_success "All dependencies satisfied"
    echo ""
    
    # Create installation directory
    print_info "Creating installation directory..."
    mkdir -p "$INSTALL_DIR"
    print_success "Installation directory ready: $INSTALL_DIR"
    echo ""
    
    # Download the hook script
    print_info "Downloading git-secrets-guard..."
    download_file "$REPO_RAW_URL/check-secrets.sh" "$INSTALL_DIR/check-secrets.sh"
    chmod +x "$INSTALL_DIR/check-secrets.sh"
    print_success "Hook script downloaded"
    
    # Download additional files
    download_file "$REPO_RAW_URL/README.md" "$INSTALL_DIR/README.md" 2>/dev/null || true
    download_file "$REPO_RAW_URL/LICENSE" "$INSTALL_DIR/LICENSE" 2>/dev/null || true
    echo ""
    
    # Ask user for installation preference
    echo -e "${BOLD}Choose installation option:${NC}"
    echo "  1) Install for current repository only"
    echo "  2) Install globally (all new repositories)"
    echo "  3) Both"
    echo "  4) Skip installation (manual setup)"
    echo ""
    
    read -p "Enter your choice (1-4): " choice
    echo ""
    
    case $choice in
        1)
            install_for_current_repo
            ;;
        2)
            install_globally
            ;;
        3)
            install_for_current_repo
            install_globally
            ;;
        4)
            print_info "Manual installation chosen"
            echo ""
            echo "To manually install in a repository:"
            echo "  cp $INSTALL_DIR/check-secrets.sh /path/to/repo/.git/hooks/pre-commit"
            echo "  chmod +x /path/to/repo/.git/hooks/pre-commit"
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}    Installation Complete! 🎉${NC}"
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${BOLD}What's protected:${NC}"
    echo "  • LLM API keys (OpenAI, Claude, Gemini, etc.)"
    echo "  • Cloud credentials (AWS, Azure, GCP)"
    echo "  • Database passwords & connection strings"
    echo "  • SSH keys & certificates"
    echo "  • Personal information"
    echo ""
    
    echo -e "${BOLD}Quick test:${NC}"
    echo "  echo 'OPENAI_API_KEY=\"sk-test123\"' > test.txt"
    echo "  git add test.txt && git commit -m \"test\""
    echo "  # Should be blocked!"
    echo ""
    
    echo -e "${BOLD}Bypass (use carefully):${NC}"
    echo "  git commit --no-verify"
    echo ""
    
    echo -e "${BOLD}More information:${NC}"
    echo "  Documentation: $INSTALL_DIR/README.md"
    echo "  Repository: $REPO_URL"
    echo ""
    
    print_success "Your repositories are now protected! 🔐"
}

# Handle errors
trap 'print_error "Installation failed. Please check the error messages above."' ERR

# Run main function
main "$@"
