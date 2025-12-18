#!/bin/bash

# 一键修复 Nginx "没有找到站点" 错误
# 使用方法: sudo bash fix-nginx-site.sh

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}开始修复 Nginx 配置...${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}错误: 请使用 sudo 运行此脚本${NC}"
    exit 1
fi

# 配置变量
SERVICE_NAME="qk-paper-search"
NGINX_AVAILABLE="/etc/nginx/sites-available/$SERVICE_NAME"
NGINX_ENABLED="/etc/nginx/sites-enabled/$SERVICE_NAME"
NGINX_DEFAULT="/etc/nginx/sites-enabled/default"

# 步骤 1: 检查 Nginx 是否安装
echo -e "${YELLOW}[1/7] 检查 Nginx 是否安装...${NC}"
if ! command -v nginx &> /dev/null; then
    echo -e "${YELLOW}Nginx 未安装，正在安装...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y nginx
    elif command -v yum &> /dev/null; then
        yum install -y nginx
    else
        echo -e "${RED}错误: 无法自动安装 Nginx，请手动安装${NC}"
        exit 1
    fi
    echo -e "${GREEN}Nginx 安装完成${NC}"
else
    echo -e "${GREEN}Nginx 已安装${NC}"
fi

# 步骤 2: 检查配置文件是否存在
echo -e "${YELLOW}[2/7] 检查配置文件...${NC}"
if [ ! -f "$NGINX_AVAILABLE" ]; then
    echo -e "${RED}错误: 配置文件不存在: $NGINX_AVAILABLE${NC}"
    echo -e "${YELLOW}请先运行部署脚本或手动创建配置文件${NC}"
    exit 1
fi
echo -e "${GREEN}配置文件存在${NC}"

# 步骤 3: 创建目录（如果不存在）
echo -e "${YELLOW}[3/7] 检查并创建目录...${NC}"
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled
echo -e "${GREEN}目录检查完成${NC}"

# 步骤 4: 修改 server_name
echo -e "${YELLOW}[4/7] 修改 server_name 配置...${NC}"
if grep -q "server_name" "$NGINX_AVAILABLE"; then
    # 备份原配置
    cp "$NGINX_AVAILABLE" "$NGINX_AVAILABLE.bak.$(date +%Y%m%d_%H%M%S)"
    
    # 修改 server_name 为匹配所有
    sed -i 's/server_name.*;/server_name _;/' "$NGINX_AVAILABLE"
    echo -e "${GREEN}server_name 已修改为 _ (匹配所有)${NC}"
else
    echo -e "${YELLOW}警告: 未找到 server_name 配置${NC}"
fi

# 步骤 5: 创建软链接
echo -e "${YELLOW}[5/7] 创建站点软链接...${NC}"
if [ -L "$NGINX_ENABLED" ]; then
    echo -e "${YELLOW}软链接已存在，更新中...${NC}"
    rm -f "$NGINX_ENABLED"
fi
ln -sf "$NGINX_AVAILABLE" "$NGINX_ENABLED"
echo -e "${GREEN}软链接已创建${NC}"

# 步骤 6: 禁用默认站点（如果存在）
echo -e "${YELLOW}[6/7] 检查默认站点...${NC}"
if [ -f "$NGINX_DEFAULT" ] || [ -L "$NGINX_DEFAULT" ]; then
    mv "$NGINX_DEFAULT" "${NGINX_DEFAULT}.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    echo -e "${GREEN}默认站点已禁用${NC}"
else
    echo -e "${YELLOW}默认站点不存在，跳过${NC}"
fi

# 步骤 7: 测试并重新加载 Nginx
echo -e "${YELLOW}[7/7] 测试并重新加载 Nginx...${NC}"

# 检测是否是宝塔面板环境
BT_NGINX_CONF="/www/server/nginx/conf/nginx.conf"
if [ -f "$BT_NGINX_CONF" ]; then
    echo -e "${YELLOW}检测到宝塔面板环境${NC}"
    NGINX_BIN="/www/server/nginx/sbin/nginx"
    NGINX_TEST_CMD="$NGINX_BIN -t"
    NGINX_RELOAD_CMD="$NGINX_BIN -s reload"
else
    NGINX_TEST_CMD="nginx -t"
    NGINX_RELOAD_CMD="systemctl reload nginx"
fi

# 测试配置
if $NGINX_TEST_CMD; then
    # 检查 Nginx 是否在运行
    if pgrep -x nginx > /dev/null || systemctl is-active --quiet nginx 2>/dev/null || systemctl is-active --quiet bt 2>/dev/null; then
        # 服务正在运行，重新加载配置
        if [ -f "$BT_NGINX_CONF" ]; then
            # 宝塔环境
            $NGINX_RELOAD_CMD 2>/dev/null || bt reload nginx 2>/dev/null || echo -e "${YELLOW}请手动通过宝塔面板重启 Nginx${NC}"
        else
            # 标准环境
            systemctl reload nginx 2>/dev/null || echo -e "${YELLOW}警告: 无法重新加载，但配置已保存${NC}"
        fi
        echo -e "${GREEN}Nginx 配置已重新加载${NC}"
    else
        # 服务未运行，启动服务
        echo -e "${YELLOW}Nginx 服务未运行，正在启动...${NC}"
        if [ -f "$BT_NGINX_CONF" ]; then
            # 宝塔环境
            $NGINX_BIN 2>/dev/null || bt reload nginx 2>/dev/null || systemctl start bt 2>/dev/null || echo -e "${YELLOW}请手动通过宝塔面板启动 Nginx${NC}"
        else
            # 标准环境
            systemctl start nginx && systemctl enable nginx
        fi
        sleep 2
        if pgrep -x nginx > /dev/null; then
            echo -e "${GREEN}Nginx 服务已启动${NC}"
        else
            echo -e "${YELLOW}警告: Nginx 服务可能未成功启动，请手动检查${NC}"
            echo -e "${YELLOW}运行启动脚本: sudo bash start-nginx.sh${NC}"
        fi
    fi
else
    echo -e "${RED}错误: Nginx 配置测试失败${NC}"
    echo -e "${YELLOW}请检查配置文件: $NGINX_AVAILABLE${NC}"
    exit 1
fi

# 步骤 8: 确保应用服务运行
echo -e "${YELLOW}[额外] 检查应用服务...${NC}"
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
echo -e "${YELLOW}下一步:${NC}"
echo -e "1. 在浏览器访问: ${GREEN}http://120.55.70.199${NC}"
echo -e "2. 如果仍无法访问，请检查:"
echo -e "   - 防火墙是否开放 80 端口"
echo -e "   - 云服务器安全组是否配置"
echo -e "   - 应用服务状态: ${GREEN}sudo systemctl status $SERVICE_NAME${NC}"
echo -e ""
echo -e "${YELLOW}查看日志:${NC}"
echo -e "   - Nginx 错误日志: ${GREEN}sudo tail -f /var/log/nginx/error.log${NC}"
echo -e "   - 应用服务日志: ${GREEN}sudo journalctl -u $SERVICE_NAME -f${NC}"

