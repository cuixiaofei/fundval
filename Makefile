#=============================================================================#
# 轻量级开源项目 Makefile | Lightweight Open Source Project Makefile
# 支持手动版本管理 + 简单CI/CD流程 + 多账号Git管理 + 环境配置显示
# Supports: Manual Versioning | Simple CI/CD | Multi-Account Git | Env Display
#=============================================================================#
SHELL := /bin/bash

#=============================================================================#
# 项目基础配置 | Project Basic Configuration
#=============================================================================#
PROJECT_NAME := mydotfiles
VERSION_FILE := VERSION
CURRENT_DATE := $(shell date +%Y-%m-%d)
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)

#=============================================================================#
# Git 多账号配置 | Git Multi-Account Configuration
#=============================================================================#
BRANCH := main
REMOTE := origin
SSH_ALIAS ?= $(shell git config --local remote.$(REMOTE).ssh-alias 2>/dev/null || echo "")
GIT_CONFIG_SCOPE := local

#=============================================================================#
# 外部脚本配置 | External Scripts Configuration
#=============================================================================#
SCRIPTS_DIR := scripts
ENV_SCRIPT := $(SCRIPTS_DIR)/show_env_info.sh

#=============================================================================#
# 版本管理 | Version Management
#=============================================================================#
VERSION := $(shell cat $(VERSION_FILE) 2>/dev/null || echo "0.1.0")
MAJOR := $(shell echo $(VERSION) | cut -d. -f1)
MINOR := $(shell echo $(VERSION) | cut -d. -f2)
PATCH := $(shell echo $(VERSION) | cut -d. -f3)

