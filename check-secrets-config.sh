#!/bin/bash

# Git pre-commit hook with configuration file support
# This script prevents committing secrets, API keys, and personal information
# Enhanced version with YAML configuration and whitelist support

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
ENABLED=true
BLOCK_COMMIT=true
CONFIG_FILE=".gitsecrets.yml"
SHOW_PATTERN=true
MAX_ISSUES_PER_FILE=10

# Whitelist arrays
declare -a WHITELIST_FILES=()
declare -a WHITELIST_PATTERNS=()
declare -a WHITELIST_STRINGS=()
declare -a WHITELIST_EXTENSIONS=()
declare -a WHITELIST_DIRECTORIES=()

# Custom patterns and keywords
declare -a CUSTOM_PATTERNS=()
declare -a CUSTOM_KEYWORDS=()

# Function to parse YAML configuration file
parse_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        # No config file, use defaults
        return 0
    fi
    
    echo -e "${BLUE}📋 Loading configuration from $CONFIG_FILE${NC}"
    
    # Parse enabled status
    if grep -q "^enabled: false" "$CONFIG_FILE" 2>/dev/null; then
        ENABLED=false
    fi
    
    # Parse block_commit setting
    if grep -q "block_commit: false" "$CONFIG_FILE" 2>/dev/null; then
        BLOCK_COMMIT=false
    fi
    
    # Parse show_pattern setting
    if grep -q "show_pattern: false" "$CONFIG_FILE" 2>/dev/null; then
        SHOW_PATTERN=false
    fi
    
    # Parse max_issues_per_file
    local max_issues=$(grep "max_issues_per_file:" "$CONFIG_FILE" 2>/dev/null | sed 's/.*: *//')
    if [ ! -z "$max_issues" ]; then
        MAX_ISSUES_PER_FILE=$max_issues
    fi
    
    # Parse whitelist files (simple parser)
    local in_files_section=false
    local in_patterns_section=false
    local in_strings_section=false
    local in_extensions_section=false
    local in_directories_section=false
    local in_custom_patterns=false
    local in_custom_keywords=false
    
    while IFS= read -r line; do
        # Remove leading/trailing whitespace
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Skip comments and empty lines
        if [[ "$line" =~ ^# ]] || [ -z "$line" ]; then
            continue
        fi
        
        # Check section headers
        if [[ "$line" == "files:" ]]; then
            in_files_section=true
            in_patterns_section=false
            in_strings_section=false
            in_extensions_section=false
            in_directories_section=false
            in_custom_patterns=false
            in_custom_keywords=false
        elif [[ "$line" == "patterns:" ]] && [[ "$prev_line" == *"whitelist"* ]]; then
            in_files_section=false
            in_patterns_section=true
            in_strings_section=false
            in_extensions_section=false
            in_directories_section=false
            in_custom_patterns=false
            in_custom_keywords=false
        elif [[ "$line" == "strings:" ]]; then
            in_files_section=false
            in_patterns_section=false
            in_strings_section=true
            in_extensions_section=false
            in_directories_section=false
            in_custom_patterns=false
            in_custom_keywords=false
        elif [[ "$line" == "extensions:" ]]; then
            in_files_section=false
            in_patterns_section=false
            in_strings_section=false
            in_extensions_section=true
            in_directories_section=false
            in_custom_patterns=false
            in_custom_keywords=false
        elif [[ "$line" == "directories:" ]]; then
            in_files_section=false
            in_patterns_section=false
            in_strings_section=false
            in_extensions_section=false
            in_directories_section=true
            in_custom_patterns=false
            in_custom_keywords=false
        elif [[ "$line" == "custom_patterns:" ]]; then
            in_files_section=false
            in_patterns_section=false
            in_strings_section=false
            in_extensions_section=false
            in_directories_section=false
            in_custom_patterns=true
            in_custom_keywords=false
        elif [[ "$line" == "custom_keywords:" ]]; then
            in_files_section=false
            in_patterns_section=false
            in_strings_section=false
            in_extensions_section=false
            in_directories_section=false
            in_custom_patterns=false
            in_custom_keywords=true
        elif [[ ! "$line" =~ ^[[:space:]]*- ]]; then
            # Not a list item, reset all sections
            in_files_section=false
            in_patterns_section=false
            in_strings_section=false
            in_extensions_section=false
            in_directories_section=false
            in_custom_patterns=false
            in_custom_keywords=false
        fi
        
        # Parse list items
        if [[ "$line" =~ ^-[[:space:]]+(.*) ]]; then
            local item="${BASH_REMATCH[1]}"
            # Remove quotes if present
            item=$(echo "$item" | sed 's/^["'"'"']//;s/["'"'"']$//')
            
            if [ "$in_files_section" = true ]; then
                WHITELIST_FILES+=("$item")
            elif [ "$in_patterns_section" = true ]; then
                WHITELIST_PATTERNS+=("$item")
            elif [ "$in_strings_section" = true ]; then
                WHITELIST_STRINGS+=("$item")
            elif [ "$in_extensions_section" = true ]; then
                WHITELIST_EXTENSIONS+=("$item")
            elif [ "$in_directories_section" = true ]; then
                WHITELIST_DIRECTORIES+=("$item")
            elif [ "$in_custom_keywords" = true ]; then
                CUSTOM_KEYWORDS+=("$item")
            fi
        fi
        
        # Parse custom patterns (more complex structure)
        if [ "$in_custom_patterns" = true ] && [[ "$line" =~ pattern:[[:space:]]*(.*) ]]; then
            local pattern="${BASH_REMATCH[1]}"
            pattern=$(echo "$pattern" | sed 's/^["'"'"']//;s/["'"'"']$//')
            CUSTOM_PATTERNS+=("$pattern")
        fi
        
        prev_line="$line"
    done < "$CONFIG_FILE"
    
    # Debug: Show loaded configuration
    if [ ${#WHITELIST_FILES[@]} -gt 0 ]; then
        echo -e "${BLUE}  • Whitelisted files: ${#WHITELIST_FILES[@]}${NC}"
    fi
    if [ ${#WHITELIST_PATTERNS[@]} -gt 0 ]; then
        echo -e "${BLUE}  • Whitelisted patterns: ${#WHITELIST_PATTERNS[@]}${NC}"
    fi
    if [ ${#CUSTOM_PATTERNS[@]} -gt 0 ]; then
        echo -e "${BLUE}  • Custom patterns: ${#CUSTOM_PATTERNS[@]}${NC}"
    fi
    if [ ${#CUSTOM_KEYWORDS[@]} -gt 0 ]; then
        echo -e "${BLUE}  • Custom keywords: ${#CUSTOM_KEYWORDS[@]}${NC}"
    fi
}

# Function to check if a file is whitelisted
is_whitelisted_file() {
    local file=$1
    local basename=$(basename "$file")
    local dirname=$(dirname "$file")
    
    # Check whitelisted files
    for wf in "${WHITELIST_FILES[@]}"; do
        if [[ "$file" == $wf ]] || [[ "$file" == *"$wf" ]]; then
            return 0
        fi
    done
    
    # Check whitelisted extensions
    for ext in "${WHITELIST_EXTENSIONS[@]}"; do
        if [[ "$basename" == *"$ext" ]]; then
            return 0
        fi
    done
    
    # Check whitelisted directories
    for dir in "${WHITELIST_DIRECTORIES[@]}"; do
        if [[ "$dirname" == *"$dir"* ]]; then
            return 0
        fi
    done
    
    return 1
}

# Function to check if a string is whitelisted
is_whitelisted_string() {
    local content=$1
    
    # Check exact string matches
    for ws in "${WHITELIST_STRINGS[@]}"; do
        if [[ "$content" == *"$ws"* ]]; then
            return 0
        fi
    done
    
    # Check pattern matches
    for wp in "${WHITELIST_PATTERNS[@]}"; do
        if echo "$content" | grep -qE "$wp" 2>/dev/null; then
            return 0
        fi
    done
    
    return 1
}

# Load configuration
parse_config

# Check if hook is enabled
if [ "$ENABLED" = false ]; then
    echo -e "${YELLOW}⚠️  Git Secrets Guard is disabled in configuration${NC}"
    exit 0
fi

echo "🔍 Checking for sensitive information..."

# Flag to track if sensitive data is found
FOUND_SENSITIVE=0

# Get list of staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
    echo "No staged files to check."
    exit 0
fi

# Include original patterns (simplified for this example)
declare -a PATTERNS=(
    "sk-[a-zA-Z0-9]{20,}"
    "sk-proj-[a-zA-Z0-9]{20,}"
    "sk-ant-[a-zA-Z0-9]{40,}"
    "AIza[0-9A-Za-z\\-_]{35}"
    "AKIA[0-9A-Z]{16}"
    "ghp_[0-9a-zA-Z]{36}"
    "mongodb\\+srv://[^\\s]+"
    "postgres://[^\\s]+"
    "password\\s*=\\s*[\"'][^\"']{8,}[\"']"
)

# Add custom patterns
for cp in "${CUSTOM_PATTERNS[@]}"; do
    PATTERNS+=("$cp")
done

# Original keywords plus custom ones
declare -a KEYWORDS=(
    "OPENAI_API_KEY"
    "ANTHROPIC_API_KEY"
    "api_key"
    "api_secret"
    "password"
    "BEGIN PRIVATE KEY"
)

# Add custom keywords
for ck in "${CUSTOM_KEYWORDS[@]}"; do
    KEYWORDS+=("$ck")
done

# Check each staged file
for FILE in $STAGED_FILES; do
    # Check if file is whitelisted
    if is_whitelisted_file "$FILE"; then
        echo -e "  Skipping (whitelisted): $FILE"
        continue
    fi
    
    # Skip binary files
    if file --mime-type "$FILE" | grep -q "text/"; then
        echo "  Checking: $FILE"
        
        # Get the staged content
        STAGED_CONTENT=$(git show ":$FILE" 2>/dev/null)
        
        # Skip if content is whitelisted
        if is_whitelisted_string "$STAGED_CONTENT"; then
            echo -e "  ${YELLOW}  Content contains whitelisted patterns${NC}"
            continue
        fi
        
        # Track findings
        FILE_ISSUES=0
        
        # Check for patterns
        for PATTERN in "${PATTERNS[@]}"; do
            if echo "$STAGED_CONTENT" | grep -qE "$PATTERN" 2>/dev/null; then
                if [ $FILE_ISSUES -lt $MAX_ISSUES_PER_FILE ]; then
                    echo -e "${RED}   ⚠️  Potential sensitive data detected!${NC}"
                    if [ "$SHOW_PATTERN" = true ]; then
                        echo -e "${YELLOW}     • Pattern: ${PATTERN:0:50}${NC}"
                    fi
                    FILE_ISSUES=$((FILE_ISSUES + 1))
                    FOUND_SENSITIVE=1
                fi
            fi
        done
        
        # Check for keywords
        for KEYWORD in "${KEYWORDS[@]}"; do
            if echo "$STAGED_CONTENT" | grep -qi "$KEYWORD" 2>/dev/null; then
                if [ $FILE_ISSUES -lt $MAX_ISSUES_PER_FILE ]; then
                    echo -e "${RED}   ⚠️  Sensitive keyword found: $KEYWORD${NC}"
                    FILE_ISSUES=$((FILE_ISSUES + 1))
                    FOUND_SENSITIVE=1
                fi
            fi
        done
        
        if [ $FILE_ISSUES -ge $MAX_ISSUES_PER_FILE ]; then
            echo -e "${YELLOW}   ... and more issues (limit: $MAX_ISSUES_PER_FILE)${NC}"
        fi
    fi
done

# Final result
if [ $FOUND_SENSITIVE -eq 1 ]; then
    echo ""
    if [ "$BLOCK_COMMIT" = true ]; then
        echo -e "${RED}❌ Commit blocked: Potential sensitive information detected!${NC}"
        echo ""
        echo "Options:"
        echo "  1. Remove the sensitive information from your files"
        echo "  2. Add files/patterns to whitelist in .gitsecrets.yml"
        echo "  3. Use environment variables for secrets"
        echo "  4. If this is a false positive, bypass with: git commit --no-verify"
        echo ""
        exit 1
    else
        echo -e "${YELLOW}⚠️  Warning: Potential sensitive information detected!${NC}"
        echo "Commit is allowed (block_commit: false in config)"
        exit 0
    fi
else
    echo -e "${GREEN}✅ No sensitive information detected${NC}"
    exit 0
fi
