# Git Secrets Guard 🔐

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/ivesyi/git-secrets-guard/pulls)

[English](README.md) | **[简体中文](README.zh-CN.md)**

*防止将敏感信息（API密钥、密码、个人隐私等）意外提交到Git仓库的预提交钩子*

</div>

## 特性 ✨

### 支持检测的LLM API密钥
- **OpenAI**: `sk-xxx`, `sk-proj-xxx`
- **Anthropic Claude**: `sk-ant-xxx`
- **Google (Gemini/PaLM)**: `AIzaxxx`
- **Azure OpenAI**: Azure密钥格式
- **Hugging Face**: `hf_xxx`
- **国内LLM提供商**:
  - 百度文心一言
  - 阿里通义千问
  - 讯飞星火
  - 智谱AI (GLM)
  - Moonshot/Kimi
  - MiniMax

### 其他检测内容
- AWS、GitHub、Slack等服务密钥
- 数据库连接字符串和密码
- SSH私钥和证书
- JWT令牌
- 个人隐私信息（身份证、手机号、银行卡号）
- 高熵字符串（可能的密钥）

## 快速安装 🚀

### 一键安装 🎯

```bash
# 选项 1：仅当前仓库
curl -sSL https://raw.githubusercontent.com/ivesyi/git-secrets-guard/main/install.sh | bash -s 1

# 选项 2：当前 + 所有未来仓库（推荐）
curl -sSL https://raw.githubusercontent.com/ivesyi/git-secrets-guard/main/install.sh | bash -s 2
```

### 方法2：使用本地安装脚本

```bash
# 给脚本添加执行权限
chmod +x install-git-hooks.sh

# 运行安装脚本
./install-git-hooks.sh
```

安装脚本提供以下选项：
1. 在当前目录安装
2. 在指定仓库安装
3. 全局安装（影响所有新仓库）
4. 显示手动安装说明

### 方法3：手动安装

```bash
# 1. 初始化Git仓库（如果还没有）
git init

# 2. 复制hook脚本到.git/hooks目录
cp check-secrets.sh .git/hooks/pre-commit

# 3. 添加执行权限
chmod +x .git/hooks/pre-commit
```

### 方法4：全局配置

```bash
# 1. 创建全局Git模板目录
mkdir -p ~/.git-templates/hooks

# 2. 复制hook到模板目录
cp check-secrets.sh ~/.git-templates/hooks/pre-commit
chmod +x ~/.git-templates/hooks/pre-commit

# 3. 配置Git使用模板
git config --global init.templatedir ~/.git-templates

# 4. 对于已存在的仓库，运行git init来应用模板
cd /path/to/existing/repo
git init
```

## 实际效果展示 🖥️

### 检测到API密钥时：
![API Key Detection](images/demo-api-key-detection.png)

### 检测到数据库连接字符串时：
![Database URL Detection](images/demo-database-url-detection.png)

## 使用方法 📖

### 正常提交
Hook会在每次`git commit`时自动运行：

```bash
git add .
git commit -m "your message"
# Hook自动检查暂存的文件
```

### 测试Hook是否工作

创建一个测试文件：
```bash
echo 'OPENAI_API_KEY="sk-1234567890abcdef1234567890abcdef"' > test.txt
git add test.txt
git commit -m "test"
# 应该被阻止并显示警告
```

### 绕过检查（谨慎使用）

如果确定是误报，可以使用`--no-verify`选项：
```bash
git commit --no-verify -m "your message"
```

⚠️ **警告**：只有在确认没有敏感信息时才使用此选项！

## 配置建议 🛠️

### 1. 创建.gitignore文件

```bash
# 创建或编辑.gitignore
cat >> .gitignore << EOF
# 环境变量文件
.env
.env.*
*.env

# 密钥和证书
*.pem
*.key
*.p12
*.pfx
*.jks
*.keystore

# 配置文件
config/secrets.*
credentials.json
service-account*.json

# IDE配置
.vscode/settings.json
.idea/
EOF
```

### 2. 使用环境变量

不要硬编码密钥：
```javascript
// ❌ 错误做法
const apiKey = "sk-1234567890abcdef";

// ✅ 正确做法
const apiKey = process.env.OPENAI_API_KEY;
```

