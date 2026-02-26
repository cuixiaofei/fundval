# 项目管理 Makefile | Project Management Makefile

一个功能丰富的 Makefile，用于管理开源项目，支持 Git 多账号管理、环境信息显示和语义化版本控制。

A feature-rich Makefile for managing open source projects with Git multi-account support, environment info display, and semantic versioning.

---

## 📋 目录 | Table of Contents

- [功能特性 | Features](#功能特性--features)
- [快速开始 | Quick Start](#快速开始--quick-start)
- [Git 多账号管理 | Git Multi-Account Management](#git-多账号管理--git-multi-account-management)
- [Commit 命令 | Commit Command](#commit-命令--commit-command)
- [环境信息显示 | Environment Info Display](#环境信息显示--environment-info-display)
- [版本管理 | Version Management](#版本管理--version-management)
- [扩展性 | Extensibility](#扩展性--extensibility)

---

## 功能特性 | Features

### 🇨🇳 中文

- ✅ **Git 多账号管理** - 通过 SSH 别名实现自动路由
- ✅ **改进的 Commit 命令** - 无需引号，直接输入提交信息
- ✅ **环境信息显示** - 通过外部脚本显示 Conda/Python 等环境信息
- ✅ **语义化版本管理** - 支持 patch/minor/major 版本递增
- ✅ **中英文双语注释** - 所有命令和输出都支持中英文
- ✅ **可扩展架构** - 支持自定义命令和外部脚本

### 🇺🇸 English

- ✅ **Git Multi-Account Management** - Automatic routing via SSH aliases
- ✅ **Enhanced Commit Command** - No quotes needed, type message directly
- ✅ **Environment Info Display** - Show Conda/Python env info via external scripts
- ✅ **Semantic Versioning** - Support patch/minor/major version bumping
- ✅ **Bilingual Comments** - All commands and outputs support Chinese and English
- ✅ **Extensible Architecture** - Support custom commands and external scripts

---

## 快速开始 | Quick Start

### 1. 基础命令 | Basic Commands

```bash
# 显示帮助信息 | Show help
make help

# 查看项目状态 | Check project status
make status

# 添加所有变更 | Add all changes
make add

# 提交代码 (新方式 - 无需引号) | Commit code (new way - no quotes)
make commit 修复了登录bug
make commit 添加新功能 - 用户认证模块

# 推送代码 | Push code
make push

# 拉取更新 | Pull updates
make pull

# 完整同步流程 | Complete sync workflow
make sync
```

---

## Git 多账号管理 | Git Multi-Account Management

### 配置步骤 | Setup Steps

#### 步骤 1: 生成 SSH 密钥 | Step 1: Generate SSH Keys

```bash
# 个人账号 | Personal account
ssh-keygen -t ed25519 -C "personal@example.com" -f ~/.ssh/id_ed25519_personal

# 工作账号 | Work account
ssh-keygen -t ed25519 -C "work@company.com" -f ~/.ssh/id_ed25519_work
```

#### 步骤 2: 配置 SSH | Step 2: Configure SSH

复制 `ssh_config.example` 到 `~/.ssh/config` 并修改：

Copy `ssh_config.example` to `~/.ssh/config` and modify:

```bash
cp ssh_config.example ~/.ssh/config
chmod 600 ~/.ssh/config
```

#### 步骤 3: 添加公钥到 Git 平台 | Step 3: Add Public Keys to Git Platform

```bash
# 复制公钥 | Copy public key
cat ~/.ssh/id_ed25519_personal.pub
# 然后添加到 GitHub/GitLab 的 SSH Keys 设置中
# Then add to GitHub/GitLab SSH Keys settings
```

#### 步骤 4: 测试连接 | Step 4: Test Connection

```bash
# 测试个人账号 | Test personal account
ssh -T github-personal

# 测试工作账号 | Test work account
ssh -T github-work
```

### Makefile 命令 | Makefile Commands

```bash
# 显示当前 Git 配置 | Show current Git config
make git-config-show

# 设置 Git 用户信息 | Set Git user config
make git-config-set NAME="张三" EMAIL="zhangsan@example.com"

# 列出 SSH 密钥 | List SSH keys
make ssh-list

# 测试 SSH 连接 | Test SSH connection
make ssh-test

# 设置远程仓库的 SSH 别名 | Set SSH alias for remote
make remote-set-alias ALIAS=github-personal

# 将 HTTPS 远程 URL 转换为 SSH | Convert HTTPS remote URL to SSH
make remote-url-ssh
```

### 多账号工作流程 | Multi-Account Workflow

```bash
# 克隆个人项目 | Clone personal project
git clone github-personal:username/personal-repo.git

# 克隆工作项目 | Clone work project
git clone github-work:company/work-repo.git

# 在项目目录中设置对应的 SSH 别名 | Set corresponding SSH alias in project
make remote-set-alias ALIAS=github-personal
```

---

## Commit 命令 | Commit Command

### 🎉 新特性：无需引号 | New Feature: No Quotes Needed

```bash
# ✅ 正确 - 直接输入 | Correct - type directly
make commit 修复了登录bug
make commit 添加用户认证功能
make commit 更新文档和配置文件

# ✅ 也支持引号 | Quotes also supported
make commit "修复了内存泄漏问题"

# ✅ 兼容旧格式 | Legacy format compatible
make commit MSG="修复了bug"

# ❌ 不再需要这样 | No longer needed
make commit MSG="修复了登录bug"
```

### 其他 Commit 相关命令 | Other Commit Commands

```bash
# 快速提交（使用默认消息）| Quick commit (default message)
make quick-commit

# 修改最后一次提交 | Amend last commit
make amend

# 修改最后一次提交的提交信息 | Amend last commit message
make amend-msg 新的提交信息
```

---

## 环境信息显示 | Environment Info Display

### 显示完整环境信息 | Show Complete Environment Info

```bash
# 显示所有环境信息 | Show all environment info
make env

# 显示 Conda 环境信息 | Show Conda environment info
make conda-info

# 显示 Python 环境信息 | Show Python environment info
make python-info

# 显示 Node.js 环境信息 | Show Node.js environment info
make node-info
```

### 自定义环境脚本 | Custom Environment Script

你可以编辑 `scripts/show_env_info.sh` 来添加自定义信息显示：

You can edit `scripts/show_env_info.sh` to add custom info display:

```bash
# 添加新的显示函数 | Add new display function
show_custom_info() {
    echo "=== 自定义信息 | Custom Info ==="
    echo "Your custom info here"
}

# 在主函数中调用 | Call in main function
main() {
    case "${1:-all}" in
        custom)
            show_custom_info
            ;;
        # ...
    esac
}
```

---

## 版本管理 | Version Management

### 查看和设置版本 | View and Set Versions

```bash
# 显示当前版本 | Show current version
make version-show

# 递增修订版本 (1.0.0 → 1.0.1) | Bump patch version
make version-patch

# 递增次版本 (1.0.1 → 1.1.0) | Bump minor version
make version-minor

# 递增主版本 (1.1.0 → 2.0.0) | Bump major version
make version-major

# 设置指定版本 | Set specific version
make version-set V=2.0.0
```

### 发布流程 | Release Workflow

```bash
# 发布修订版本 | Release patch version
make release-patch

# 发布次版本 | Release minor version
make release-minor

# 发布主版本 | Release major version
make release-major

# 推送标签到远程 | Push tags to remote
make push-tags
```

---

## 扩展性 | Extensibility

### 方法 1: 创建自定义 Makefile | Method 1: Create Custom Makefile

创建 `Makefile.custom` 文件：

Create `Makefile.custom` file:

```makefile
# 自定义命令 | Custom commands
my-deploy:
	@echo "部署到生产环境 | Deploying to production..."
	# 你的部署命令 | Your deployment commands

my-test:
	@echo "运行自定义测试 | Running custom tests..."
	# 你的测试命令 | Your test commands
```

主 Makefile 会自动包含此文件。

The main Makefile will automatically include this file.

### 方法 2: 添加外部脚本 | Method 2: Add External Scripts

```bash
# 创建新脚本 | Create new script
touch scripts/my_custom_script.sh
chmod +x scripts/my_custom_script.sh
```

然后在 Makefile 中添加命令：

Then add command in Makefile:

```makefile
my-script:
	@$(SCRIPTS_DIR)/my_custom_script.sh
```

### 方法 3: 直接扩展 Makefile | Method 3: Directly Extend Makefile

在 Makefile 末尾添加自定义命令：

Add custom commands at the end of Makefile:

```makefile
#=============================================================================#
# 自定义命令 | Custom Commands
#=============================================================================#
docker-build:
	@echo "构建 Docker 镜像 | Building Docker image..."
	docker build -t $(PROJECT_NAME):$(VERSION) .

docker-run:
	@echo "运行 Docker 容器 | Running Docker container..."
	docker run -d --name $(PROJECT_NAME) $(PROJECT_NAME):$(VERSION)
```

---

## 完整命令列表 | Complete Command List

### 日常开发 | Daily Development

| 命令 | 描述 | Description |
|------|------|-------------|
| `make help` | 显示帮助信息 | Display help |
| `make status` | 查看项目状态 | Show project status |
| `make add` | 添加所有变更 | Add all changes |
| `make commit <msg>` | 提交代码 | Commit code |
| `make quick-commit` | 快速提交 | Quick commit |
| `make push` | 推送到远程 | Push to remote |
| `make pull` | 拉取更新 | Pull updates |
| `make sync` | 完整同步 | Complete sync |

### Git 多账号 | Git Multi-Account

| 命令 | 描述 | Description |
|------|------|-------------|
| `make git-config-show` | 显示 Git 配置 | Show Git config |
| `make git-config-set` | 设置 Git 用户 | Set Git user |
| `make ssh-list` | 列出 SSH 密钥 | List SSH keys |
| `make ssh-test` | 测试 SSH 连接 | Test SSH connection |
| `make remote-set-alias` | 设置 SSH 别名 | Set SSH alias |

### 环境信息 | Environment Info

| 命令 | 描述 | Description |
|------|------|-------------|
| `make env` | 显示完整环境 | Show complete env |
| `make conda-info` | Conda 环境 | Conda environment |
| `make python-info` | Python 环境 | Python environment |
| `make node-info` | Node.js 环境 | Node.js environment |

### 版本管理 | Version Management

| 命令 | 描述 | Description |
|------|------|-------------|
| `make version-show` | 显示版本 | Show version |
| `make version-patch` | 递增修订版本 | Bump patch |
| `make version-minor` | 递增次版本 | Bump minor |
| `make version-major` | 递增主版本 | Bump major |
| `make release-patch` | 发布修订版本 | Release patch |
| `make release-minor` | 发布次版本 | Release minor |
| `make release-major` | 发布主版本 | Release major |

---

## 文件结构 | File Structure

```
.
├── Makefile                    # 主 Makefile | Main Makefile
├── VERSION                     # 版本文件 | Version file
├── scripts/
│   └── show_env_info.sh        # 环境信息脚本 | Environment info script
├── ssh_config.example          # SSH 配置示例 | SSH config example
├── Makefile.custom             # 自定义命令 (可选) | Custom commands (optional)
└── README_Makefile.md          # 本文档 | This documentation
```

---

## 许可证 | License

此 Makefile 是开源的，您可以自由使用和修改。

This Makefile is open source, you are free to use and modify it.
