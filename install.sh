#!/bin/bash
# 醒宅家一键安装脚本 (通用加速分享版)

# 检查权限：如果不是 root 用户则提示
if [ "$(id -u)" != "0" ]; then
    echo "请使用 root 用户运行此脚本，或在命令前加 sudo"
    exit 1
fi

echo "Step 1: 正在更新系统并安装基础工具..."
apt update && apt install -y curl git

# --- 1. Node.js 环境安装 ---
echo "Step 2: 正在安装 Node.js 18 运行环境..."
# 使用 NodeSource 官方安装脚本
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# --- 2. 清理旧文件并克隆代码 ---
echo "Step 3: 正在拉取代码..."
cd ~
systemctl stop smart-reminder 2>/dev/null
rm -rf smart-reminder

# 注意：这里请把 heibai082 换成你最终确定的 GitHub 用户名
git clone https://github.com/heibai082/smart-reminder.git
cd smart-reminder

# --- 3. NPM 国内镜像加速 (核心加速点) ---
echo "Step 4: 正在通过国内镜像加速安装依赖..."
# 这一步是通用的，所有人在中国访问都会变快
npm config set registry https://registry.npmmirror.com
npm install

# --- 4. 初始化配置与数据目录 ---
echo "Step 5: 正在初始化环境..."
mkdir -p data config
# 创建默认配置文件
if [ ! -f config/.env ]; then
  cat <<EOF > config/.env
NOTIFY_HOST=http://192.168.100.9:18088/api/v1/notify/lucky
PORT=3166
TZ=Asia/Shanghai
EOF
fi

# --- 5. 配置 Systemd 后台运行 ---
echo "Step 6: 正在配置后台服务..."
# 确保程序在后台运行并能开机自启
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

# --- 6. 启动服务 ---
echo "Step 7: 启动程序..."
systemctl daemon-reload
systemctl enable smart-reminder
systemctl start smart-reminder

echo "------------------------------------------------"
echo "✅ 安装成功！此脚本为通用加速版，可分享给好友。"
echo "访问地址: http://$(hostname -I | awk '{print $1}'):3166"
echo "------------------------------------------------"
