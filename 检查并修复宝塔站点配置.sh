#!/bin/bash

# 全面检查并修复宝塔面板站点配置
# 使用方法: sudo bash 检查并修复宝塔站点配置.sh

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}全面检查并修复宝塔面板站点配置${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}错误: 请使用 sudo 运行此脚本${NC}"
    exit 1
fi

# 配置变量
SERVICE_NAME="qk-paper-search"
BT_VHOST_DIR="/www/server/panel/vhost/nginx"
BT_NGINX_CONF="/www/server/nginx/conf/nginx.conf"
BT_NGINX_BIN="/www/server/nginx/sbin/nginx"
CONFIG_FILE="$BT_VHOST_DIR/${SERVICE_NAME}.conf"

# 步骤 1: 检查是否是宝塔环境
echo -e "${YELLOW}[1/8] 检查环境...${NC}"
if [ ! -f "$BT_NGINX_CONF" ]; then
    echo -e "${RED}错误: 未检测到宝塔面板环境${NC}"
    exit 1
fi
echo -e "${GREEN}检测到宝塔面板环境${NC}"

# 步骤 2: 创建站点配置文件
echo -e "${YELLOW}[2/8] 创建/检查站点配置文件...${NC}"
mkdir -p "$BT_VHOST_DIR"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}配置文件不存在，正在创建...${NC}"
    cat > "$CONFIG_FILE" << 'EOF'
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
    echo -e "${GREEN}配置文件已创建${NC}"
else
    echo -e "${GREEN}配置文件已存在${NC}"
    # 修正日志路径
    sed -i 's|/var/log/nginx/|/www/server/nginx/logs/|g' "$CONFIG_FILE"
    # 确保 server_name 正确
    sed -i 's/server_name.*;/server_name _;/' "$CONFIG_FILE"
    echo -e "${GREEN}配置文件已检查和修正${NC}"
fi

# 步骤 3: 检查 Nginx 主配置是否包含 vhost
echo -e "${YELLOW}[3/8] 检查 Nginx 主配置...${NC}"
if ! grep -q "include.*vhost.*nginx.*\*.conf" "$BT_NGINX_CONF"; then
    echo -e "${YELLOW}主配置未包含 vhost 目录，正在添加...${NC}"
    
    # 备份主配置
    cp "$BT_NGINX_CONF" "$BT_NGINX_CONF.bak.$(date +%Y%m%d_%H%M%S)"
    
    # 在 http 块末尾添加 include（在最后一个 } 之前）
    if grep -q "^}" "$BT_NGINX_CONF"; then
        # 在最后一个 } 之前添加
        sed -i '/^}/i\    include /www/server/panel/vhost/nginx/*.conf;' "$BT_NGINX_CONF"
        echo -e "${GREEN}已添加 vhost include 到主配置${NC}"
    else
        echo -e "${YELLOW}警告: 无法自动添加 include，请手动检查主配置文件${NC}"
    fi
else
    echo -e "${GREEN}主配置已包含 vhost 目录${NC}"
fi

# 步骤 4: 检查并禁用默认站点
echo -e "${YELLOW}[4/8] 检查默认站点...${NC}"
DEFAULT_SITES=(
    "/www/server/panel/vhost/nginx/default.conf"
    "/www/server/panel/vhost/nginx/0.default.conf"
    "/www/server/panel/vhost/nginx/phpmyadmin.conf"
)

for site in "${DEFAULT_SITES[@]}"; do
    if [ -f "$site" ]; then
        echo -e "${YELLOW}发现默认站点: $site${NC}"
        # 检查是否也在监听 80 端口
        if grep -q "listen 80" "$site"; then
            echo -e "${YELLOW}默认站点也在监听 80 端口，可能会冲突${NC}"
            echo -e "${YELLOW}建议：在宝塔面板中禁用或删除默认站点${NC}"
        fi
    fi
done

# 步骤 5: 检查配置文件语法
echo -e "${YELLOW}[5/8] 检查配置文件语法...${NC}"
if $BT_NGINX_BIN -t 2>&1 | grep -q "syntax is ok"; then
    echo -e "${GREEN}配置文件语法正确${NC}"
