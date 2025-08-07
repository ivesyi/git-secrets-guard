#!/bin/bash

# Git pre-commit hook to check for sensitive information
# This script prevents committing secrets, API keys, and personal information
# Enhanced with LLM API key patterns

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Flag to track if sensitive data is found
FOUND_SENSITIVE=0

echo "🔍 Checking for sensitive information..."

# Get list of staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
    echo "No staged files to check."
    exit 0
fi

# Define patterns for sensitive information
declare -a PATTERNS=(
    # ========== LLM API Keys ==========
    # OpenAI
    "sk-[a-zA-Z0-9]{20,}"
    "sk-proj-[a-zA-Z0-9]{20,}"
    "sess-[a-zA-Z0-9]{40,}"
    "openai[_-]?api[_-]?key"
    
    # Anthropic Claude
    "sk-ant-[a-zA-Z0-9]{40,}"
    "sk-ant-api[0-9]{2}-[a-zA-Z0-9-]{40,}"
    "anthropic[_-]?api[_-]?key"
    "claude[_-]?api[_-]?key"
    
    # Google (Gemini, PaLM, Vertex AI)
    "AIza[0-9A-Za-z\\-_]{35}"
    "ya29\\.[a-zA-Z0-9_-]{100,}"
    "gemini[_-]?api[_-]?key"
    "palm[_-]?api[_-]?key"
    "vertex[_-]?api[_-]?key"
    
    # Azure OpenAI
    "[a-z0-9]{32}"  # Azure API keys are 32 character hex strings
    "azure[_-]?openai[_-]?key"
    "azure[_-]?api[_-]?key"
    "cognitive[_-]?services[_-]?key"
    
    # Hugging Face
    "hf_[a-zA-Z0-9]{30,}"
    "api_[a-zA-Z0-9]{30,}"
    "huggingface[_-]?token"
    "hugging[_-]?face[_-]?api[_-]?key"
    
    # Cohere
    "[a-zA-Z0-9]{40}"  # Cohere keys are typically 40 chars
    "cohere[_-]?api[_-]?key"
    
    # Replicate
    "r8_[a-zA-Z0-9]{40}"
    "replicate[_-]?api[_-]?token"
    
    # Stability AI
    "sk-[a-zA-Z0-9]{48,}"
    "stability[_-]?api[_-]?key"
    "dreamstudio[_-]?api[_-]?key"
    
    # Midjourney (unofficial APIs)
    "mj[_-]?[a-zA-Z0-9]{32,}"
    "midjourney[_-]?token"
    
    # DeepMind
    "deepmind[_-]?api[_-]?key"
    "gopher[_-]?api[_-]?key"
    
    # AI21 Labs
    "[a-zA-Z0-9]{32}"
    "ai21[_-]?api[_-]?key"
    
    # Mistral AI
    "[a-zA-Z0-9]{32}"
    "mistral[_-]?api[_-]?key"
    
    # Perplexity
    "pplx-[a-zA-Z0-9]{48,}"
    "perplexity[_-]?api[_-]?key"
    
    # Together AI
    "[a-f0-9]{64}"
    "together[_-]?api[_-]?key"
    
    # Groq
    "gsk_[a-zA-Z0-9]{50,}"
    "groq[_-]?api[_-]?key"
    
    # Fireworks AI
    "fw_[a-zA-Z0-9]{40,}"
    "fireworks[_-]?api[_-]?key"
    
    # Anyscale
    "esecret_[a-zA-Z0-9]{40,}"
    "anyscale[_-]?api[_-]?key"
    
    # ========== Chinese LLM Providers ==========
    # 百度文心一言 (ERNIE)
    "[a-zA-Z0-9]{32}"
    "qianfan[_-]?api[_-]?key"
    "wenxin[_-]?api[_-]?key"
    "ernie[_-]?api[_-]?key"
    
    # 阿里通义千问
    "sk-[a-zA-Z0-9]{20,}"
    "dashscope[_-]?api[_-]?key"
    "qwen[_-]?api[_-]?key"
    "tongyi[_-]?api[_-]?key"
    
    # 讯飞星火
    "[a-f0-9]{32}"
    "spark[_-]?api[_-]?key"
    "xfyun[_-]?api[_-]?key"
    "iflytek[_-]?api[_-]?key"
    
    # 智谱AI (GLM)
    "[a-zA-Z0-9\\.]{30,}"
    "zhipu[_-]?api[_-]?key"
    "glm[_-]?api[_-]?key"
    "chatglm[_-]?api[_-]?key"
    
    # MiniMax
    "eyJ[a-zA-Z0-9_-]+\\.[a-zA-Z0-9_-]+\\.[a-zA-Z0-9_-]+"
    "minimax[_-]?api[_-]?key"
    
    # 月之暗面 (Moonshot/Kimi)
    "sk-[a-zA-Z0-9]{48,}"
    "moonshot[_-]?api[_-]?key"
    "kimi[_-]?api[_-]?key"
    
    # ========== Other Common API Keys ==========
    # Generic API patterns
    "api[_-]?key"
    "apikey"
    "api[_-]?secret"
    "access[_-]?token"
    "auth[_-]?token"
    "authentication[_-]?token"
    "private[_-]?key"
    "secret[_-]?key"
    "bearer[_-]?token"
    
    # AWS
    "AKIA[0-9A-Z]{16}"
    "aws[_-]?access[_-]?key[_-]?id"
    "aws[_-]?secret[_-]?access[_-]?key"
    
    # GitHub
    "ghp_[0-9a-zA-Z]{36}"
    "gho_[0-9a-zA-Z]{36}"
    "ghu_[0-9a-zA-Z]{36}"
    "ghs_[0-9a-zA-Z]{36}"
    "ghr_[0-9a-zA-Z]{36}"
    
    # Slack
    "xox[baprs]-[0-9]{10,13}-[0-9]{10,13}-[a-zA-Z0-9]{24,32}"
    
    # Discord
    "[MN][a-zA-Z0-9]{23}\\.[a-zA-Z0-9]{6}\\.[a-zA-Z0-9]{27}"
    
    # Telegram
    "[0-9]{9,10}:[a-zA-Z0-9_-]{35}"
    
    # Stripe
    "sk_live_[a-zA-Z0-9]{24,}"
    "pk_live_[a-zA-Z0-9]{24,}"
    "sk_test_[a-zA-Z0-9]{24,}"
    "pk_test_[a-zA-Z0-9]{24,}"
    
    # SendGrid
    "SG\\.[a-zA-Z0-9]{22}\\.[a-zA-Z0-9]{43}"
    
    # Twilio
    "SK[a-z0-9]{32}"
    "AC[a-z0-9]{32}"
    
    # Generic Secrets in code
    "password\\s*=\\s*[\"'][^\"']{8,}[\"']"
    "passwd\\s*=\\s*[\"'][^\"']{8,}[\"']"
    "pwd\\s*=\\s*[\"'][^\"']{8,}[\"']"
    "secret\\s*=\\s*[\"'][^\"']{8,}[\"']"
    "token\\s*=\\s*[\"'][^\"']{8,}[\"']"
    
    # Database URLs
    "mongodb\\+srv://[^\\s]+"
    "postgres://[^\\s]+"
    "postgresql://[^\\s]+"
    "mysql://[^\\s]+"
    "redis://[^\\s]+"
    "amqp://[^\\s]+"
    
    # Private Keys
    "-----BEGIN (RSA|DSA|EC|OPENSSH) PRIVATE KEY-----"
    "-----BEGIN PGP PRIVATE KEY BLOCK-----"
    "-----BEGIN CERTIFICATE-----"
    
    # JWT tokens
    "eyJ[a-zA-Z0-9_-]+\\.[a-zA-Z0-9_-]+\\.[a-zA-Z0-9_-]+"
    
    # Chinese Personal Information
    # 身份证
    "[^0-9]([1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\\d|3[01])\\d{3}[\\dXx])[^0-9]"
    # 手机号
    "[^0-9](1[3-9]\\d{9})[^0-9]"
    # 银行卡号
    "[^0-9]([1-9]\\d{15,18})[^0-9]"
)

