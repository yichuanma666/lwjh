# 服务器部署指南

本指南提供了将论文聚合搜索项目部署到生产服务器的详细步骤。提供多种部署方式供选择。

## 目录

- [方式一：传统部署（Systemd + Nginx）](#方式一传统部署systemd--nginx)
- [方式二：Docker 部署](#方式二docker-部署)
- [方式三：云平台部署](#方式三云平台部署)
- [部署后如何访问](#部署后如何访问)

## ⚠️ 重要提示：关于文本编辑器

如果遇到 `nano: command not found` 错误，请先查看 [编辑器使用指南 (EDITOR_GUIDE.md)](EDITOR_GUIDE.md) 了解解决方案。

**快速解决**：
- 安装 nano：`sudo apt install nano -y`（Ubuntu/Debian）或 `sudo yum install nano -y`（CentOS）
- 或使用 vi：`vi 文件名`（编辑时按 `i` 进入插入模式，按 `Esc` 后输入 `:wq` 保存退出）

---

## 方式一：传统部署（Systemd + Nginx）

适合在 Linux 服务器（Ubuntu、CentOS 等）上部署。

### 前置要求

- Python 3.8 或更高版本
- pip 包管理器
- Nginx（作为反向代理）
- 服务器有 root 或 sudo 权限

### 📝 关于文本编辑器

本文档中使用 `nano` 作为示例编辑器。如果你的服务器没有安装 `nano`，可以使用以下替代方案：

**选项 1：安装 nano（推荐，最简单）**
```bash
# Ubuntu/Debian
sudo apt install nano -y

# CentOS/RHEL
sudo yum install nano -y
```

**选项 2：使用 vi/vim（大多数 Linux 系统自带）**
```bash
# 使用 vi 编辑
vi config.yml
# 或
vim config.yml

# vi/vim 基本操作：
# - 按 'i' 进入插入模式（开始编辑）
# - 按 'Esc' 退出插入模式
# - 输入 ':wq' 保存并退出
# - 输入 ':q!' 不保存退出
```

**选项 3：使用其他编辑器**
- `vim` - 功能强大的编辑器
- `emacs` - 另一个流行的编辑器
- 或者直接使用 `cat > 文件名 << EOF` 的方式创建文件

在下面的步骤中，如果看到 `nano` 命令，请根据你的系统替换为上述编辑器之一。

### 步骤 1：准备服务器环境

```bash
# 更新系统包
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
# 或
sudo yum update -y  # CentOS/RHEL

# 安装 Python 和 pip（如果未安装）
sudo apt install python3 python3-pip python3-venv -y  # Ubuntu/Debian
# 或
sudo yum install python3 python3-pip -y  # CentOS/RHEL

# 安装 Nginx
sudo apt install nginx -y  # Ubuntu/Debian
# 或
sudo yum install nginx -y  # CentOS/RHEL
```

### 步骤 2：上传项目代码

将项目代码上传到服务器，建议放在 `/opt/qk` 或 `/home/your-user/qk` 目录：

```bash
# 创建项目目录
sudo mkdir -p /opt/qk
sudo chown $USER:$USER /opt/qk

# 使用 git 克隆或直接上传文件
cd /opt/qk
# 上传你的项目文件...
```

### 步骤 3：创建 Python 虚拟环境

```bash
cd /opt/qk

# 创建虚拟环境
python3 -m venv venv

# 激活虚拟环境
source venv/bin/activate

# 安装依赖
pip install --upgrade pip
pip install -r requirements.txt
```

### 步骤 4：配置应用

```bash
# 复制配置文件（如果还没有）
cp config.example.yml config.yml

# 编辑配置文件（如果系统没有 nano，可以使用 vi 或其他编辑器）
nano config.yml
# 或者使用: vi config.yml 或 vim config.yml
```

在 `config.yml` 中配置：
- API Keys（如 Semantic Scholar）
- Unpaywall 邮箱
- 其他配置项

### 步骤 5：测试应用

```bash
# 确保虚拟环境已激活
source venv/bin/activate

# 测试应用能否正常启动
uvicorn src.web.app:app --host 0.0.0.0 --port 8000
```

如果看到服务启动成功，按 `Ctrl+C` 停止。

### 步骤 6：创建 Systemd 服务

创建 systemd 服务文件，让应用作为系统服务运行：

```bash
# 如果系统没有 nano，可以使用 vi: sudo vi /etc/systemd/system/qk-paper-search.service
sudo nano /etc/systemd/system/qk-paper-search.service
```

复制以下内容（根据实际情况修改路径和用户）：

```ini
[Unit]
Description=论文聚合搜索 Web 服务
After=network.target

[Service]
Type=simple
User=your-user
Group=your-group
WorkingDirectory=/opt/qk
Environment="PATH=/opt/qk/venv/bin"
ExecStart=/opt/qk/venv/bin/uvicorn src.web.app:app --host 127.0.0.1 --port 8000 --workers 4
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**重要参数说明**：
- `User` 和 `Group`：运行服务的用户和组（建议使用非 root 用户）
- `WorkingDirectory`：项目根目录
- `ExecStart`：启动命令
  - `--host 127.0.0.1`：只监听本地，通过 Nginx 反向代理访问
  - `--workers 4`：工作进程数（根据服务器 CPU 核心数调整）

启动并启用服务：

```bash
# 重新加载 systemd
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start qk-paper-search

# 设置开机自启
sudo systemctl enable qk-paper-search

# 查看服务状态
sudo systemctl status qk-paper-search

# 查看日志
sudo journalctl -u qk-paper-search -f
```

### 步骤 7：配置 Nginx 反向代理

创建 Nginx 配置文件：

```bash
# 如果系统没有 nano，可以使用 vi: sudo vi /etc/nginx/sites-available/qk-paper-search
sudo nano /etc/nginx/sites-available/qk-paper-search
```

复制以下内容（根据实际情况修改域名和端口）：

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;  # 替换为你的域名或 IP

    client_max_body_size 100M;  # 允许上传大文件（如下载 PDF）

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket 支持（如果将来需要）
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # 超时设置
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }

    # 静态文件直接由 Nginx 提供（可选优化）
    location /static {
        alias /opt/qk/static;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

启用站点：

```bash
# 创建软链接
sudo ln -s /etc/nginx/sites-available/qk-paper-search /etc/nginx/sites-enabled/

# 测试 Nginx 配置
sudo nginx -t

# 重新加载 Nginx
sudo systemctl reload nginx
```

### 步骤 8：配置 SSL（可选但推荐）

使用 Let's Encrypt 免费 SSL 证书：

```bash
# 安装 Certbot
sudo apt install certbot python3-certbot-nginx -y  # Ubuntu/Debian

# 获取证书
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# 证书会自动续期（Certbot 已配置 cron 任务）
```

### 步骤 9：配置防火墙

```bash
# Ubuntu/Debian (UFW)
sudo ufw allow 'Nginx Full'
sudo ufw allow ssh
sudo ufw enable

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### 完成

现在可以通过浏览器访问：`http://your-domain.com` 或 `https://your-domain.com`（如果配置了 SSL）。

**📖 详细访问说明**：查看 [如何访问应用.md](如何访问应用.md)

---

## 方式二：Docker 部署

适合需要快速部署、隔离环境或使用容器编排的场景。

### 前置要求

- Docker 和 Docker Compose 已安装

### 步骤 1：构建和运行

```bash
# 构建镜像
docker-compose build

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f
```

### 步骤 2：配置 Nginx（可选）

如果需要通过域名访问，可以参考方式一的 Nginx 配置，将 `proxy_pass` 指向容器的端口。

---

## 方式三：云平台部署

### 阿里云 / 腾讯云 / AWS

1. **购买云服务器**（建议至少 2 核 4GB 内存）
2. **选择操作系统**：Ubuntu 20.04/22.04 LTS 或 CentOS 7/8
3. **按照方式一的步骤部署**

### 使用云平台应用服务

- **阿里云 ECS + 应用部署**：可以在 ECS 控制台使用应用部署模板
- **腾讯云 Lighthouse**：提供一键部署应用的功能
- **AWS EC2 + Elastic Beanstalk**：可以打包应用并自动部署

### 容器服务

- **阿里云容器服务 ACK**
- **腾讯云 TKE**
- **AWS ECS / EKS**

可以使用方式二的 Docker 部署文件。

---

## 生产环境优化建议

### 1. 性能优化

- **工作进程数**：根据 CPU 核心数调整 `--workers` 参数（建议为 CPU 核心数 × 2）
- **使用 Gunicorn**（如果需要更高级的功能）：
  ```bash
  pip install gunicorn
  gunicorn src.web.app:app -w 4 -k uvicorn.workers.UvicornWorker --bind 127.0.0.1:8000
  ```

### 2. 日志管理

- 配置日志轮转，避免日志文件过大
- 使用 `journalctl` 查看 systemd 服务日志
- 或配置日志收集系统（如 ELK Stack）

### 3. 监控和告警

- 使用监控工具（如 Prometheus + Grafana）监控应用状态
- 配置告警，当服务异常时及时通知

### 4. 备份

- 定期备份配置文件 `config.yml`
- 如果使用了 SQLite 数据库，定期备份数据库文件

### 5. 安全加固

- 使用非 root 用户运行服务
- 配置防火墙，只开放必要端口
- 定期更新系统和依赖包
- 使用 HTTPS（SSL/TLS）
- 如果使用 API Key，确保配置文件权限安全：
  ```bash
  chmod 600 config.yml
  ```

---

## 常见问题

### 问题 1：服务启动失败

**检查步骤**：
```bash
# 查看服务状态
sudo systemctl status qk-paper-search

# 查看详细日志
sudo journalctl -u qk-paper-search -n 50

# 检查配置文件语法
python3 -c "from src.config import load_config; load_config(None)"
```

### 问题 2：无法访问网站

**检查步骤**：
```bash
# 检查服务是否运行
sudo systemctl status qk-paper-search

# 检查端口是否监听
sudo netstat -tlnp | grep 8000

# 检查 Nginx 状态
sudo systemctl status nginx

# 检查 Nginx 配置
sudo nginx -t

# 查看 Nginx 错误日志
sudo tail -f /var/log/nginx/error.log
```

### 问题 3：502 Bad Gateway

通常是因为后端服务未启动或端口不匹配。

**解决方案**：
- 确认应用服务正在运行
- 检查 Nginx 配置中的 `proxy_pass` 端口是否与应用端口一致
- 检查防火墙是否阻止了连接

### 问题 4：内存不足

如果服务器内存较小，可以减少工作进程数：

```ini
# 在 systemd 服务文件中
ExecStart=/opt/qk/venv/bin/uvicorn src.web.app:app --host 127.0.0.1 --port 8000 --workers 2
```

---

## 更新部署

当需要更新代码时：

```bash
cd /opt/qk

# 备份当前版本（可选）
cp -r . ../qk-backup-$(date +%Y%m%d)

# 更新代码（git pull 或上传新文件）
git pull  # 如果使用 git

# 激活虚拟环境
source venv/bin/activate

# 更新依赖（如果有变化）
pip install -r requirements.txt

# 重启服务
sudo systemctl restart qk-paper-search

# 检查服务状态
sudo systemctl status qk-paper-search
```

---

## 卸载

如果需要卸载服务：

```bash
# 停止并禁用服务
sudo systemctl stop qk-paper-search
sudo systemctl disable qk-paper-search

# 删除服务文件
sudo rm /etc/systemd/system/qk-paper-search.service
sudo systemctl daemon-reload

# 删除 Nginx 配置
sudo rm /etc/nginx/sites-enabled/qk-paper-search
sudo systemctl reload nginx

# 删除项目文件（可选）
sudo rm -rf /opt/qk
```

---

如有问题，请查看日志或提交 Issue。

