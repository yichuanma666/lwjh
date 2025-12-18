# 如何修改 Nginx 配置

## 📝 修改 server_name（域名配置）

### 场景 1：使用域名访问

如果你有域名，编辑 Nginx 配置文件：

```bash
# 编辑配置文件
sudo vi /etc/nginx/sites-available/qk-paper-search
# 或
sudo nano /etc/nginx/sites-available/qk-paper-search
```

找到 `server_name` 行，修改为你的域名：

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;  # 改为你的实际域名
    
    # ... 其他配置 ...
}
```

例如：
```nginx
server_name example.com www.example.com;
```

保存后重新加载 Nginx：
```bash
sudo nginx -t          # 测试配置
sudo systemctl reload nginx  # 重新加载
```

### 场景 2：使用 IP 地址访问（没有域名）

如果没有域名，可以使用服务器 IP 或使用 `_`（匹配所有）：

```nginx
server {
    listen 80;
    server_name _;  # 使用 _ 匹配所有域名和 IP
    
    # ... 其他配置 ...
}
```

或者直接使用 IP 地址：
```nginx
server {
    listen 80;
    server_name 192.168.1.100;  # 替换为你的服务器 IP
    
    # ... 其他配置 ...
}
```

**获取服务器 IP**：
```bash
curl ifconfig.me        # 公网 IP
hostname -I             # 本地 IP
```

### 场景 3：同时支持域名和 IP

可以同时配置多个 server_name：

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com 192.168.1.100;
    
    # ... 其他配置 ...
}
```

## 🔄 配置 HTTPS 重定向

### 启用 HTTP 到 HTTPS 自动重定向

如果配置了 SSL 证书，可以添加 HTTP 重定向到 HTTPS：

编辑配置文件，添加 HTTP 重定向块：

```nginx
# HTTP 重定向到 HTTPS
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS 配置
server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;
    
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    # ... 其他配置 ...
}
```

## 🔧 完整配置示例

### 示例 1：仅使用 IP 访问（无域名）

```nginx
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
}
```

### 示例 2：使用域名访问

```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    
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
}
```

### 示例 3：使用 HTTPS（完整配置）

```nginx
# HTTP 重定向到 HTTPS
server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS 配置
server {
    listen 443 ssl http2;
    server_name example.com www.example.com;
    
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
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
}
```

## 📋 修改配置步骤

### 1. 编辑配置文件

```bash
sudo vi /etc/nginx/sites-available/qk-paper-search
# 或
sudo nano /etc/nginx/sites-available/qk-paper-search
```

### 2. 修改 server_name

找到 `server_name` 行，修改为你需要的值：
- 域名：`server_name example.com www.example.com;`
- IP 地址：`server_name 192.168.1.100;`
- 匹配所有：`server_name _;`

### 3. 保存并测试

```bash
# 测试配置语法
sudo nginx -t

# 如果测试通过，重新加载 Nginx
sudo systemctl reload nginx
```

### 4. 验证访问

```bash
# 测试本地访问
curl http://127.0.0.1

# 如果配置了域名，测试域名
curl http://your-domain.com
```

## 🚨 常见问题

### 问题 1：修改后无法访问

**检查步骤**：
```bash
# 1. 检查配置语法
sudo nginx -t

# 2. 查看错误日志
sudo tail -f /var/log/nginx/error.log

# 3. 检查服务状态
sudo systemctl status nginx
```

### 问题 2：域名无法解析

如果使用域名但无法访问，检查：
1. **DNS 配置**：确保域名 A 记录指向服务器 IP
2. **等待 DNS 传播**：DNS 更改可能需要几分钟到几小时
3. **使用 IP 测试**：先用 IP 访问确认服务正常

### 问题 3：配置不生效

```bash
# 确保配置已重新加载
sudo systemctl reload nginx

# 或重启 Nginx
sudo systemctl restart nginx

# 检查配置是否生效
sudo nginx -T | grep server_name
```

## 💡 快速修改命令

### 使用 sed 快速修改 server_name

```bash
# 替换为 IP 地址（例如 192.168.1.100）
sudo sed -i 's/server_name.*;/server_name 192.168.1.100;/' /etc/nginx/sites-available/qk-paper-search

# 替换为域名（例如 example.com）
sudo sed -i 's/server_name.*;/server_name example.com www.example.com;/' /etc/nginx/sites-available/qk-paper-search

# 替换为匹配所有
sudo sed -i 's/server_name.*;/server_name _;/' /etc/nginx/sites-available/qk-paper-search

# 测试并重新加载
sudo nginx -t && sudo systemctl reload nginx
```

## 📚 相关文档

- [如何访问应用.md](如何访问应用.md) - 访问应用的方法
- [DEPLOYMENT.md](DEPLOYMENT.md) - 完整部署文档
- [故障排除清单.md](故障排除清单.md) - 常见问题解决

---

**快速修改示例**：
```bash
# 1. 编辑配置文件
sudo vi /etc/nginx/sites-available/qk-paper-search

# 2. 修改 server_name 行（按 i 编辑，修改后按 Esc，输入 :wq 保存）
server_name _;  # 或你的域名/IP

# 3. 测试并重新加载
sudo nginx -t && sudo systemctl reload nginx
```