# Additional keywords to check (case-insensitive)
declare -a KEYWORDS=(
    # LLM related
    "OPENAI_API_KEY"
    "ANTHROPIC_API_KEY"
    "CLAUDE_API_KEY"
    "GEMINI_API_KEY"
    "PALM_API_KEY"
    "AZURE_OPENAI_KEY"
    "AZURE_OPENAI_API_KEY"
    "HUGGINGFACE_TOKEN"
    "HF_TOKEN"
    "COHERE_API_KEY"
    "REPLICATE_API_TOKEN"
    "STABILITY_API_KEY"
    "MISTRAL_API_KEY"
    "PERPLEXITY_API_KEY"
    "GROQ_API_KEY"
    "TOGETHER_API_KEY"
    "FIREWORKS_API_KEY"
    "ANYSCALE_API_KEY"
    "DASHSCOPE_API_KEY"
    "QIANFAN_API_KEY"
    "ZHIPU_API_KEY"
    "MOONSHOT_API_KEY"
    "KIMI_API_KEY"
    
    # Private keys
    "BEGIN PRIVATE KEY"
    "BEGIN RSA PRIVATE KEY"
    "BEGIN DSA PRIVATE KEY"
    "BEGIN EC PRIVATE KEY"
    "BEGIN OPENSSH PRIVATE KEY"
    "BEGIN PGP PRIVATE KEY"
    "BEGIN CERTIFICATE"
    
    # Generic secrets
    "client_secret"
    "api_key"
    "api_secret"
    "access_token"
    "refresh_token"
    "private_key"
    "consumer_key"
    "consumer_secret"
    "bearer_token"
    "oauth_token"
    "db_password"
    "database_password"
    "db_pass"
    "mongodb_uri"
    "postgres_password"
    "mysql_password"
    "redis_password"
)