### 3. 使用.env文件进行本地开发

创建`.env`文件：
```bash
OPENAI_API_KEY=sk-your-key-here
ANTHROPIC_API_KEY=sk-ant-your-key-here
DATABASE_URL=postgresql://user:pass@localhost/db
```

在代码中使用：
```javascript
require('dotenv').config();
const apiKey = process.env.OPENAI_API_KEY;
```

**重要**：确保`.env`在`.gitignore`中！

## 高级配置 ⚙️

### 配置文件支持

在仓库根目录创建 `.gitsecrets.yml` 文件进行高级配置：

```yaml
# .gitsecrets.yml
version: 1
enabled: true

# 组织内部的自定义模式
custom_patterns:
  - pattern: "INTERNAL_KEY_[A-Z0-9]{32}"
    description: "内部API密钥"
    
# 自定义检测关键词
custom_keywords:
  - "COMPANY_SECRET"
  - "INTERNAL_TOKEN"

# 白名单配置
whitelist:
  # 跳过这些文件
  files:
    - "README.md"
    - "docs/examples/*"
    
  # 忽略这些模式
  patterns:
    - "sk-test.*"  # 测试密钥
    - "example\\.com"
    
  # 跳过这些扩展名
  extensions:
    - ".md"
    - ".txt"
    
  # 跳过这些目录
  directories:
    - "node_modules"
    - "test/fixtures"

actions:
  block_commit: true  # 或 false 仅警告模式
```

**功能特点：**
- ✅ 自定义检测模式和关键词
- ✅ 白名单支持（文件、模式、扩展名、目录）
- ✅ 配置阻止或仅警告模式
- ✅ 控制输出详细程度

参见 [.gitsecrets.example.yml](.gitsecrets.example.yml) 获取完整示例。

### 手动自定义

或者直接编辑 `check-secrets.sh`：

```bash
# 在 PATTERNS 数组中添加模式
declare -a PATTERNS=(
    "your-pattern-here"
    # ...
)

# 在 KEYWORDS 数组中添加关键词
declare -a KEYWORDS=(
    "YOUR_SECRET_KEY"
    # ...
)
```

## 常见问题 ❓

### Q: Hook没有运行？
A: 确保：
1. 文件有执行权限：`chmod +x .git/hooks/pre-commit`
2. 文件名正确：必须是`pre-commit`（没有扩展名）
3. 在Git仓库中：确保当前目录是Git仓库

### Q: 误报太多？
A: 你可以：
1. 使用`--no-verify`临时绕过
2. 调整检测模式
3. 将非敏感的配置文件排除

### Q: 如何检查已经提交的历史？
A: 使用工具如：
- [git-secrets](https://github.com/awslabs/git-secrets)
- [truffleHog](https://github.com/trufflesecurity/trufflehog)
- [gitleaks](https://github.com/zricethezav/gitleaks)

### Q: 如何在CI/CD中使用？
A: 在CI pipeline中添加：
```yaml
# GitHub Actions示例
- name: Check secrets
  run: |
    chmod +x check-secrets.sh
    ./check-secrets.sh
```

## 最佳实践 💡

1. **永远不要**硬编码密钥在源代码中
2. **使用**环境变量管理敏感配置
3. **定期**轮换你的API密钥
4. **立即**撤销任何已暴露的密钥
5. **审查**你的提交历史，确保没有遗留的敏感信息
6. **教育**团队成员安全意识

## 如果密钥已经泄露 🚨

1. **立即撤销**泄露的密钥
2. **生成新密钥**
3. **检查日志**查看是否有未授权访问
4. **清理Git历史**（如果需要）：
   ```bash
   # 使用BFG Repo-Cleaner
   bfg --delete-files YOUR-FILE-WITH-SECRETS
   
   # 或使用git filter-branch（更复杂）
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch PATH-TO-YOUR-FILE" \
     --prune-empty --tag-name-filter cat -- --all
   ```

## 贡献 🤝

欢迎提交问题和改进建议！如果你发现新的API密钥格式，请告诉我们。

## 许可证 📄

MIT License - 自由使用和修改

---

**记住**：安全是每个开发者的责任！保护好你的密钥就是保护你的应用和用户。🛡️
