#!/bin/bash

# 论文聚合搜索项目部署脚本
# 使用方法: ./deploy.sh

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置变量（请根据实际情况修改）
PROJECT_DIR="/opt/qk"
SERVICE_USER="www-data"
SERVICE_GROUP="www-data"
SERVICE_NAME="qk-paper-search"
DOMAIN_NAME="your-domain.com"  # 替换为你的域名

echo -e "${GREEN}开始部署论文聚合搜索项目...${NC}"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}错误: 请使用 sudo 运行此脚本${NC}"
    exit 1
fi

# 步骤 1: 检查系统依赖
echo -e "${YELLOW}[1/8] 检查系统依赖...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}错误: 未安装 Python3${NC}"
    exit 1
fi

if ! command -v pip3 &> /dev/null; then
    echo -e "${YELLOW}警告: 未安装 pip3，正在安装...${NC}"
    apt-get update && apt-get install -y python3-pip
fi

# 步骤 2: 创建项目目录并检查项目文件
echo -e "${YELLOW}[2/8] 创建项目目录并检查项目文件...${NC}"
mkdir -p "$PROJECT_DIR"

# 检查脚本是否在项目目录中运行（如果脚本本身就在项目目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# 如果脚本所在目录的父目录有 requirements.txt，说明项目在那里
if [ -f "$PARENT_DIR/requirements.txt" ]; then
    echo -e "${GREEN}检测到项目文件在: $PARENT_DIR${NC}"
    # 如果项目文件不在目标目录，提示用户
    if [ "$PARENT_DIR" != "$PROJECT_DIR" ]; then
        echo -e "${YELLOW}提示: 项目文件在 $PARENT_DIR，但目标目录是 $PROJECT_DIR${NC}"
        echo -e "${YELLOW}请确保项目文件已复制到 $PROJECT_DIR，或修改脚本中的 PROJECT_DIR 变量${NC}"
    fi
    cd "$PARENT_DIR"
elif [ -f "$PROJECT_DIR/requirements.txt" ]; then
    echo -e "${GREEN}项目文件已在目标目录: $PROJECT_DIR${NC}"
    cd "$PROJECT_DIR"
else
    echo -e "${RED}错误: 未找到项目文件！${NC}"
    echo -e "${RED}请确保：${NC}"
    echo -e "${RED}1. 项目文件已上传到服务器${NC}"
    echo -e "${RED}2. requirements.txt 文件存在于项目根目录${NC}"
    echo -e "${RED}3. 或修改脚本中的 PROJECT_DIR 变量指向正确的项目路径${NC}"
    echo -e "${YELLOW}当前检查的路径:${NC}"
    echo -e "  - 脚本目录: $SCRIPT_DIR"
    echo -e "  - 父目录: $PARENT_DIR"
    echo -e "  - 目标目录: $PROJECT_DIR"
    echo -e "${YELLOW}请检查这些目录中是否有 requirements.txt 文件${NC}"
    exit 1
fi

# 步骤 3: 创建虚拟环境
echo -e "${YELLOW}[3/8] 创建 Python 虚拟环境...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate

# 步骤 4: 安装依赖
echo -e "${YELLOW}[4/8] 安装 Python 依赖...${NC}"

# 升级 pip 到最新版本（避免版本兼容问题）
echo -e "${YELLOW}正在升级 pip...${NC}"
python3 -m pip install --upgrade pip --quiet || pip install --upgrade pip