# Check each staged file
for FILE in $STAGED_FILES; do
    # Skip binary files
    if file --mime-type "$FILE" | grep -q "text/"; then
        echo "  Checking: $FILE"
        
        # Get the staged content (not the working directory content)
        STAGED_CONTENT=$(git show ":$FILE" 2>/dev/null)
        
        # Check for patterns using grep
        for PATTERN in "${PATTERNS[@]}"; do
            if echo "$STAGED_CONTENT" | grep -qE "$PATTERN"; then
                echo -e "${RED}⚠️  Potential sensitive data found in $FILE${NC}"
                echo -e "${YELLOW}   Pattern matched: $PATTERN${NC}"
                FOUND_SENSITIVE=1
            fi
        done
        
        # Check for keywords (case-insensitive)
        for KEYWORD in "${KEYWORDS[@]}"; do
            if echo "$STAGED_CONTENT" | grep -qi "$KEYWORD"; then
                echo -e "${RED}⚠️  Potential sensitive keyword found in $FILE${NC}"
                echo -e "${YELLOW}   Keyword found: $KEYWORD${NC}"
                FOUND_SENSITIVE=1
            fi
        done
        
        # Special check for .env variables
        if echo "$STAGED_CONTENT" | grep -qE "^[A-Z_]+=['\"]?[a-zA-Z0-9_\-]{20,}['\"]?$"; then
            echo -e "${YELLOW}⚠️  Potential environment variable with secret in $FILE${NC}"
            # This is a warning, you might want to make it blocking
        fi
        
        # Check for high-entropy strings (potential secrets)
        if echo "$STAGED_CONTENT" | grep -qE "[a-zA-Z0-9+/=]{40,}" | head -20; then
            ENTROPY_MATCHES=$(echo "$STAGED_CONTENT" | grep -oE "[a-zA-Z0-9+/=]{40,}" | head -5)
            if [ ! -z "$ENTROPY_MATCHES" ]; then
                echo -e "${YELLOW}⚠️  High-entropy strings found in $FILE (possible secrets):${NC}"
                echo "$ENTROPY_MATCHES" | head -3 | while read -r line; do
                    # Skip common false positives (like base64 encoded images in markdown)
                    if [[ ! "$line" =~ ^[A-Za-z0-9+/]*=*$ ]] || [[ ${#line} -lt 100 ]]; then
                        echo "   ${line:0:20}..."
                    fi
                done
            fi
        fi
    fi
done

# Check for common sensitive file names
declare -a SENSITIVE_FILES=(
    ".env"
    ".env.local"
    ".env.development"
    ".env.production"
    ".env.staging"
    ".env.test"
    "config.json"
    "config.yaml"
    "config.yml"
    "secrets.json"
    "secrets.yaml"
    "secrets.yml"
    "credentials.json"
    "credentials.yaml"
    "credentials.yml"
    "id_rsa"
    "id_dsa"
    "id_ecdsa"
    "id_ed25519"
    "*.pem"
    "*.key"
    "*.p12"
    "*.pfx"
    "*.cer"
    "*.crt"
    "*.jks"
    "*.keystore"
    "service-account*.json"
    "serviceaccount*.json"
    "firebase*.json"
    "google-services.json"
    "GoogleService-Info.plist"
)

for FILE in $STAGED_FILES; do
    BASENAME=$(basename "$FILE")
    for SENSITIVE_FILE in "${SENSITIVE_FILES[@]}"; do
        if [[ "$BASENAME" == $SENSITIVE_FILE ]] || [[ "$BASENAME" == *"$SENSITIVE_FILE" ]]; then
            echo -e "${RED}⚠️  Sensitive file detected: $FILE${NC}"
            echo -e "${YELLOW}   Consider adding this file to .gitignore${NC}"
            FOUND_SENSITIVE=1
        fi
    done
done

# Final result
if [ $FOUND_SENSITIVE -eq 1 ]; then
    echo ""
    echo -e "${RED}❌ Commit blocked: Potential sensitive information detected!${NC}"
    echo ""
    echo "Options:"
    echo "  1. Remove the sensitive information from your files"
    echo "  2. Add sensitive files to .gitignore"
    echo "  3. Use environment variables for secrets (e.g., process.env.OPENAI_API_KEY)"
    echo "  4. Use a secrets management tool (e.g., dotenv, AWS Secrets Manager)"
    echo "  5. If this is a false positive, you can bypass with: git commit --no-verify"
    echo ""
    echo "Best practices:"
    echo "  • Never hardcode API keys in your source code"
    echo "  • Use .env files for local development (and add .env to .gitignore)"
    echo "  • Use environment variables in production"
    echo "  • Rotate any keys that may have been exposed"
    echo ""
    exit 1
else
    echo -e "${GREEN}✅ No sensitive information detected${NC}"
    exit 0
fi
