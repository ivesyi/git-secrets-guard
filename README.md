# Git Secrets Guard 🔐

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/ivesyi/git-secrets-guard/pulls)

**[English](README.md)** | [简体中文](README.zh-CN.md)

*Prevent secrets, API keys, and sensitive data from being committed to your Git repositories*

</div>

## ✨ Features

### Detects LLM API Keys
- **OpenAI**: `sk-xxx`, `sk-proj-xxx`
- **Anthropic Claude**: `sk-ant-xxx` 
- **Google (Gemini/PaLM)**: `AIzaxxx`
- **Azure OpenAI**: Azure key formats
- **Hugging Face**: `hf_xxx`
- **Chinese LLM Providers**:
  - Baidu Wenxin (ERNIE)
  - Alibaba Tongyi Qianwen
  - iFlytek Spark
  - Zhipu AI (GLM)
  - Moonshot/Kimi
  - MiniMax

### Also Detects
- AWS, GitHub, Slack service keys
- Database connection strings and passwords
- SSH private keys and certificates
- JWT tokens
- Personal information (ID numbers, phone numbers, credit cards)
- High-entropy strings (potential secrets)

## 🚀 Quick Install

### Method 1: One-Line Install (Simplest) 🎯

Using curl:
```bash
curl -sSL https://raw.githubusercontent.com/ivesyi/git-secrets-guard/main/install.sh | bash
```

Using wget:
```bash
wget -qO- https://raw.githubusercontent.com/ivesyi/git-secrets-guard/main/install.sh | bash
```

This will automatically download and configure git-secrets-guard. You can choose to:
- Install for current repository
- Install globally (all new repositories automatically protected)
- Install both

### Method 2: Local Installation Script

```bash
# Clone the repository
git clone https://github.com/ivesyi/git-secrets-guard.git
cd git-secrets-guard

# Make script executable
chmod +x install-git-hooks.sh

# Run installation script
./install-git-hooks.sh
```

The installation script provides the following options:
1. Install in current directory
2. Install in specific repository
3. Global installation (affects all new repositories)
4. Show manual installation instructions

### Method 3: Manual Installation

```bash
# 1. Initialize Git repository (if not already)
git init

# 2. Copy hook script to .git/hooks directory
cp check-secrets.sh .git/hooks/pre-commit

# 3. Make it executable
chmod +x .git/hooks/pre-commit
```

### Method 4: Global Configuration

```bash
# 1. Create global Git hooks directory
mkdir -p ~/.git-templates/hooks

# 2. Copy hook to template directory
cp check-secrets.sh ~/.git-templates/hooks/pre-commit
chmod +x ~/.git-templates/hooks/pre-commit

# 3. Configure Git to use template
git config --global init.templatedir ~/.git-templates

# 4. For existing repositories, run git init to apply template
cd /path/to/existing/repo
git init
```

## 🖥️ Demo

### When API Key is Detected:
![API Key Detection](images/demo-api-key-detection.png)

### When Database URL is Detected:
![Database URL Detection](images/demo-database-url-detection.png)

## 📖 Usage

### Normal Commits
The hook runs automatically on every `git commit`:

```bash
git add .
git commit -m "your message"
# Hook automatically checks staged files
```

### Test If Hook Works

Create a test file:
```bash
echo 'OPENAI_API_KEY="sk-1234567890abcdef1234567890abcdef"' > test.txt
git add test.txt
git commit -m "test"
# Should be blocked with warning
```

### Bypass Check (Use Carefully)

If you're certain it's a false positive:
```bash
git commit --no-verify -m "your message"
```

⚠️ **Warning**: Only use this option when you're certain there's no sensitive information!

## 🛠️ Configuration

### 1. Create .gitignore

```bash
# Create or edit .gitignore
cat >> .gitignore << EOF
# Environment files
.env
.env.*
*.env

# Keys and certificates
*.pem
*.key
*.p12
*.pfx
*.jks
*.keystore

# Config files
config/secrets.*
credentials.json
service-account*.json

# IDE settings
.vscode/settings.json
.idea/
EOF
```

### 2. Use Environment Variables

Don't hardcode secrets:
```javascript
// ❌ Wrong
const apiKey = "sk-1234567890abcdef";

// ✅ Correct
const apiKey = process.env.OPENAI_API_KEY;
```

### 3. Use .env Files for Local Development

Create `.env` file:
```bash
OPENAI_API_KEY=sk-your-key-here
ANTHROPIC_API_KEY=sk-ant-your-key-here
DATABASE_URL=postgresql://user:pass@localhost/db
```

Use in code:
```javascript
require('dotenv').config();
const apiKey = process.env.OPENAI_API_KEY;
```

**Important**: Make sure `.env` is in `.gitignore`!

## ⚙️ Customization

### Add New Detection Patterns

Edit `check-secrets.sh`, add patterns to `PATTERNS` array:

```bash
declare -a PATTERNS=(
    # Add your custom pattern
    "your-pattern-here"
    # ...
)
```

### Add New Keywords

Add to `KEYWORDS` array:

```bash
declare -a KEYWORDS=(
    # Add your keyword
    "YOUR_SECRET_KEY"
    # ...
)
```

### Adjust Detection Strictness

- **Stricter**: Change high-entropy string check from warning to blocking
- **Looser**: Comment out certain detection patterns

## ❓ FAQ

### Q: Hook not running?
A: Make sure:
1. File has execute permission: `chmod +x .git/hooks/pre-commit`
2. Filename is correct: must be `pre-commit` (no extension)
3. You're in a Git repository

### Q: Too many false positives?
A: You can:
1. Use `--no-verify` to temporarily bypass
2. Adjust detection patterns
3. Exclude non-sensitive config files

### Q: How to check already committed history?
A: Use tools like:
- [git-secrets](https://github.com/awslabs/git-secrets)
- [truffleHog](https://github.com/trufflesecurity/trufflehog)
- [gitleaks](https://github.com/zricethezav/gitleaks)

### Q: How to use in CI/CD?
A: Add to CI pipeline:
```yaml
# GitHub Actions example
- name: Check secrets
  run: |
    chmod +x check-secrets.sh
    ./check-secrets.sh
```

## 💡 Best Practices

1. **Never** hardcode secrets in source code
2. **Use** environment variables for sensitive configuration
3. **Regularly** rotate your API keys
4. **Immediately** revoke any exposed keys
5. **Review** your commit history for any lingering sensitive data
6. **Educate** team members about security awareness

## 🚨 If Keys Are Leaked

1. **Immediately revoke** the leaked keys
2. **Generate new keys**
3. **Check logs** for unauthorized access
4. **Clean Git history** (if needed):
   ```bash
   # Using BFG Repo-Cleaner
   bfg --delete-files YOUR-FILE-WITH-SECRETS
   
   # Or using git filter-branch (more complex)
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch PATH-TO-YOUR-FILE" \
     --prune-empty --tag-name-filter cat -- --all
   ```

## 🤝 Contributing

Issues and pull requests are welcome! If you discover new API key formats, please let us know.

## 📄 License

MIT License - Free to use and modify

---

**Remember**: Security is every developer's responsibility! Protecting your keys means protecting your applications and users. 🛡️