else
    echo -e "${RED}错误: 配置文件语法有误${NC}"
    $BT_NGINX_BIN -t
    exit 1
fi

# 步骤 6: 检查配置是否被加载
echo -e "${YELLOW}[6/8] 检查配置是否被加载...${NC}"
if $BT_NGINX_BIN -T 2>/dev/null | grep -q "qk-paper-search"; then
    echo -e "${GREEN}配置已被加载${NC}"
else
    echo -e "${YELLOW}警告: 配置可能未被加载${NC}"
    echo -e "${YELLOW}正在检查 Nginx 加载的配置...${NC}"
    $BT_NGINX_BIN -T 2>/dev/null | grep -A 5 "server_name" || echo -e "${YELLOW}未找到 server_name 配置${NC}"
fi

# 步骤 7: 重新加载 Nginx
echo -e "${YELLOW}[7/8] 重新加载 Nginx...${NC}"
if pgrep -x nginx > /dev/null; then
    if $BT_NGINX_BIN -s reload 2>/dev/null; then
        echo -e "${GREEN}Nginx 已重新加载${NC}"
    else
        echo -e "${YELLOW}尝试重启 Nginx...${NC}"
        pkill nginx 2>/dev/null || true
        sleep 1
        $BT_NGINX_BIN
        sleep 2
        if pgrep -x nginx > /dev/null; then
            echo -e "${GREEN}Nginx 已重启${NC}"
        else
            echo -e "${RED}错误: Nginx 重启失败${NC}"
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}Nginx 未运行，正在启动...${NC}"
    $BT_NGINX_BIN
    sleep 2
    if pgrep -x nginx > /dev/null; then
        echo -e "${GREEN}Nginx 已启动${NC}"
    else
        echo -e "${RED}错误: Nginx 启动失败${NC}"
        exit 1
    fi
fi

# 步骤 8: 检查应用服务
echo -e "${YELLOW}[8/8] 检查应用服务...${NC}"
if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
    echo -e "${GREEN}应用服务正在运行${NC}"
else
    echo -e "${YELLOW}应用服务未运行，尝试启动...${NC}"
    systemctl start "$SERVICE_NAME" 2>/dev/null || echo -e "${YELLOW}警告: 无法启动应用服务，请手动检查${NC}"
fi

# 显示检查结果
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}检查完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e ""
echo -e "${YELLOW}配置信息:${NC}"
echo -e "  - 站点配置: ${GREEN}$CONFIG_FILE${NC}"
echo -e "  - Nginx 主配置: ${GREEN}$BT_NGINX_CONF${NC}"
echo -e ""
echo -e "${YELLOW}诊断信息:${NC}"
echo -e "  - Nginx 进程: $(pgrep -x nginx | wc -l) 个进程"
echo -e "  - 端口 80 监听: $(netstat -tlnp 2>/dev/null | grep -c ':80 ' || echo '0') 个"
echo -e "  - 端口 8000 监听: $(netstat -tlnp 2>/dev/null | grep -c ':8000 ' || echo '0') 个"
echo -e ""
echo -e "${YELLOW}下一步操作:${NC}"
echo -e "1. 在浏览器访问: ${GREEN}http://120.55.70.199${NC}"
echo -e "2. 如果仍显示'没有找到站点'，请检查:"
echo -e "   - 查看所有站点配置: ${GREEN}ls -la $BT_VHOST_DIR/${NC}"
echo -e "   - 查看 Nginx 加载的配置: ${GREEN}$BT_NGINX_BIN -T | grep -A 10 'listen 80'${NC}"
echo -e "   - 查看错误日志: ${GREEN}tail -f /www/server/nginx/logs/error.log${NC}"
echo -e ""
echo -e "${YELLOW}宝塔面板操作:${NC}"
echo -e "   - 登录宝塔面板 → 网站 → 查看所有站点"
echo -e "   - 如果有默认站点也在监听 80 端口，需要删除或禁用"




