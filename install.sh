#!/bin/bash
# 醒宅家一键安装脚本 (heibai082 专用版)

echo "正在安装运行环境..."
apt update
apt install -y curl git

# 1. 安装 Node.js 18 (Debian 版)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# 2. 清理并进入目录
cd ~
rm -rf smart-reminder

echo "正在拉取代码..."
# 这里已经帮你替换好了真实的用户名
git clone https://github.com/heibai082/smart-reminder.git
cd smart-reminder

echo "正在安装程序依赖..."
npm install

echo "正在配置后台运行服务..."
cat <<EOF > /etc/systemd/system/smart-reminder.service
[Unit]
Description=Smart Reminder Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/smart-reminder
ExecStart=/usr/bin/node reminder.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 3. 启动程序
systemctl daemon-reload
systemctl enable smart-reminder
systemctl start smart-reminder

echo "------------------------------------------------"
echo "✅ 这次是真的安装成功了！"
echo "请访问: http://$(hostname -I | awk '{print $1}'):3166"
echo "------------------------------------------------"
