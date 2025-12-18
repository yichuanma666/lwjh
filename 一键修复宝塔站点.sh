#!/bin/bash

# 一键修复宝塔面板"没有找到站点"问题
# 使用方法: sudo bash 一键修复宝塔站点.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}一键修复宝塔面板站点配置${NC}"
echo -e "${GREEN}========================================${NC}"

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}请使用 sudo 运行${NC}"
    exit 1
fi

CONFIG_FILE="/www/server/panel/vhost/nginx/qk-paper-search.conf"
NGINX_BIN="/www/server/nginx/sbin/nginx"

# 创建/更新配置文件（添加 default_server）
echo -e "${YELLOW}[1/4] 创建站点配置（设置为默认站点）...${NC}"
mkdir -p /www/server/panel/vhost/nginx

cat > "$CONFIG_FILE" << 'EOF'
server {
    listen 80 default_server;
    server_name _;

    # 增加缓冲区大小（解决 400 错误）
    client_header_buffer_size 64k;
    large_client_header_buffers 4 64k;
    client_body_buffer_size 128k;

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

echo -e "${GREEN}配置文件已创建（设置为 default_server）${NC}"

# 禁用默认站点
echo -e "${YELLOW}[2/4] 禁用可能冲突的默认站点...${NC}"
for site in default.conf 0.default.conf phpmyadmin.conf; do
    if [ -f "/www/server/panel/vhost/nginx/$site" ]; then
        mv "/www/server/panel/vhost/nginx/$site" "/www/server/panel/vhost/nginx/${site}.bak" 2>/dev/null && \
        echo -e "${GREEN}已禁用: $site${NC}" || true
    fi
done

# 测试配置
echo -e "${YELLOW}[3/4] 测试 Nginx 配置...${NC}"
if $NGINX_BIN -t; then
    echo -e "${GREEN}配置测试通过${NC}"
else
    echo -e "${RED}配置测试失败${NC}"
    exit 1
fi

# 重新加载
echo -e "${YELLOW}[4/4] 重新加载 Nginx...${NC}"
$NGINX_BIN -s reload 2>/dev/null || {
    pkill nginx 2>/dev/null
    sleep 1
    $NGINX_BIN
}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}修复完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e ""
echo -e "${YELLOW}现在可以访问: ${GREEN}http://120.55.70.199${NC}"
echo -e ""
echo -e "${YELLOW}如果还有问题:${NC}"
echo -e "  - 查看日志: tail -f /www/server/nginx/logs/error.log"
echo -e "  - 检查应用: systemctl status qk-paper-search"

