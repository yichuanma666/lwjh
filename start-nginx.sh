#!/bin/bash

# 启动 Nginx 服务脚本
# 使用方法: sudo bash start-nginx.sh

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}启动 Nginx 服务${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}错误: 请使用 sudo 运行此脚本${NC}"
    exit 1
fi

# 检测 Nginx 安装方式
NGINX_CONF="/etc/nginx/nginx.conf"
BT_NGINX_CONF="/www/server/nginx/conf/nginx.conf"

if [ -f "$BT_NGINX_CONF" ]; then
    echo -e "${YELLOW}检测到宝塔面板环境${NC}"
    NGINX_TYPE="bt"
    NGINX_SERVICE="bt"
elif [ -f "$NGINX_CONF" ]; then
    echo -e "${YELLOW}检测到标准 Nginx 安装${NC}"
    NGINX_TYPE="standard"
    NGINX_SERVICE="nginx"
else
    echo -e "${RED}错误: 未找到 Nginx 配置文件${NC}"
    exit 1
fi

# 检查 Nginx 是否已运行
if systemctl is-active --quiet "$NGINX_SERVICE" 2>/dev/null || pgrep -x nginx > /dev/null; then
    echo -e "${GREEN}Nginx 服务已在运行${NC}"
    
    # 重新加载配置
    echo -e "${YELLOW}重新加载 Nginx 配置...${NC}"
    if [ "$NGINX_TYPE" = "bt" ]; then
        # 宝塔面板方式
        /www/server/nginx/sbin/nginx -s reload 2>/dev/null || systemctl reload bt 2>/dev/null || echo -e "${YELLOW}使用宝塔面板命令重新加载${NC}"
    else
        # 标准方式
        systemctl reload nginx
    fi
    echo -e "${GREEN}Nginx 配置已重新加载${NC}"
else
    echo -e "${YELLOW}Nginx 服务未运行，正在启动...${NC}"
    
    # 启动 Nginx
    if [ "$NGINX_TYPE" = "bt" ]; then
        # 宝塔面板方式
        if command -v bt &> /dev/null; then
            echo -e "${YELLOW}使用宝塔面板启动 Nginx...${NC}"
            bt reload nginx 2>/dev/null || /www/server/nginx/sbin/nginx 2>/dev/null || systemctl start bt 2>/dev/null
        else
            # 直接启动 Nginx 二进制文件
            if [ -f "/www/server/nginx/sbin/nginx" ]; then
                /www/server/nginx/sbin/nginx
            else
                systemctl start bt 2>/dev/null || systemctl start nginx
            fi
        fi
    else
        # 标准方式
        systemctl start nginx
        systemctl enable nginx
    fi
    
    # 等待服务启动
    sleep 2
    
    # 检查启动状态
    if systemctl is-active --quiet "$NGINX_SERVICE" 2>/dev/null || pgrep -x nginx > /dev/null; then
        echo -e "${GREEN}Nginx 服务启动成功${NC}"
    else
        echo -e "${RED}错误: Nginx 服务启动失败${NC}"
        echo -e "${YELLOW}请检查错误日志:${NC}"
        if [ "$NGINX_TYPE" = "bt" ]; then
            echo -e "  ${YELLOW}cat /www/server/nginx/logs/error.log${NC}"
        else
            echo -e "  ${YELLOW}sudo journalctl -u nginx -n 50${NC}"
            echo -e "  ${YELLOW}sudo tail -f /var/log/nginx/error.log${NC}"
        fi
        exit 1
    fi
fi

# 检查端口监听
echo -e "${YELLOW}检查端口监听状态...${NC}"
if netstat -tlnp 2>/dev/null | grep -q ":80 " || ss -tlnp 2>/dev/null | grep -q ":80 "; then
    echo -e "${GREEN}端口 80 正在监听${NC}"
else
    echo -e "${YELLOW}警告: 端口 80 未监听，但服务可能正在启动中...${NC}"
fi

# 完成
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}操作完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e ""
echo -e "${YELLOW}下一步:${NC}"
echo -e "1. 在浏览器访问: ${GREEN}http://120.55.70.199${NC}"
echo -e "2. 查看 Nginx 状态:"
if [ "$NGINX_TYPE" = "bt" ]; then
    echo -e "   ${GREEN}ps aux | grep nginx${NC}"
    echo -e "   ${GREEN}cat /www/server/nginx/logs/error.log${NC}"
else
    echo -e "   ${GREEN}sudo systemctl status nginx${NC}"
    echo -e "   ${GREEN}sudo tail -f /var/log/nginx/error.log${NC}"
fi




