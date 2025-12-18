# 快速部署指南

这是服务器部署的快速参考，详细说明请查看 [DEPLOYMENT.md](DEPLOYMENT.md)。

## 方式一：使用部署脚本（最快）

```bash
# 1. 将项目上传到服务器，例如 /opt/qk
cd /opt/qk

# 2. 编辑部署脚本中的配置变量
nano deploy/deploy.sh
# 修改：PROJECT_DIR、SERVICE_USER、DOMAIN_NAME 等

# 3. 运行部署脚本
# 添加执行权限
chmod +x deploy/deploy.sh

# 如果文件是从 Windows 上传的，可能需要修复行结束符
# sudo apt install dos2unix -y && dos2unix deploy/deploy.sh

# 运行脚本
sudo ./deploy/deploy.sh
# 如果上面的命令失败，可以尝试：sudo bash deploy/deploy.sh
```

## 方式二：手动部署（推荐用于生产环境）

### 1. 准备环境

```bash
# 安装依赖
sudo apt update
sudo apt install python3 python3-pip python3-venv nginx -y

# 创建项目目录
sudo mkdir -p /opt/qk
sudo chown $USER:$USER /opt/qk
cd /opt/qk
# 上传项目文件到这里
```

### 2. 设置 Python 环境

```bash
# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装依赖
pip install --upgrade pip
pip install -r requirements.txt

# 配置应用
cp config.example.yml config.yml
# 编辑配置（如果系统没有 nano，可以使用 vi）
nano config.yml  # 或: vi config.yml
```

### 3. 配置 Systemd 服务

```bash
# 复制服务文件
sudo cp deploy/qk-paper-search.service /etc/systemd/system/

# 编辑服务文件（修改路径和用户）
# 如果系统没有 nano，可以使用: sudo vi /etc/systemd/system/qk-paper-search.service
sudo nano /etc/systemd/system/qk-paper-search.service

# 启动服务
sudo systemctl daemon-reload
sudo systemctl enable qk-paper-search
sudo systemctl start qk-paper-search
sudo systemctl status qk-paper-search
```

### 4. 配置 Nginx

```bash
# 复制并编辑 Nginx 配置
sudo cp deploy/nginx.conf.example /etc/nginx/sites-available/qk-paper-search
# 如果系统没有 nano，可以使用: sudo vi /etc/nginx/sites-available/qk-paper-search
sudo nano /etc/nginx/sites-available/qk-paper-search
# 修改域名和路径

# 启用站点
sudo ln -s /etc/nginx/sites-available/qk-paper-search /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 5. 配置 SSL（可选但推荐）

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d your-domain.com
```

## 方式三：Docker 部署

```bash
# 1. 构建并启动
docker-compose up -d

# 2. 查看日志
docker-compose logs -f

# 3. 停止服务
docker-compose down
```

## 部署后访问应用

部署完成后，访问你的应用：

- **有域名**：`http://your-domain.com`
- **无域名**：`http://服务器IP地址`
- **直接访问应用**：`http://服务器IP地址:8000`

**详细访问指南**：查看 [如何访问应用.md](如何访问应用.md)

## 部署后检查清单

- [ ] 服务是否正常运行：`sudo systemctl status qk-paper-search`
- [ ] 可以通过浏览器访问网站
- [ ] 配置文件已正确设置（API Keys、邮箱等）
- [ ] 防火墙已配置（开放 80 和 443 端口）
- [ ] SSL 证书已配置（如需要）
- [ ] 日志正常，无错误信息

## 常用命令

```bash
# 查看服务状态
sudo systemctl status qk-paper-search

# 查看日志
sudo journalctl -u qk-paper-search -f

# 重启服务
sudo systemctl restart qk-paper-search

# 查看 Nginx 日志
sudo tail -f /var/log/nginx/qk-paper-search-error.log

# 测试 Nginx 配置
sudo nginx -t
```

## 遇到问题？

1. 查看 [DEPLOYMENT.md](DEPLOYMENT.md) 的"常见问题"部分
2. 检查服务日志：`sudo journalctl -u qk-paper-search -n 50`
3. 检查 Nginx 日志：`sudo tail -f /var/log/nginx/error.log`

