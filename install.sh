#!/bin/bash
# 醒宅家一键安装脚本

# 1. 自动安装 Node.js 环境
echo "正在安装运行环境..."
sudo apt update && sudo apt install -y curl git
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 2. 拉取你的代码 (记得把下面的 '你的用户名' 换掉)
cd ~
git clone https://github.com/你的用户名/smart-reminder.git
cd smart-reminder

# 3. 安装程序依赖
echo "正在安装程序依赖..."
npm install

# 4. 准备配置文件
mkdir -p data config
# 如果没有 .env 就创建一个默认的
if [ ! -f config/.env ]; then
  echo "PORT=3166" > config/.env
  echo "NOTIFY_HOST=http://192.168.100.9:18088/api/v1/notify/lucky" >> config/.env
  echo "TZ=Asia/Shanghai" >> config/.env
fi

# 5. 设置开机自启 (Systemd)
echo "正在配置后台运行服务..."
sudo tee /etc/systemd/system/smart-reminder.service > /dev/null <<EOF
[Unit]
Description=Smart Reminder Service
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$(pwd)
ExecStart=/usr/bin/node reminder.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 6. 启动程序
sudo systemctl daemon-reload
sudo systemctl enable smart-reminder
sudo systemctl start smart-reminder

echo "------------------------------------------------"
echo "🎉 安装成功！"
echo "请访问: http://$(hostname -I | awk '{print $1}'):3166"
echo "------------------------------------------------"
