#!/bin/bash

# 修复 400 Bad Request - 请求头或 Cookie 过大错误
# 使用方法: sudo bash 修复400错误.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}修复 400 Bad Request 错误${NC}"
echo -e "${GREEN}========================================${NC}"

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}请使用 sudo 运行${NC}"
    exit 1
fi

CONFIG_FILE="/www/server/panel/vhost/nginx/qk-paper-search.conf"
NGINX_BIN="/www/server/nginx/sbin/nginx"

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}错误: 配置文件不存在${NC}"
    echo -e "${YELLOW}请先运行站点配置脚本${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/4] 检查当前配置...${NC}"

# 检查是否已有缓冲区配置
if grep -q "client_header_buffer_size" "$CONFIG_FILE"; then
    echo -e "${YELLOW}检测到已有缓冲区配置，将更新为更大值...${NC}"
    # 更新现有配置
    sed -i 's/client_header_buffer_size.*/client_header_buffer_size 128k;/' "$CONFIG_FILE"
    sed -i 's/large_client_header_buffers.*/large_client_header_buffers 8 128k;/' "$CONFIG_FILE"
    sed -i 's/client_body_buffer_size.*/client_body_buffer_size 256k;/' "$CONFIG_FILE"
else
    echo -e "${YELLOW}添加缓冲区配置...${NC}"
    # 在 server { 后面添加配置
    sed -i '/server {/a\    # 增加缓冲区大小（解决 400 错误）\n    client_header_buffer_size 128k;\n    large_client_header_buffers 8 128k;\n    client_body_buffer_size 256k;' "$CONFIG_FILE"
fi

echo -e "${GREEN}缓冲区配置已添加/更新${NC}"

# 验证配置
echo -e "${YELLOW}[2/4] 验证配置...${NC}"
if grep -q "client_header_buffer_size" "$CONFIG_FILE"; then
    echo -e "${GREEN}配置验证通过${NC}"
    echo -e "${YELLOW}当前缓冲区配置:${NC}"
    grep -E "client_header_buffer_size|large_client_header_buffers|client_body_buffer_size" "$CONFIG_FILE"
else
    echo -e "${RED}错误: 配置添加失败${NC}"
    exit 1
fi

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
if $NGINX_BIN -s reload 2>/dev/null; then
    echo -e "${GREEN}Nginx 已重新加载${NC}"
else
    echo -e "${YELLOW}尝试重启 Nginx...${NC}"
    pkill nginx 2>/dev/null || true
    sleep 1
    $NGINX_BIN
    sleep 2
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}修复完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e ""
echo -e "${YELLOW}下一步:${NC}"
echo -e "1. ${GREEN}清除浏览器缓存${NC}（重要！）"
echo -e "2. 使用 ${GREEN}无痕模式${NC}或 ${GREEN}其他浏览器${NC}访问"
echo -e "3. 访问: ${GREEN}http://120.55.70.199${NC}"
echo -e ""
echo -e "${YELLOW}如果仍然出现 400 错误:${NC}"
echo -e "  - 清除浏览器 Cookie"
echo -e "  - 使用不同的浏览器"
echo -e "  - 检查错误日志: ${GREEN}tail -f /www/server/nginx/logs/error.log${NC}"




