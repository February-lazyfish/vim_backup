#!/bin/bash

# 安装依赖
if [ -f /etc/debian_version ]; then
    sudo apt update sudo apt install -y git curl build-essential cmake python3-dev
elif [ -f /etc/redhat-release ]; then
    sudo yum install -y git curl cmake python3-devel
fi
#是否有用看最后的配置结果
#sudo git clone https://github.com/chxuan/vimplus.git ~/vimplus-master
# 合包操作
cat vim_config.tar.gz.part.a* > vim_config.tar.gz
# 恢复配置
sudo tar -xzvf vim_config.tar.gz 
sudo cp ./vim_config/.vimrc ~
sudo cp -r ./vim_config/.vim ~

# 当前用户和用户组
USER=$(whoami)
GROUP=$(id -gn "$USER")

# 检查 .vimrc 文件所有者是否为 root
if [ -f "$HOME/.vimrc" ]; then
    OWNER=$(stat -c %U "$HOME/.vimrc")
    if [ "$OWNER" == "root" ]; then
        echo "Changing owner of ~/.vimrc from root to $USER"
        sudo chown "$USER:$GROUP" "$HOME/.vimrc"
    fi
fi

# 递归检查 ~/.vim 目录下所有文件和目录
if [ -d "$HOME/.vim" ]; then
    find "$HOME/.vim" -exec stat --format '%U %n' {} \; | while read OWNER FILE; do
        if [ "$OWNER" == "root" ]; then
            echo "Changing owner of $FILE from root to $USER"
            sudo chown "$USER:$GROUP" "$FILE"
        fi
    done
fi

# 安装插件管理器
# 检查是否存在 plug.vim
if [[ ! -f ~/.vim/autoload/plug.vim ]]; then
  echo "🔌 未检测到 plug.vim，正在下载 vim-plug..."
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
else
  echo "🔌 plug.vim 已存在，跳过下载"
fi


# 安装插件
vim +PlugInstall +qall

# 编译YCM
if [ -d ~/.vim/plugged/YouCompleteMe ]; then
    cd ~/.vim/plugged/YouCompleteMe
    echo "⚙️ 正在编译 YouCompleteMe..."
    python3 install.py --all || {
        echo "YCM 编译失败，请检查 Python 依赖和 CMake 安装。"
        exit 1
    }
fi
# 做好vim 和 sudovim的同步操作
sudo cp ~/.vimrc /root/
sudo cp -r ~/.vim /root/

echo "Vim配置恢复完成！"