if [ -f "requirements.txt" ]; then
    echo -e "${GREEN}找到 requirements.txt，开始安装依赖...${NC}"
    
    # 尝试安装依赖
    if ! pip install -r requirements.txt; then
        echo -e "${YELLOW}警告: 使用标准 requirements.txt 安装失败${NC}"
        echo -e "${YELLOW}尝试使用兼容版本...${NC}"
        
        # 如果失败，尝试使用兼容版本或逐个安装
        if [ -f "requirements-old.txt" ]; then
            echo -e "${YELLOW}使用 requirements-old.txt 安装兼容版本...${NC}"
            if ! pip install -r requirements-old.txt; then
                echo -e "${YELLOW}requirements-old.txt 也失败，尝试使用 requirements-minimal.txt...${NC}"
                if [ -f "requirements-minimal.txt" ]; then
                    pip install -r requirements-minimal.txt || {
                        echo -e "${YELLOW}所有 requirements 文件都失败，尝试逐个安装（不指定版本）...${NC}"
                        pip install requests PyYAML dataclasses-json tenacity fastapi "uvicorn[standard]" jinja2 python-multipart || {
                            echo -e "${RED}错误: 依赖安装失败${NC}"
                            echo -e "${YELLOW}请检查：${NC}"
                            echo -e "${YELLOW}1. pip 版本是否最新: pip --version${NC}"
                            echo -e "${YELLOW}2. Python 版本是否 >= 3.8: python3 --version${NC}"
                            echo -e "${YELLOW}3. 网络连接是否正常${NC}"
                            echo -e "${YELLOW}4. 查看详细错误信息：pip install -r requirements.txt -v${NC}"
                            exit 1
                        }
                    }
                else
                    echo -e "${YELLOW}尝试使用更宽松的版本要求安装...${NC}"
                    pip install requests PyYAML dataclasses-json tenacity fastapi "uvicorn[standard]" jinja2 python-multipart || {
                        echo -e "${RED}错误: 依赖安装失败${NC}"
                        echo -e "${YELLOW}请检查：${NC}"
                        echo -e "${YELLOW}1. pip 版本是否最新: pip --version${NC}"
                        echo -e "${YELLOW}2. Python 版本是否 >= 3.8: python3 --version${NC}"
                        echo -e "${YELLOW}3. 网络连接是否正常${NC}"
                        exit 1
                    }
                fi
            fi
        else
            echo -e "${YELLOW}尝试使用更宽松的版本要求安装...${NC}"
            pip install requests PyYAML dataclasses-json tenacity fastapi "uvicorn[standard]" jinja2 python-multipart || {
                echo -e "${RED}错误: 依赖安装失败${NC}"
                echo -e "${YELLOW}请检查：${NC}"
                echo -e "${YELLOW}1. pip 版本是否最新: pip --version${NC}"
                echo -e "${YELLOW}2. Python 版本是否 >= 3.8: python3 --version${NC}"
                echo -e "${YELLOW}3. 网络连接是否正常${NC}"
                exit 1
            }
        fi
    fi
    echo -e "${GREEN}依赖安装完成${NC}"
else
    echo -e "${RED}错误: 未找到 requirements.txt${NC}"
    echo -e "${YELLOW}当前工作目录: $(pwd)${NC}"
    echo -e "${YELLOW}目录内容:${NC}"
    ls -la
    echo -e "${RED}请确保 requirements.txt 文件存在于当前目录${NC}"
    exit 1
fi

# 步骤 5: 检查配置文件
echo -e "${YELLOW}[5/8] 检查配置文件...${NC}"
if [ ! -f "config.yml" ]; then
    if [ -f "config.example.yml" ]; then
        cp config.example.yml config.yml
        echo -e "${YELLOW}已创建 config.yml，请记得编辑配置${NC}"
    else
        echo -e "${RED}错误: 未找到配置文件${NC}"
        exit 1
    fi
fi

# 步骤 6: 安装 systemd 服务
echo -e "${YELLOW}[6/8] 安装 systemd 服务...${NC}"
if [ -f "deploy/qk-paper-search.service" ]; then
    # 替换服务文件中的变量
    sed "s|/opt/qk|$PROJECT_DIR|g; s|www-data|$SERVICE_USER|g" deploy/qk-paper-search.service > /tmp/qk-paper-search.service
    cp /tmp/qk-paper-search.service /etc/systemd/system/$SERVICE_NAME.service
    systemctl daemon-reload
    echo -e "${GREEN}systemd 服务已安装${NC}"
else
    echo -e "${YELLOW}警告: 未找到 systemd 服务文件，请手动配置${NC}"
