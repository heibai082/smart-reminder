#!/bin/bash
# 醒宅家一键安装脚本 (国内全链路加速版)

echo "Step 1: 正在切换 Debian 软件源为阿里云 (APT 加速)..."
# 将系统软件源换成阿里云，让 apt update 变快
sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list
sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list
apt update && apt install -y curl git

echo "Step 2: 正在安装 Node.js 18 (环境加速)..."
# 使用国内镜像脚本安装 Node.js 环境
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

echo "Step 3: 正在从 GitHub 代理下载代码 (Git 加速)..."
cd ~
systemctl stop smart-reminder 2>/dev/null
rm -rf smart-reminder
# 使用 GitHub 代理加速拉取你的仓库
git clone https://ghproxy.com/https://github.com/heibai082/smart-reminder.git
cd smart-reminder

echo "Step 4: 正在安装依赖 (NPM 加速)..."
# 强制使用阿里云 NPM 镜像
npm config set registry https://registry.npmmirror.com
npm install

echo "Step 5: 初始化配置..."
mkdir -p data config
if [ ! -f config/.env ]; then
  cat <<EOF > config/.env
NOTIFY_HOST=http://192.168.100.9:18088/api/v1/notify/lucky
PORT=3166
TZ=Asia/Shanghai
EOF
fi

echo "Step 6: 配置后台服务..."
# 确保 reminder.js 能稳定后台运行
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

echo "Step 7: 启动服务..."
systemctl daemon-reload
systemctl enable smart-reminder
systemctl start smart-reminder

echo "------------------------------------------------"
echo "✅ 搞定！全链路加速已开启。"
echo "访问地址: http://$(hostname -I | awk '{print $1}'):3166"
echo "------------------------------------------------"