#=============================================================================#
# 颜色定义 (使用printf格式) | Color Definitions (printf format)
#=============================================================================#
C_RESET := \x1b[0m
C_RED := \x1b[31m
C_GREEN := \x1b[32m
C_YELLOW := \x1b[33m
C_BLUE := \x1b[34m
C_CYAN := \x1b[36m
C_BOLD := \x1b[1m

#=============================================================================#
# 主要帮助命令 | Main Help Command
#=============================================================================#
.PHONY: help
help:  ## 显示帮助信息 | Display help information
	@printf "\n"
	@printf "$(C_BOLD)=== $(PROJECT_NAME) - 版本 $(VERSION) | Version $(VERSION) ===$(C_RESET)\n"
	@printf "\n"
	@printf "$(C_CYAN)📋 常用命令 | Common Commands:$(C_RESET)\n"
	@grep -E "^[a-zA-Z0-9_-]+:.*##" $(MAKEFILE_LIST) | grep -v "help:" | head -20 | while read line; do \
		cmd=$$(echo "$$line" | sed 's/:.*//'); \
		desc=$$(echo "$$line" | sed 's/.*## //'); \
		printf "  $(C_GREEN)%-20s$(C_RESET) %s\n" "$$cmd" "$$desc"; \
	done
	@printf "\n"
	@printf "$(C_CYAN)🔖 版本管理 | Version Management:$(C_RESET)\n"
	@grep -E "^version-[a-z]+:.*##" $(MAKEFILE_LIST) | while read line; do \
		cmd=$$(echo "$$line" | sed 's/:.*//'); \
		desc=$$(echo "$$line" | sed 's/.*## //'); \
		printf "  $(C_GREEN)%-20s$(C_RESET) %s\n" "$$cmd" "$$desc"; \
	done
	@printf "\n"
	@printf "$(C_CYAN)🔐 Git 多账号管理 | Git Multi-Account:$(C_RESET)\n"
	@grep -E "^(git-|ssh-|remote-)[a-z-]+:.*##" $(MAKEFILE_LIST) | while read line; do \
		cmd=$$(echo "$$line" | sed 's/:.*//'); \
		desc=$$(echo "$$line" | sed 's/.*## //'); \
		printf "  $(C_GREEN)%-20s$(C_RESET) %s\n" "$$cmd" "$$desc"; \
	done
	@printf "\n"
	@printf "$(C_CYAN)🖥️  环境信息 | Environment Info:$(C_RESET)\n"
	@grep -E "^(env|conda|python|node)-?[a-z]*:.*##" $(MAKEFILE_LIST) | while read line; do \
		cmd=$$(echo "$$line" | sed 's/:.*//'); \
		desc=$$(echo "$$line" | sed 's/.*## //'); \
		printf "  $(C_GREEN)%-20s$(C_RESET) %s\n" "$$cmd" "$$desc"; \
	done
	@printf "\n"
	@printf "$(C_YELLOW)💡 提示 | Tips:$(C_RESET)\n"
	@printf "  • 使用 'make commit 你的提交信息' 直接提交 | Use 'make commit your message'\n"
	@printf "  • 使用 'make env' 查看环境配置 | Use 'make env' to check environment\n"
	@printf "  • 编辑 Makefile 自定义配置 | Edit Makefile to customize settings\n"
	@printf "\n"

#=============================================================================#
# 日常开发流程 | Daily Development Workflow
#=============================================================================#
.PHONY: status
status:  ## 查看项目状态 | Show project status
	@printf "\n"
	@printf "$(C_BOLD)=== 项目状态 | Project Status ===$(C_RESET)\n"
	@printf "📁 项目 | Project: $(C_CYAN)$(PROJECT_NAME)$(C_RESET)\n"
	@printf "🏷️  版本 | Version: $(C_CYAN)$(VERSION)$(C_RESET)\n"
	@printf "📅 日期 | Date: $(C_CYAN)$(CURRENT_DATE)$(C_RESET)\n"
	@printf "\n"
	@printf "$(C_BOLD)=== Git 状态 | Git Status ===$(C_RESET)\n"
	@git status -s 2>/dev/null || printf "❌ 不是Git仓库 | Not a Git repository\n"
	@printf "\n"
	@printf "$(C_BOLD)=== 分支信息 | Branch Info ===$(C_RESET)\n"
	@git branch -vv 2>/dev/null | grep "^*" || printf "当前无分支 | No branch\n"
	@printf "\n"
	@if [ -n "$(SSH_ALIAS)" ]; then \
		printf "$(C_BOLD)=== SSH 配置 | SSH Config ===$(C_RESET)\n"; \
		printf "🔑 SSH 别名 | SSH Alias: $(C_GREEN)$(SSH_ALIAS)$(C_RESET)\n"; \
		printf "\n"; \
	fi

.PHONY: add
add:  ## 添加所有变更到暂存区 | Add all changes to staging
	@printf "📦 添加变更到暂存区 | Adding changes to staging...\n"
	@git add .
	@printf "$(C_GREEN)✅ 已添加所有变更 | All changes added$(C_RESET)\n"

#=============================================================================#
# 改进的 Commit 命令 | Enhanced Commit Command
#=============================================================================#
COMMIT_MSG := $(filter-out $@,$(MAKECMDGOALS))

.PHONY: check-git
check-git:
	@git rev-parse --git-dir > /dev/null 2>&1 || (printf "$(C_RED)❌ 错误：当前目录不是Git仓库 | Error: Not a Git repository$(C_RESET)\n" && exit 1)

.PHONY: commit
commit: check-git  ## 提交代码 (用法: make commit 你的提交信息) | Commit code (usage: make commit your message)
	@$(eval MSG := $(if $(MSG),$(MSG),$(COMMIT_MSG)))
	@if [ -z "$(MSG)" ]; then \
		printf "$(C_RED)❌ 错误：请提供提交信息 | Error: Please provide commit message$(C_RESET)\n"; \
		printf "\n"; \
		printf "$(C_YELLOW)💡 用法示例 | Usage examples:$(C_RESET)\n"; \
		printf "  make commit 修复了登录bug\n"; \
		printf "  make commit 添加新功能 - 用户认证模块\n"; \
		printf "  make commit MSG=\"修复了内存泄漏问题\"\n"; \
		printf "\n"; \
		printf "$(C_CYAN)📝 提示 | Tip: 不需要引号，直接写提交信息 | No quotes needed$(C_RESET)\n"; \
		exit 1; \
	fi
	@printf "📝 提交信息 | Commit message: $(C_CYAN)$(MSG)$(C_RESET)\n"
	@git commit -m "$(MSG)"
	@printf "$(C_GREEN)✅ 提交成功 | Commit successful: $(MSG)$(C_RESET)\n"

%:
	@:

.PHONY: quick-commit
quick-commit: check-git  ## 快速提交，使用默认消息 | Quick commit with default message
	@printf "⚡ 快速提交中 | Quick committing...\n"
	@git add .
	@git commit -m "更新: $(CURRENT_DATE) 的修改 | Update: Changes on $(CURRENT_DATE)"
	@printf "$(C_GREEN)✅ 快速提交完成 | Quick commit completed$(C_RESET)\n"

.PHONY: amend
amend: check-git  ## 修改最后一次提交 | Amend last commit
	@printf "📝 修改最后一次提交 | Amending last commit...\n"
	@git add .
	@git commit --amend --no-edit
	@printf "$(C_GREEN)✅ 已修改最后一次提交 | Last commit amended$(C_RESET)\n"

.PHONY: amend-msg
amend-msg: check-git  ## 修改最后一次提交的提交信息 | Amend last commit message
	@$(eval MSG := $(if $(MSG),$(MSG),$(COMMIT_MSG)))
	@if [ -z "$(MSG)" ]; then \
		printf "$(C_RED)❌ 错误：请提供新的提交信息 | Error: Please provide new message$(C_RESET)\n"; \
		printf "$(C_YELLOW)💡 用法 | Usage: make amend-msg 新的提交信息$(C_RESET)\n"; \
		exit 1; \
	fi
	@printf "📝 修改提交信息 | Amending commit message: $(C_CYAN)$(MSG)$(C_RESET)\n"
	@git add .
	@git commit --amend -m "$(MSG)"
	@printf "$(C_GREEN)✅ 提交信息已修改 | Commit message amended$(C_RESET)\n"

#=============================================================================#
# 推送与拉取 | Push & Pull
#=============================================================================#
.PHONY: push
push: check-git  ## 推送到远程仓库 | Push to remote repository
	@printf "🚀 推送到 $(REMOTE)/$(BRANCH) | Pushing to $(REMOTE)/$(BRANCH)...\n"
	@git push $(REMOTE) $(BRANCH)
	@printf "$(C_GREEN)✅ 推送完成 | Push completed$(C_RESET)\n"

.PHONY: push-force
push-force: check-git  ## 强制推送到远程仓库 (谨慎使用) | Force push to remote (use with caution)
	@printf "$(C_YELLOW)⚠️  警告：即将强制推送 | Warning: About to force push$(C_RESET)\n"
	@read -p "确定要继续吗？| Are you sure? [y/N] " confirm && [ $$confirm = y ] || exit 1
	@printf "🚀 强制推送到 $(REMOTE)/$(BRANCH) | Force pushing to $(REMOTE)/$(BRANCH)...\n"
	@git push $(REMOTE) $(BRANCH) --force-with-lease
	@printf "$(C_GREEN)✅ 强制推送完成 | Force push completed$(C_RESET)\n"

.PHONY: pull
pull: check-git  ## 从远程仓库拉取更新 | Pull updates from remote
	@printf "📥 拉取远程更新 | Pulling remote updates...\n"
	@git pull $(REMOTE) $(BRANCH)
	@printf "$(C_GREEN)✅ 拉取完成 | Pull completed$(C_RESET)\n"

.PHONY: fetch
fetch: check-git  ## 获取远程更新但不合并 | Fetch remote updates without merging
	@printf "📥 获取远程更新 | Fetching remote updates...\n"
	@git fetch $(REMOTE)
	@printf "$(C_GREEN)✅ 获取完成 | Fetch completed$(C_RESET)\n"

.PHONY: sync
sync: check-git pull add quick-commit push  ## 完整的同步流程 | Complete sync workflow
	@printf "$(C_GREEN)✅ 同步完成 | Sync completed$(C_RESET)\n"

#=============================================================================#
# Git 多账号管理 | Git Multi-Account Management
#=============================================================================#
.PHONY: git-config-show
git-config-show: check-git  ## 显示当前Git配置 | Show current Git config
	@printf "\n"
	@printf "$(C_BOLD)=== Git 用户配置 | Git User Config ===$(C_RESET)\n"
	@printf "👤 用户名 | Name:  $(C_CYAN)$(shell git config --$(GIT_CONFIG_SCOPE) user.name)$(C_RESET)\n"
	@printf "📧 邮箱 | Email: $(C_CYAN)$(shell git config --$(GIT_CONFIG_SCOPE) user.email)$(C_RESET)\n"
	@printf "\n"
	@printf "$(C_BOLD)=== Git 远程配置 | Git Remote Config ===$(C_RESET)\n"
	@git remote -v
	@printf "\n"
	@if [ -n "$(SSH_ALIAS)" ]; then \
		printf "$(C_BOLD)=== SSH 别名配置 | SSH Alias Config ===$(C_RESET)\n"; \
		printf "🔑 当前SSH别名 | Current SSH Alias: $(C_GREEN)$(SSH_ALIAS)$(C_RESET)\n"; \
		printf "\n"; \
		printf "$(C_YELLOW)💡 使用以下命令测试SSH连接 | Test SSH connection with:$(C_RESET)\n"; \
		printf "  ssh -T $(SSH_ALIAS)\n"; \
		printf "\n"; \
	fi

.PHONY: git-config-set
git-config-set: check-git  ## 设置Git用户信息 (用法: make git-config-set NAME="姓名" EMAIL="邮箱") | Set Git user config
	@if [ -z "$(NAME)" ] || [ -z "$(EMAIL)" ]; then \
		printf "$(C_RED)❌ 错误：请提供姓名和邮箱 | Error: Please provide NAME and EMAIL$(C_RESET)\n"; \
		printf "$(C_YELLOW)💡 用法 | Usage: make git-config-set NAME=\"张三\" EMAIL=\"zhangsan@example.com\"$(C_RESET)\n"; \
		exit 1; \
	fi
	@printf "🔧 设置Git用户配置 | Setting Git user config...\n"
	@git config --$(GIT_CONFIG_SCOPE) user.name "$(NAME)"
	@git config --$(GIT_CONFIG_SCOPE) user.email "$(EMAIL)"
	@printf "$(C_GREEN)✅ Git配置已更新 | Git config updated$(C_RESET)\n"
	@printf "   用户名 | Name:  $(C_CYAN)$(NAME)$(C_RESET)\n"
	@printf "   邮箱 | Email: $(C_CYAN)$(EMAIL)$(C_RESET)\n"

.PHONY: ssh-list
ssh-list:  ## 列出可用的SSH密钥 | List available SSH keys
	@printf "\n"
	@printf "$(C_BOLD)=== SSH 密钥列表 | SSH Key List ===$(C_RESET)\n"
	@if [ -d ~/.ssh ]; then \
		printf "$(C_CYAN)📁 ~/.ssh 目录中的密钥 | Keys in ~/.ssh:$(C_RESET)\n"; \
		ls -la ~/.ssh/ 2>/dev/null | grep -E "id_|\.pub" | awk '{printf "  %s\n", $$9}'; \
	else \
		printf "❌ ~/.ssh 目录不存在 | ~/.ssh directory not found\n"; \
	fi
	@printf "\n"
	@printf "$(C_BOLD)=== SSH 配置 | SSH Config ===$(C_RESET)\n"
	@if [ -f ~/.ssh/config ]; then \
		printf "$(C_CYAN)📄 ~/.ssh/config 内容 | Content:$(C_RESET)\n"; \
		cat ~/.ssh/config; \
	else \
		printf "❌ ~/.ssh/config 文件不存在 | ~/.ssh/config not found\n"; \
		printf "$(C_YELLOW)💡 提示 | Tip: 创建 ~/.ssh/config 来配置多账号 | Create ~/.ssh/config for multi-account setup$(C_RESET)\n"; \
	fi
	@printf "\n"

.PHONY: ssh-test
ssh-test:  ## 测试SSH连接 | Test SSH connection
	@if [ -n "$(SSH_ALIAS)" ]; then \
		printf "🧪 测试SSH连接 | Testing SSH connection to $(SSH_ALIAS)...\n"; \
		ssh -T $(SSH_ALIAS) 2>&1 || true; \
	else \
		printf "$(C_YELLOW)⚠️  未配置SSH别名 | SSH alias not configured$(C_RESET)\n"; \
		printf "$(C_CYAN)💡 使用以下命令测试 | Test with: ssh -T git@github.com$(C_RESET)\n"; \
	fi

.PHONY: remote-set-alias
remote-set-alias: check-git  ## 设置远程仓库的SSH别名 (用法: make remote-set-alias ALIAS=github-personal) | Set SSH alias for remote
	@if [ -z "$(ALIAS)" ]; then \
		printf "$(C_RED)❌ 错误：请提供SSH别名 | Error: Please provide ALIAS$(C_RESET)\n"; \
		printf "$(C_YELLOW)💡 用法 | Usage: make remote-set-alias ALIAS=github-personal$(C_RESET)\n"; \
		exit 1; \
	fi
	@printf "🔧 设置SSH别名 | Setting SSH alias: $(ALIAS)\n"
	@git config --local remote.$(REMOTE).ssh-alias "$(ALIAS)"
	@printf "$(C_GREEN)✅ SSH别名已设置 | SSH alias set: $(ALIAS)$(C_RESET)\n"

.PHONY: remote-url-ssh
remote-url-ssh: check-git  ## 将远程URL转换为SSH格式 | Convert remote URL to SSH format
	@$(eval CURRENT_URL := $(shell git remote get-url $(REMOTE) 2>/dev/null || echo ""))
	@if [ -z "$(CURRENT_URL)" ]; then \
		printf "$(C_RED)❌ 错误：未配置远程仓库 | Error: No remote configured$(C_RESET)\n"; \
		exit 1; \
	fi
	@printf "当前URL | Current URL: $(CURRENT_URL)\n"
	@if echo "$(CURRENT_URL)" | grep -q "^https://"; then \
		NEW_URL=$$(echo "$(CURRENT_URL)" | sed 's|https://github.com/|git@github.com:|'); \
		git remote set-url $(REMOTE) $$NEW_URL; \
		printf "$(C_GREEN)✅ 已转换为SSH格式 | Converted to SSH: $$NEW_URL$(C_RESET)\n"; \
	else \
		printf "$(C_YELLOW)⚠️  当前已经是SSH格式或不是GitHub仓库 | Already SSH or not GitHub$(C_RESET)\n"; \
	fi

#=============================================================================#
# 语义化版本管理 | Semantic Version Management
#=============================================================================#
.PHONY: version-show
version-show:  ## 显示当前版本 | Show current version
	@printf "$(C_CYAN)当前版本 | Current version: $(C_BOLD)$(VERSION)$(C_RESET)\n"

.PHONY: version-patch
version-patch:  ## 递增修订版本 (1.0.0 → 1.0.1) | Bump patch version
	@$(eval NEW_PATCH := $(shell echo $$(($(PATCH) + 1))))
	@$(eval NEW_VERSION := $(MAJOR).$(MINOR).$(NEW_PATCH))
	@echo $(NEW_VERSION) > $(VERSION_FILE)
	@printf "$(C_GREEN)✅ 版本已更新 | Version updated: $(VERSION) → $(NEW_VERSION)$(C_RESET)\n"

.PHONY: version-minor
version-minor:  ## 递增次版本 (1.0.1 → 1.1.0) | Bump minor version
	@$(eval NEW_MINOR := $(shell echo $$(($(MINOR) + 1))))
	@$(eval NEW_VERSION := $(MAJOR).$(NEW_MINOR).0)
	@echo $(NEW_VERSION) > $(VERSION_FILE)
	@printf "$(C_GREEN)✅ 版本已更新 | Version updated: $(VERSION) → $(NEW_VERSION)$(C_RESET)\n"

.PHONY: version-major
version-major:  ## 递增主版本 (1.1.0 → 2.0.0) | Bump major version
	@$(eval NEW_MAJOR := $(shell echo $$(($(MAJOR) + 1))))
	@$(eval NEW_VERSION := $(NEW_MAJOR).0.0)
	@echo $(NEW_VERSION) > $(VERSION_FILE)
	@printf "$(C_GREEN)✅ 版本已更新 | Version updated: $(VERSION) → $(NEW_VERSION)$(C_RESET)\n"

.PHONY: version-set
version-set:  ## 设置指定版本 (用法: make version-set V=2.0.0) | Set specific version
	@if [ -z "$(V)" ]; then \
		printf "$(C_RED)❌ 错误：请提供版本号 | Error: Please provide version number$(C_RESET)\n"; \
		printf "$(C_YELLOW)💡 用法 | Usage: make version-set V=2.0.0$(C_RESET)\n"; \
		exit 1; \
	fi
	@echo "$(V)" > $(VERSION_FILE)
	@printf "$(C_GREEN)✅ 版本已设置 | Version set: $(V)$(C_RESET)\n"

#=============================================================================#
# 发布流程 | Release Workflow
#=============================================================================#
.PHONY: release-patch
release-patch: version-patch check-git  ## 发布修订版本 | Release patch version
	@printf "📦 发布补丁版本 | Releasing patch version...\n"
	@git add $(VERSION_FILE)
	@git commit -m "发布: 版本 $(shell cat $(VERSION_FILE)) (补丁更新) | Release: v$(shell cat $(VERSION_FILE)) (patch)"
	@if git rev-parse -q --verify "v$(shell cat $(VERSION_FILE))" >/dev/null 2>&1; then \
		printf "$(C_YELLOW)⚠️  标签已存在，先删除 | Tag exists, deleting...$(C_RESET)\n"; \
		git tag -d "v$(shell cat $(VERSION_FILE))" 2>/dev/null || true; \
		git push $(REMOTE) --delete "v$(shell cat $(VERSION_FILE))" 2>/dev/null || true; \
	fi
	@git tag -a "v$(shell cat $(VERSION_FILE))" -m "发布版本 $(shell cat $(VERSION_FILE)) | Release v$(shell cat $(VERSION_FILE))"
	@printf "$(C_GREEN)✅ 补丁发布完成 | Patch release completed$(C_RESET)\n"
	@printf "$(C_CYAN)🚀 执行 'make push' 推送标签 | Run 'make push' to push tags$(C_RESET)\n"

.PHONY: release-minor
release-minor: version-minor check-git  ## 发布次版本 | Release minor version
	@printf "📦 发布次版本 | Releasing minor version...\n"
	@git add $(VERSION_FILE)
	@git commit -m "发布: 版本 $(shell cat $(VERSION_FILE)) (新功能) | Release: v$(shell cat $(VERSION_FILE)) (feature)"
	@if git rev-parse -q --verify "v$(shell cat $(VERSION_FILE))" >/dev/null 2>&1; then \
		printf "$(C_YELLOW)⚠️  标签已存在，先删除 | Tag exists, deleting...$(C_RESET)\n"; \
		git tag -d "v$(shell cat $(VERSION_FILE))" 2>/dev/null || true; \
		git push $(REMOTE) --delete "v$(shell cat $(VERSION_FILE))" 2>/dev/null || true; \
	fi
	@git tag -a "v$(shell cat $(VERSION_FILE))" -m "发布版本 $(shell cat $(VERSION_FILE)) | Release v$(shell cat $(VERSION_FILE))"
	@printf "$(C_GREEN)✅ 次版本发布完成 | Minor release completed$(C_RESET)\n"
	@printf "$(C_CYAN)🚀 执行 'make push' 推送标签 | Run 'make push' to push tags$(C_RESET)\n"

.PHONY: release-major
release-major: version-major check-git  ## 发布主版本 | Release major version
	@printf "📦 发布主版本 | Releasing major version...\n"
	@git add $(VERSION_FILE)
	@git commit -m "发布: 版本 $(shell cat $(VERSION_FILE)) (重大更新) | Release: v$(shell cat $(VERSION_FILE)) (breaking)"
	@if git rev-parse -q --verify "v$(shell cat $(VERSION_FILE))" >/dev/null 2>&1; then \
		printf "$(C_YELLOW)⚠️  标签已存在，先删除 | Tag exists, deleting...$(C_RESET)\n"; \
		git tag -d "v$(shell cat $(VERSION_FILE))" 2>/dev/null || true; \
		git push $(REMOTE) --delete "v$(shell cat $(VERSION_FILE))" 2>/dev/null || true; \
	fi
	@git tag -a "v$(shell cat $(VERSION_FILE))" -m "发布版本 $(shell cat $(VERSION_FILE)) | Release v$(shell cat $(VERSION_FILE))"
	@printf "$(C_GREEN)✅ 主版本发布完成 | Major release completed$(C_RESET)\n"
	@printf "$(C_CYAN)🚀 执行 'make push' 推送标签 | Run 'make push' to push tags$(C_RESET)\n"

.PHONY: push-tags
push-tags: check-git  ## 推送所有标签到远程 | Push all tags to remote
	@printf "🚀 推送标签到远程 | Pushing tags to remote...\n"
	@git push $(REMOTE) --tags
	@printf "$(C_GREEN)✅ 标签推送完成 | Tags pushed$(C_RESET)\n"

#=============================================================================#
# 环境信息显示 | Environment Info Display
#=============================================================================#
.PHONY: env
env:  ## 显示完整的环境配置信息 | Show complete environment info
	@printf "\n"
	@printf "$(C_BOLD)╔══════════════════════════════════════════════════════════════╗$(C_RESET)\n"
	@printf "$(C_BOLD)║           🖥️  开发环境信息 | Development Environment           ║$(C_RESET)\n"
	@printf "$(C_BOLD)╚══════════════════════════════════════════════════════════════╝$(C_RESET)\n"
	@printf "\n"
	@printf "$(C_BOLD)=== 系统信息 | System Info ===$(C_RESET)\n"
	@printf "🖥️  操作系统 | OS: $(C_CYAN)$(shell uname -s -r 2>/dev/null || echo 'Unknown')$(C_RESET)\n"
	@printf "🐚 Shell: $(C_CYAN)$(SHELL)$(C_RESET)\n"
	@printf "📅 时间 | Time: $(C_CYAN)$(shell date '+%Y-%m-%d %H:%M:%S')$(C_RESET)\n"
	@printf "\n"
	@printf "$(C_BOLD)=== 项目信息 | Project Info ===$(C_RESET)\n"
	@printf "📁 项目名称 | Project: $(C_CYAN)$(PROJECT_NAME)$(C_RESET)\n"
	@printf "🏷️  版本 | Version: $(C_CYAN)$(VERSION)$(C_RESET)\n"
	@printf "\n"
	@if [ -x "$(ENV_SCRIPT)" ]; then \
		$(ENV_SCRIPT); \
	else \
		printf "$(C_YELLOW)⚠️  环境信息脚本未找到或不可执行 | Env script not found or not executable$(C_RESET)\n"; \
		printf "$(C_CYAN)💡 路径 | Path: $(ENV_SCRIPT)$(C_RESET)\n"; \
		printf "\n"; \
	fi

.PHONY: conda-info
conda-info:  ## 显示Conda虚拟环境信息 | Show Conda environment info
	@if command -v conda >/dev/null 2>&1; then \
		printf "\n"; \
		printf "$(C_BOLD)=== Conda 环境信息 | Conda Environment Info ===$(C_RESET)\n"; \
		printf "📦 Conda版本 | Version: $(C_CYAN)$$(conda --version)$(C_RESET)\n"; \
		printf "🌍 当前环境 | Current: $(C_GREEN)$$(conda info --envs | grep '\*' | awk '{print \$$1}')$(C_RESET)\n"; \
		printf "\n"; \
		printf "$(C_BOLD)可用环境 | Available Environments:$(C_RESET)\n"; \
		conda env list; \
		printf "\n"; \
		printf "$(C_BOLD)当前环境包 | Packages in Current Env:$(C_RESET)\n"; \
		conda list 2>/dev/null | head -20 || printf "  (无法显示包列表 | Unable to list packages)\n"; \
	else \
		printf "$(C_YELLOW)⚠️  Conda未安装 | Conda not installed$(C_RESET)\n"; \
	fi

.PHONY: python-info
python-info:  ## 显示Python环境信息 | Show Python environment info
	@printf "\n"
	@printf "$(C_BOLD)=== Python 环境信息 | Python Environment Info ===$(C_RESET)\n"
	@if command -v python3 >/dev/null 2>&1; then \
		printf "🐍 Python版本 | Version: $(C_CYAN)$$(python3 --version)$(C_RESET)\n"; \
		printf "📍 可执行文件路径 | Path: $(C_CYAN)$$(which python3)$(C_RESET)\n"; \
		if [ -f "requirements.txt" ]; then \
			printf "\n"; \
			printf "$(C_BOLD)项目依赖 (requirements.txt) | Project Dependencies:$(C_RESET)\n"; \
			cat requirements.txt | head -10; \
		fi; \
	elif command -v python >/dev/null 2>&1; then \
		printf "🐍 Python版本 | Version: $(C_CYAN)$$(python --version)$(C_RESET)\n"; \
		printf "📍 可执行文件路径 | Path: $(C_CYAN)$$(which python)$(C_RESET)\n"; \
	else \
		printf "$(C_YELLOW)⚠️  Python未安装 | Python not installed$(C_RESET)\n"; \
	fi
	@printf "\n"

.PHONY: node-info
node-info:  ## 显示Node.js环境信息 | Show Node.js environment info
	@printf "\n"
	@printf "$(C_BOLD)=== Node.js 环境信息 | Node.js Environment Info ===$(C_RESET)\n"
	@if command -v node >/dev/null 2>&1; then \
		printf "⬢ Node版本 | Version: $(C_CYAN)$$(node --version)$(C_RESET)\n"; \
		printf "📍 路径 | Path: $(C_CYAN)$$(which node)$(C_RESET)\n"; \
	else \
		printf "$(C_YELLOW)⚠️  Node.js未安装 | Node.js not installed$(C_RESET)\n"; \
	fi
	@if command -v npm >/dev/null 2>&1; then \
		printf "📦 npm版本 | npm Version: $(C_CYAN)$$(npm --version)$(C_RESET)\n"; \
		if [ -f "package.json" ]; then \
			printf "\n"; \
			printf "$(C_BOLD)项目信息 (package.json) | Project Info:$(C_RESET)\n"; \
			cat package.json | grep -E '"name"|"version"' | head -2; \
		fi; \
	fi
	@printf "\n"

#=============================================================================#
# 测试与质量检查 | Testing & Quality Check
#=============================================================================#
.PHONY: test
test:  ## 运行本地测试 | Run local tests
	@printf "🧪 运行本地测试 | Running local tests...\n"
	@printf "$(C_CYAN)请根据项目类型添加测试命令 | Add test commands based on project type:$(C_RESET)\n"
	@printf "  Python: python -m pytest tests/ || python test.py\n"
	@printf "  Node.js: npm test || node test.js\n"
	@printf "  Shell: bash test.sh\n"
	@printf "\n"

.PHONY: lint
lint:  ## 代码风格检查 | Code style check
	@printf "🔍 代码风格检查 | Code style checking...\n"
	@printf "$(C_CYAN)请根据项目类型添加检查命令 | Add lint commands based on project type:$(C_RESET)\n"
	@printf "  Python: flake8 . || pylint .\n"
	@printf "  Node.js: eslint . || prettier --check .\n"
	@printf "  Shell: shellcheck *.sh\n"
	@printf "\n"

.PHONY: check
check: test lint  ## 完整的质量检查 | Complete quality check
	@printf "$(C_GREEN)✅ 检查完成 | Check completed$(C_RESET)\n"

#=============================================================================#
# Git 实用工具 | Git Utilities
#=============================================================================#
.PHONY: log
log: check-git  ## 查看提交历史 (最近10条) | View commit history (last 10)
	@printf "$(C_BOLD)📜 最近提交历史 | Recent Commits:$(C_RESET)\n"
	@git log --oneline -10 --graph --decorate
	@printf "\n"
	@printf "$(C_BOLD)📊 详细统计 | Detailed Stats:$(C_RESET)\n"
	@git log --pretty=format:'%h - %an, %ar : %s' | head -5

.PHONY: log-graph
log-graph: check-git  ## 图形化查看提交历史 | View commit history graph
	@printf "$(C_BOLD)📊 提交历史图 | Commit Graph:$(C_RESET)\n"
	@git log --oneline --graph --all --decorate -20

.PHONY: branch
branch: check-git  ## 查看分支信息 | View branch info
	@printf "$(C_BOLD)🌿 分支信息 | Branch Info:$(C_RESET)\n"
	@git branch -a
	@printf "\n"
	@printf "$(C_BOLD)📍 当前分支 | Current Branch:$(C_RESET)\n"
	@git branch --show-current

.PHONY: branch-new
branch-new: check-git  ## 创建新分支 (用法: make branch-new NAME=feature/xxx) | Create new branch
	@if [ -z "$(NAME)" ]; then \
		printf "$(C_RED)❌ 错误：请提供分支名称 | Error: Please provide branch name$(C_RESET)\n"; \
		printf "$(C_YELLOW)💡 用法 | Usage: make branch-new NAME=feature/new-feature$(C_RESET)\n"; \
		exit 1; \
	fi
	@printf "🌿 创建新分支 | Creating new branch: $(NAME)\n"
	@git checkout -b $(NAME)
	@printf "$(C_GREEN)✅ 分支创建完成 | Branch created: $(NAME)$(C_RESET)\n"

.PHONY: branch-delete
branch-delete: check-git  ## 删除分支 (用法: make branch-delete NAME=xxx) | Delete branch
	@if [ -z "$(NAME)" ]; then \
		printf "$(C_RED)❌ 错误：请提供分支名称 | Error: Please provide branch name$(C_RESET)\n"; \
		printf "$(C_YELLOW)💡 用法 | Usage: make branch-delete NAME=old-branch$(C_RESET)\n"; \
		exit 1; \
	fi
	@printf "🗑️  删除分支 | Deleting branch: $(NAME)\n"
	@git branch -d $(NAME) 2>/dev/null || git branch -D $(NAME)
	@printf "$(C_GREEN)✅ 分支已删除 | Branch deleted: $(NAME)$(C_RESET)\n"

.PHONY: remote
remote: check-git  ## 查看远程仓库信息 | View remote repository info
	@printf "$(C_BOLD)🌐 远程仓库信息 | Remote Repository Info:$(C_RESET)\n"
	@git remote -v

.PHONY: stash
stash: check-git  ## 暂存当前更改 | Stash current changes
	@printf "📦 暂存更改 | Stashing changes...\n"
	@git stash push -m "WIP: $(CURRENT_DATE)"
	@printf "$(C_GREEN)✅ 更改已暂存 | Changes stashed$(C_RESET)\n"

.PHONY: stash-pop
stash-pop: check-git  ## 恢复暂存的更改 | Pop stashed changes
	@printf "📦 恢复暂存 | Popping stash...\n"
	@git stash pop
	@printf "$(C_GREEN)✅ 暂存已恢复 | Stash popped$(C_RESET)\n"

.PHONY: stash-list
stash-list: check-git  ## 查看暂存列表 | List stashes
	@printf "$(C_BOLD)📦 暂存列表 | Stash List:$(C_RESET)\n"
	@git stash list

.PHONY: clean
clean:  ## 清理未跟踪文件 (谨慎使用) | Clean untracked files (use with caution)
	@printf "$(C_YELLOW)⚠️  警告：即将清理未跟踪文件 | Warning: About to clean untracked files$(C_RESET)\n"
	@read -p "确定要继续吗？| Are you sure? [y/N] " confirm && [ $$confirm = y ] || exit 1
	@printf "🧹 清理未跟踪文件 | Cleaning untracked files...\n"
	@git clean -fd
	@printf "$(C_GREEN)✅ 清理完成 | Clean completed$(C_RESET)\n"

#=============================================================================#
# 项目初始化 | Project Initialization
#=============================================================================#
.PHONY: init-check
init-check:  ## 检查开源基础结构是否齐全 | Check if open source structure is complete
	@printf "🔍 检查基础结构 | Checking basic structure...\n"
	@miss=""; \
	for f in README.md CONTRIBUTING.md CHANGELOG.md .gitignore VERSION LICENSE; do \
		if [ -e "$$f" ]; then \
			printf "  $(C_GREEN)✅ $$f$(C_RESET)\n"; \
		else \
			printf "  $(C_RED)❌ $$f$(C_RESET)\n"; \
			miss="$$miss $$f"; \
		fi; \
	done; \
	if [ -z "$$miss" ]; then \
		printf "\n"; \
		printf "$(C_GREEN)🎉 齐备 | All files present!$(C_RESET)\n"; \
	else \
		printf "\n"; \
		printf "$(C_RED)❌ 缺失文件 | Missing files:$${miss}$(C_RESET)\n"; \
		exit 1; \
	fi

.PHONY: init
init:  ## 初始化 Git 仓库 | Initialize Git repository
	@if [ -d .git ]; then \
		printf "$(C_GREEN)✅ Git 仓库已存在 | Git repository already exists$(C_RESET)\n"; \
	else \
		printf "🔰 正在初始化 Git 仓库 | Initializing Git repository...\n"; \
		git init --quiet && \
		git checkout -b main 2>/dev/null || true && \
		printf "$(C_GREEN)✅ Git仓库初始化完成 | Git repository initialized$(C_RESET)\n" && \
		printf "📂 仓库路径 | Path: $$(pwd)\n" && \
		printf "🌿 默认分支 | Default branch: main\n" && \
		printf "🔑 远程地址 | Remote: 未配置 (稍后使用 git remote add) | Not configured\n"; \
		if [ ! -f .gitignore ]; then \
			printf "# Dependencies\nnode_modules/\n__pycache__/\n*.egg-info/\n.pytest_cache/\n.mypy_cache/\n\n# Build outputs\ndist/\nbuild/\n*.log\n\n# Environment files\n.env\n.env.local\n.env.*.local\n\n# IDE files\n.idea/\n.vscode/\n*.swp\n*.swo\n*~\n\n# OS files\n.DS_Store\nThumbs.db\n" > .gitignore; \
			printf "$(C_GREEN)✅ 已创建默认 .gitignore | Default .gitignore created$(C_RESET)\n"; \
		fi; \
		if [ -z "$$(git log --oneline -1 2>/dev/null)" ]; then \
			git add . && \
			git commit --quiet -m "🎉 初始提交：项目骨架 | Initial commit: Project skeleton" && \
			printf "$(C_GREEN)✅ 首次提交完成 | First commit completed$(C_RESET)\n"; \
		fi; \
	fi

.PHONY: init-scripts
init-scripts:  ## 初始化脚本目录和示例脚本 | Initialize scripts directory and example scripts
	@printf "📂 初始化脚本目录 | Initializing scripts directory...\n"
	@mkdir -p $(SCRIPTS_DIR)
	@printf "$(C_GREEN)✅ 脚本目录已创建 | Scripts directory created: $(SCRIPTS_DIR)$(C_RESET)\n"
	@if [ ! -f $(ENV_SCRIPT) ]; then \
		printf '#!/bin/bash\n' > $(ENV_SCRIPT); \
		printf '#============================================================================#\n' >> $(ENV_SCRIPT); \
		printf '# Environment Info Display Script\n' >> $(ENV_SCRIPT); \
		printf '#============================================================================#\n' >> $(ENV_SCRIPT); \
		printf '\n' >> $(ENV_SCRIPT); \
		printf 'echo "=== Conda Environment Info ==="\n' >> $(ENV_SCRIPT); \
		printf 'if command -v conda >/dev/null 2>&1; then\n' >> $(ENV_SCRIPT); \
		printf '    conda --version\n' >> $(ENV_SCRIPT); \
		printf '    conda env list\n' >> $(ENV_SCRIPT); \
		printf 'else\n' >> $(ENV_SCRIPT); \
		printf '    echo "Conda not installed"\n' >> $(ENV_SCRIPT); \
		printf 'fi\n' >> $(ENV_SCRIPT); \
		chmod +x $(ENV_SCRIPT); \
		printf "$(C_GREEN)✅ 示例脚本已创建 | Example script created: $(ENV_SCRIPT)$(C_RESET)\n"; \
	fi

#=============================================================================#
# 扩展命令钩子 | Extension Hooks
#=============================================================================#
-include Makefile.custom

#=============================================================================#
# 默认目标 | Default Target
#=============================================================================#
.DEFAULT_GOAL := help
