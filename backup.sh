mkdir -p ./vim_config
echo "开始备份中............."
cp ~/.vimrc ./vim_config/
cp -r ~/.vim ./vim_config/
tar -czvf vim_config.tar.gz vim_config
rm -rf vim_config
echo "finished!!!!"
