#!/bin/bash

# 宝塔面板 Nginx 站点配置修复脚本
# 使用方法: sudo bash fix-bt-nginx-site.sh

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}修复宝塔面板 Nginx 站点配置${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}错误: 请使用 sudo 运行此脚本${NC}"
    exit 1
fi

# 宝塔面板路径
BT_NGINX_CONF="/www/server/nginx/conf/nginx.conf"
BT_VHOST_DIR="/www/server/panel/vhost/nginx"
BT_NGINX_BIN="/www/server/nginx/sbin/nginx"
SERVICE_NAME="qk-paper-search"

# 检查是否是宝塔环境
if [ ! -f "$BT_NGINX_CONF" ]; then
    echo -e "${RED}错误: 未检测到宝塔面板环境${NC}"
    echo -e "${YELLOW}请使用 fix-nginx-site.sh 脚本${NC}"
    exit 1
fi

echo -e "${GREEN}检测到宝塔面板环境${NC}"

# 步骤 1: 检查站点配置文件
echo -e "${YELLOW}[1/6] 检查站点配置文件...${NC}"

# 查找所有可能的站点配置文件位置
SITE_CONFIGS=(
    "/etc/nginx/sites-available/$SERVICE_NAME"
    "/www/server/panel/vhost/nginx/$SERVICE_NAME.conf"
    "$BT_VHOST_DIR/${SERVICE_NAME}.conf"
)

SITE_CONFIG=""
for config in "${SITE_CONFIGS[@]}"; do
    if [ -f "$config" ]; then
        SITE_CONFIG="$config"
        echo -e "${GREEN}找到配置文件: $config${NC}"
        break
    fi
done

if [ -z "$SITE_CONFIG" ]; then
    echo -e "${YELLOW}未找到现有配置文件，检查标准位置...${NC}"
    
    # 检查标准位置
    if [ -f "/etc/nginx/sites-available/$SERVICE_NAME" ]; then
        SITE_CONFIG="/etc/nginx/sites-available/$SERVICE_NAME"
    else
        echo -e "${RED}错误: 未找到站点配置文件${NC}"
        echo -e "${YELLOW}请先运行部署脚本或手动创建配置文件${NC}"
        exit 1
    fi
fi

# 步骤 2: 在宝塔 vhost 目录创建配置
echo -e "${YELLOW}[2/6] 创建宝塔面板站点配置...${NC}"

# 确保目录存在
mkdir -p "$BT_VHOST_DIR"

# 读取配置文件内容并修改 server_name
if [ -f "$SITE_CONFIG" ]; then
    # 备份原配置
    if [ -f "$BT_VHOST_DIR/${SERVICE_NAME}.conf" ]; then
        cp "$BT_VHOST_DIR/${SERVICE_NAME}.conf" "$BT_VHOST_DIR/${SERVICE_NAME}.conf.bak.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # 复制配置文件到宝塔 vhost 目录
    cp "$SITE_CONFIG" "$BT_VHOST_DIR/${SERVICE_NAME}.conf"
    
    # 修改 server_name 为匹配所有
    sed -i 's/server_name.*;/server_name _;/' "$BT_VHOST_DIR/${SERVICE_NAME}.conf"
    
    # 修改日志路径为宝塔路径
    sed -i 's|/var/log/nginx/|/www/server/nginx/logs/|g' "$BT_VHOST_DIR/${SERVICE_NAME}.conf"
    
    echo -e "${GREEN}配置文件已创建: $BT_VHOST_DIR/${SERVICE_NAME}.conf${NC}"
    echo -e "${GREEN}日志路径已更新为宝塔路径${NC}"
else
    # 如果源文件不存在，创建新配置（使用宝塔日志路径）
    cat > "$BT_VHOST_DIR/${SERVICE_NAME}.conf" << 'EOF'
server {
    listen 80;
    server_name _;

    client_max_body_size 100M;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }

    location /static {
        alias /opt/qk/static;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    access_log /www/server/nginx/logs/qk-paper-search-access.log;
    error_log /www/server/nginx/logs/qk-paper-search-error.log;
}
EOF
    echo -e "${GREEN}已创建新的配置文件（使用宝塔日志路径）${NC}"
fi

