#!/bin/bash
#============================================================================#
# 环境信息展示脚本 | Environment Info Display Script
# 用法: ./show_env_info.sh 或通过 make env 调用
# Usage: ./show_env_info.sh or call via make env
#============================================================================#

# 颜色定义 | Color definitions
COLOR_RESET='\033[0m'
COLOR_RED='\033[31m'
COLOR_GREEN='\033[32m'
COLOR_YELLOW='\033[33m'
COLOR_BLUE='\033[34m'
COLOR_CYAN='\033[36m'
COLOR_BOLD='\033[1m'

#============================================================================#
# Conda 环境信息 | Conda Environment Info
#============================================================================#
show_conda_info() {
    echo ""
    echo -e "${COLOR_BOLD}=== Conda 环境信息 | Conda Environment Info ===${COLOR_RESET}"
    
    if ! command -v conda &> /dev/null; then
        echo -e "${COLOR_YELLOW}⚠️  Conda 未安装或不在 PATH 中${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}⚠️  Conda is not installed or not in PATH${COLOR_RESET}"
        return 1
    fi
    
    # Conda 版本 | Conda version
    echo -e "📦 ${COLOR_BOLD}Conda 版本 | Version:${COLOR_RESET} ${COLOR_CYAN}$(conda --version)${COLOR_RESET}"
    
    # 当前激活的环境 | Currently activated environment
    local current_env
    current_env=$(conda info --envs 2>/dev/null | grep '\*' | awk '{print $1}')
    if [ -n "$current_env" ]; then
        echo -e "🌍 ${COLOR_BOLD}当前环境 | Current Env:${COLOR_RESET} ${COLOR_GREEN}$current_env${COLOR_RESET}"
    else
        echo -e "🌍 ${COLOR_BOLD}当前环境 | Current Env:${COLOR_RESET} ${COLOR_YELLOW}(base)${COLOR_RESET}"
    fi
    
    # Conda 安装路径 | Conda installation path
    local conda_prefix
    conda_prefix=$(conda info --base 2>/dev/null)
    echo -e "📍 ${COLOR_BOLD}安装路径 | Install Path:${COLOR_RESET} ${COLOR_CYAN}$conda_prefix${COLOR_RESET}"
    
    # 所有可用环境 | All available environments
    echo ""
    echo -e "${COLOR_BOLD}📋 可用环境列表 | Available Environments:${COLOR_RESET}"
    conda env list 2>/dev/null | while read -r line; do
        if echo "$line" | grep -q '^\*'; then
            echo -e "  ${COLOR_GREEN}$line${COLOR_RESET}  ← 当前 | current"
        elif [ -n "$line" ]; then
            echo "  $line"
        fi
    done
    
    # 当前环境的包数量 | Package count in current environment
    echo ""
    echo -e "${COLOR_BOLD}📦 当前环境已安装包 | Packages in Current Env:${COLOR_RESET}"
    local pkg_count
    pkg_count=$(conda list 2>/dev/null | wc -l)
    echo "  共 $pkg_count 个包 | Total $pkg_count packages"
    
    # 显示部分重要包 | Show some important packages
    echo ""
    echo -e "${COLOR_BOLD}🔍 关键包版本 | Key Package Versions:${COLOR_RESET}"
    
    # Python 版本 | Python version
    local python_version
    python_version=$(conda list python 2>/dev/null | grep -v '^#' | tail -1 | awk '{print $2}')
    if [ -n "$python_version" ]; then
        echo "  Python: $python_version"
    fi
    
    # 其他常用包 | Other common packages
    for pkg in numpy pandas matplotlib scipy scikit-learn pytorch tensorflow; do
        local pkg_ver
        pkg_ver=$(conda list "$pkg" 2>/dev/null | grep -v '^#' | tail -1 | awk '{print $2}')
        if [ -n "$pkg_ver" ]; then
            echo "  $pkg: $pkg_ver"
        fi
    done
}

#============================================================================#
# Python 环境信息 | Python Environment Info
#============================================================================#
show_python_info() {
    echo ""
    echo -e "${COLOR_BOLD}=== Python 环境信息 | Python Environment Info ===${COLOR_RESET}"
    
    local python_cmd=""
    if command -v python3 &> /dev/null; then
        python_cmd="python3"
    elif command -v python &> /dev/null; then
        python_cmd="python"
    fi
    
    if [ -z "$python_cmd" ]; then
        echo -e "${COLOR_YELLOW}⚠️  Python 未安装${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}⚠️  Python is not installed${COLOR_RESET}"
        return 1
    fi
    
    echo -e "🐍 ${COLOR_BOLD}Python 版本 | Version:${COLOR_RESET} ${COLOR_CYAN}$($python_cmd --version)${COLOR_RESET}"
    echo -e "📍 ${COLOR_BOLD}可执行文件路径 | Executable Path:${COLOR_RESET} ${COLOR_CYAN}$(which $python_cmd)${COLOR_RESET}"
    
    # pip 版本 | pip version
    if command -v pip &> /dev/null; then
        echo -e "📦 ${COLOR_BOLD}pip 版本 | pip Version:${COLOR_RESET} ${COLOR_CYAN}$(pip --version | awk '{print $2}')${COLOR_RESET}"
    fi
    
    # 虚拟环境信息 | Virtual environment info
    local venv_path
    venv_path=$($python_cmd -c "import sys; print(sys.prefix)" 2>/dev/null)
    if [ -n "$venv_path" ]; then
        echo -e "🌐 ${COLOR_BOLD}Python 前缀 | Python Prefix:${COLOR_RESET} ${COLOR_CYAN}$venv_path${COLOR_RESET}"
    fi
    
    # 检查是否在虚拟环境中 | Check if in virtual environment
    if [ -n "$VIRTUAL_ENV" ]; then
        echo -e "✅ ${COLOR_GREEN}当前在虚拟环境中 | Currently in virtual environment: $VIRTUAL_ENV${COLOR_RESET}"
    fi
}

#============================================================================#
# 系统环境变量 | System Environment Variables
#============================================================================#
show_env_vars() {
    echo ""
    echo -e "${COLOR_BOLD}=== 关键环境变量 | Key Environment Variables ===${COLOR_RESET}"
    
    # PATH 摘要 | PATH summary
    echo -e "📂 ${COLOR_BOLD}PATH 路径数量 | PATH entries:${COLOR_RESET} $(echo "$PATH" | tr ':' '\n' | wc -l)"
    
    # 关键变量 | Key variables
    local key_vars=("HOME" "USER" "SHELL" "LANG" "EDITOR")
    for var in "${key_vars[@]}"; do
        local value
        value=$(printenv "$var" 2>/dev/null)
        if [ -n "$value" ]; then
            echo "  $var: $value"
        fi
    done
    
    # Git 相关变量 | Git related variables
    if [ -n "$GIT_SSH" ]; then
        echo "  GIT_SSH: $GIT_SSH"
    fi
}

#============================================================================#
# 主函数 | Main Function
#============================================================================#
main() {
    # 根据参数显示特定信息或全部信息
    # Display specific or all info based on arguments
    case "${1:-all}" in
        conda)
            show_conda_info
            ;;
        python)
            show_python_info
            ;;
        env)
            show_env_vars
            ;;
        all|*)
            show_conda_info
            show_python_info
            show_env_vars
            ;;
    esac
    
    echo ""
}

# 执行主函数 | Execute main function
main "$@"