fi

# 步骤 7: 配置 Nginx
echo -e "${YELLOW}[7/8] 配置 Nginx...${NC}"
if command -v nginx &> /dev/null; then
    if [ -f "deploy/nginx.conf.example" ]; then
        # 确定 Nginx 配置目录（不同发行版可能不同）
        NGINX_CONF_DIR="/etc/nginx"
        SITES_AVAILABLE_DIR="/etc/nginx/sites-available"
        SITES_ENABLED_DIR="/etc/nginx/sites-enabled"
        
        # 检查并创建目录（如果不存在）
        if [ ! -d "$SITES_AVAILABLE_DIR" ]; then
            echo -e "${YELLOW}创建 Nginx sites-available 目录...${NC}"
            mkdir -p "$SITES_AVAILABLE_DIR"
        fi
        
        if [ ! -d "$SITES_ENABLED_DIR" ]; then
            echo -e "${YELLOW}创建 Nginx sites-enabled 目录...${NC}"
            mkdir -p "$SITES_ENABLED_DIR"
        fi
        
        # 替换配置文件中的域名
        sed "s|your-domain.com|$DOMAIN_NAME|g; s|/opt/qk|$PROJECT_DIR|g" deploy/nginx.conf.example > /tmp/nginx-qk.conf
        
        # 复制配置文件
        cp /tmp/nginx-qk.conf "$SITES_AVAILABLE_DIR/$SERVICE_NAME"
        echo -e "${GREEN}Nginx 配置文件已复制到 $SITES_AVAILABLE_DIR/$SERVICE_NAME${NC}"
        
        # 创建软链接
        if [ ! -L "$SITES_ENABLED_DIR/$SERVICE_NAME" ]; then
            ln -s "$SITES_AVAILABLE_DIR/$SERVICE_NAME" "$SITES_ENABLED_DIR/$SERVICE_NAME"
            echo -e "${GREEN}已创建 Nginx 站点软链接${NC}"
        else
            echo -e "${YELLOW}Nginx 站点软链接已存在${NC}"
        fi
        
        # 测试 Nginx 配置
        if nginx -t; then
            systemctl reload nginx
            echo -e "${GREEN}Nginx 配置已更新并重新加载${NC}"
        else
            echo -e "${RED}错误: Nginx 配置测试失败${NC}"
            echo -e "${YELLOW}请手动检查 Nginx 配置: nginx -t${NC}"
        fi
    else
        echo -e "${YELLOW}警告: 未找到 Nginx 配置文件示例${NC}"
    fi
else
    echo -e "${YELLOW}警告: 未安装 Nginx，跳过配置${NC}"
    echo -e "${YELLOW}如需配置 Nginx，请先安装: sudo apt install nginx -y${NC}"
fi

# 步骤 8: 启动服务
echo -e "${YELLOW}[8/8] 启动服务...${NC}"
systemctl enable $SERVICE_NAME
systemctl restart $SERVICE_NAME

# 检查服务状态
if systemctl is-active --quiet $SERVICE_NAME; then
    echo -e "${GREEN}服务启动成功！${NC}"
else
    echo -e "${RED}错误: 服务启动失败，请检查日志: journalctl -u $SERVICE_NAME${NC}"
    exit 1
fi

# 完成
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "项目目录: ${GREEN}$PROJECT_DIR${NC}"
echo -e "服务状态: ${GREEN}systemctl status $SERVICE_NAME${NC}"
echo -e "查看日志: ${GREEN}journalctl -u $SERVICE_NAME -f${NC}"
echo -e "访问地址: ${GREEN}http://$DOMAIN_NAME${NC}"
echo -e ""
echo -e "${YELLOW}下一步:${NC}"
echo -e "1. 编辑配置文件: nano $PROJECT_DIR/config.yml"
echo -e "2. 如需配置 SSL: certbot --nginx -d $DOMAIN_NAME"
echo -e "3. 重启服务: systemctl restart $SERVICE_NAME"