# 步骤 3: 检查 Nginx 主配置是否包含 vhost
echo -e "${YELLOW}[3/6] 检查 Nginx 主配置...${NC}"

if ! grep -q "include.*vhost.*nginx.*\*.conf" "$BT_NGINX_CONF"; then
    echo -e "${YELLOW}Nginx 主配置中未找到 vhost 包含，尝试添加...${NC}"
    
    # 备份主配置
    cp "$BT_NGINX_CONF" "$BT_NGINX_CONF.bak.$(date +%Y%m%d_%H%M%S)"
    
    # 在 http 块末尾添加 include
    if grep -q "^}" "$BT_NGINX_CONF"; then
        # 在最后一个 } 之前添加
        sed -i '/^}/i\    include /www/server/panel/vhost/nginx/*.conf;' "$BT_NGINX_CONF"
    else
        echo -e "${YELLOW}警告: 无法自动添加 include，请手动检查主配置文件${NC}"
    fi
else
    echo -e "${GREEN}Nginx 主配置已包含 vhost${NC}"
fi

# 步骤 4: 测试 Nginx 配置
echo -e "${YELLOW}[4/6] 测试 Nginx 配置...${NC}"

if $BT_NGINX_BIN -t; then
    echo -e "${GREEN}Nginx 配置测试通过${NC}"
else
    echo -e "${RED}错误: Nginx 配置测试失败${NC}"
    echo -e "${YELLOW}请检查配置文件: $BT_VHOST_DIR/${SERVICE_NAME}.conf${NC}"
    exit 1
fi

# 步骤 5: 重新加载 Nginx
echo -e "${YELLOW}[5/6] 重新加载 Nginx...${NC}"

if pgrep -x nginx > /dev/null; then
    # Nginx 正在运行，重新加载
    $BT_NGINX_BIN -s reload 2>/dev/null || bt reload nginx 2>/dev/null || {
        echo -e "${YELLOW}尝试重启 Nginx...${NC}"
        pkill nginx 2>/dev/null || true
        sleep 1
        $BT_NGINX_BIN
    }
    echo -e "${GREEN}Nginx 已重新加载${NC}"
else
    # Nginx 未运行，启动
    echo -e "${YELLOW}Nginx 未运行，正在启动...${NC}"
    $BT_NGINX_BIN || bt reload nginx 2>/dev/null
    sleep 2
    if pgrep -x nginx > /dev/null; then
        echo -e "${GREEN}Nginx 已启动${NC}"
    else
        echo -e "${RED}错误: Nginx 启动失败${NC}"
        exit 1
    fi
fi

# 步骤 6: 确保应用服务运行
echo -e "${YELLOW}[6/6] 检查应用服务...${NC}"

if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
    echo -e "${GREEN}应用服务正在运行${NC}"
else
    echo -e "${YELLOW}应用服务未运行，尝试启动...${NC}"
    systemctl start "$SERVICE_NAME" 2>/dev/null || echo -e "${YELLOW}警告: 无法启动应用服务，请手动检查${NC}"
fi

# 完成
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}修复完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e ""
echo -e "${YELLOW}配置信息:${NC}"
echo -e "  - 站点配置: ${GREEN}$BT_VHOST_DIR/${SERVICE_NAME}.conf${NC}"
echo -e "  - Nginx 主配置: ${GREEN}$BT_NGINX_CONF${NC}"
echo -e ""
echo -e "${YELLOW}下一步:${NC}"
echo -e "1. 在浏览器访问: ${GREEN}http://120.55.70.199${NC}"
echo -e "2. 如果仍无法访问，请检查:"
echo -e "   - 查看 Nginx 错误日志: ${GREEN}tail -f /www/server/nginx/logs/error.log${NC}"
echo -e "   - 查看站点配置: ${GREEN}cat $BT_VHOST_DIR/${SERVICE_NAME}.conf${NC}"
echo -e "   - 检查应用服务: ${GREEN}systemctl status $SERVICE_NAME${NC}"
echo -e ""
echo -e "${YELLOW}宝塔面板操作:${NC}"
echo -e "   - 登录宝塔面板 → 网站 → 查看站点列表"
echo -e "   - 或手动在宝塔面板中添加站点"

