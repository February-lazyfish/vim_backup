#!/bin/bash
# ubuntu_init.sh - Ubuntu 系统初始化及 Vim 环境配置脚本

# 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
  echo "请使用 sudo 或以 root 用户运行此脚本"
  exit 1
fi

# 设置颜色变量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color


## 2. 系统更新与基础配置
message "开始系统更新和基础配置..."

# 更新软件源
apt update -y || error "更新软件源失败"
apt upgrade -y || warning "系统升级失败，但将继续"

# 安装基础工具
message "安装基础工具..."
apt install -y \
  git curl wget zip unzip \
  build-essential cmake \
  python3 python3-pip python3-venv \
  htop tree tmux clangd\
  clang ssh vim\
  net-tools openssh-server  || error "安装基础工具失败"

# 设置时区
timedatectl set-timezone Asia/Shanghai

## 3. 安装并配置 Vim
message "配置 Vim 开发环境..."

echo "当前的vim版本是："
vim --version | head -n 1
# 🧠 获取当前 Vim 版本号（如：9.1）
current_version=$(vim --version 2>/dev/null | head -n 1 | grep -oP 'Vi IMproved \K[0-9]+\.[0-9]+' || echo "0.0")
# 🎯 与 9.0 版本进行比较（只比较主版本和次版本）
required_major=9
required_minor=0
current_major=$(echo $current_version | cut -d. -f1)
current_minor=$(echo $current_version | cut -d. -f2)
if [ "$current_major" -gt "$required_major" ] || { [ "$current_major" -eq "$required_major" ] && [ "$current_minor" -ge "$required_minor" ]; }; then
    echo "✅ 已安装 Vim 版本 $current_version（>= 9.0），跳过安装。"
    echo "初始化完成"
    exit 0
fi
echo "🔧 当前 Vim 版本 $current_version < 9.0，开始安装 Vim 9.1..."
#-------------------------第一种方法---------------------
#add-apt-repository ppa:jonathonf/vim -y
#apt update
#apt install -y vim-gtk || error "安装 Vim 失败"
#echo "初始化完成"
#-------------------------------------------------------
#--------------------------源码编译-——-----------------

set -euo pipefail

echo "🔍 检查已有 Vim 版本..."
if command -v vim >/dev/null 2>&1; then
    current_version=$(vim --version | head -n 1)
    echo "当前 Vim 版本：$current_version"
fi

echo "📦 卸载系统旧版 Vim..."
sudo apt remove -y vim vim-runtime gvim vim-tiny vim-common vim-gui-common || true

echo "🔧 安装构建依赖..."
sudo apt update
sudo apt install -y git make gcc \
    libncurses5-dev libgtk-3-dev libx11-dev libxpm-dev libxt-dev \
    python3-dev lua5.4 liblua5.4-dev libperl-dev ruby-dev cscope

echo "🌐 克隆 Vim 最新源码..."
cd /tmp
rm -rf vim
git clone https://github.com/vim/vim.git
cd vim

echo "📌 当前 Vim Git 最新提交："
git log -1 --oneline

echo "⚙️ 配置编译选项..."
./configure \
  --with-features=huge \
  --enable-multibyte \
  --enable-python3interp=yes \
  --enable-luainterp=yes \
  --enable-perlinterp=yes \
  --enable-rubyinterp=yes \
  --enable-gui=gtk3 \
  --enable-cscope \
  --enable-terminal \
  --enable-clipboard \
  --prefix=/usr/local

echo "🔨 编译并安装 Vim（使用 CPU 核心数: $(nproc)）..."
make -j$(nproc)
sudo make install

echo "🔗 设置为默认 vim..."
sudo ln -sf /usr/local/bin/vim /usr/bin/vim

echo "✅ Vim 最新版安装完成！当前版本："
vim --version | head -n 1
