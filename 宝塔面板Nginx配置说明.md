# 宝塔面板 Nginx 配置说明

## 🔍 问题说明

在宝塔面板环境下，即使 Nginx 服务运行正常，仍可能出现"没有找到站点"的错误。这是因为：

1. **宝塔面板使用独立的 vhost 目录**：`/www/server/panel/vhost/nginx/`
2. **需要在此目录创建站点配置**，而不是 `/etc/nginx/sites-available/`
3. **需要确保 Nginx 主配置包含 vhost 目录**

## ✅ 解决方案

### 方法 1：使用修复脚本（推荐）

```bash
# 运行宝塔面板专用修复脚本
sudo bash fix-bt-nginx-site.sh
```

### 方法 2：手动配置

#### 步骤 1：在宝塔 vhost 目录创建配置

```bash
# 创建站点配置文件
sudo vi /www/server/panel/vhost/nginx/qk-paper-search.conf
```

添加以下内容：

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

    access_log /www/server/nginx/logs/qk-paper-search-access.log;
    error_log /www/server/nginx/logs/qk-paper-search-error.log;
}
```

#### 步骤 2：检查 Nginx 主配置

```bash
# 查看 Nginx 主配置
cat /www/server/nginx/conf/nginx.conf | grep include

# 应该看到类似：
# include /www/server/panel/vhost/nginx/*.conf;
```

如果没有，需要添加：

```bash
# 编辑主配置文件
sudo vi /www/server/nginx/conf/nginx.conf

# 在 http { ... } 块中添加：
include /www/server/panel/vhost/nginx/*.conf;
```

#### 步骤 3：测试并重新加载

```bash
# 测试配置
/www/server/nginx/sbin/nginx -t

# 重新加载
/www/server/nginx/sbin/nginx -s reload
# 或
bt reload nginx
```

### 方法 3：通过宝塔面板界面配置

1. **登录宝塔面板**
2. **进入"网站"**
3. **点击"添加站点"**
   - 域名：填写 `120.55.70.199` 或留空
   - 网站目录：`/opt/qk`
   - PHP版本：纯静态（如果不需要PHP）
4. **在站点设置中添加反向代理**
   - 目标URL：`http://127.0.0.1:8000`
   - 发送域名：`$host`

## 📋 宝塔面板目录结构

```
/www/server/nginx/
├── conf/
│   └── nginx.conf          # 主配置文件
├── sbin/
│   └── nginx               # Nginx 二进制文件
└── logs/
    ├── error.log           # 错误日志
    └── access.log          # 访问日志

/www/server/panel/vhost/nginx/
└── *.conf                  # 站点配置文件（每个站点一个）
```

## 🔍 检查配置

### 1. 检查站点配置文件

```bash
# 查看所有站点配置
ls -la /www/server/panel/vhost/nginx/

# 查看我们的站点配置
cat /www/server/panel/vhost/nginx/qk-paper-search.conf
```

### 2. 检查 Nginx 主配置

```bash
# 查看主配置文件
cat /www/server/nginx/conf/nginx.conf | grep -A5 -B5 vhost

# 应该包含：
# include /www/server/panel/vhost/nginx/*.conf;
```

### 3. 检查配置加载

```bash
# 查看 Nginx 加载的所有配置
/www/server/nginx/sbin/nginx -T | grep server_name
```

### 4. 查看错误日志

```bash
# 实时查看错误日志
tail -f /www/server/nginx/logs/error.log

# 查看最近错误
tail -n 50 /www/server/nginx/logs/error.log
```

## 🚨 常见问题

### 问题 1：配置文件存在但不生效

**原因**：Nginx 主配置未包含 vhost 目录

**解决**：
```bash
# 检查主配置
cat /www/server/nginx/conf/nginx.conf | grep vhost

# 如果没有，添加包含
echo "include /www/server/panel/vhost/nginx/*.conf;" >> /www/server/nginx/conf/nginx.conf

# 重新加载
/www/server/nginx/sbin/nginx -s reload
```

### 问题 2：端口冲突

```bash
# 检查端口占用
netstat -tlnp | grep :80
lsof -i :80

# 如果有其他服务占用，需要停止或修改端口
```

### 问题 3：server_name 不匹配

确保 `server_name` 设置为 `_` 或你的 IP：

```nginx
server_name _;  # 匹配所有
# 或
server_name 120.55.70.199;  # 匹配特定 IP
```

## 📚 相关文档

- [fix-bt-nginx-site.sh](fix-bt-nginx-site.sh) - 宝塔面板修复脚本
- [fix-nginx-site.sh](fix-nginx-site.sh) - 标准 Nginx 修复脚本
- [解决没有找到站点错误.md](解决没有找到站点错误.md) - 通用故障排查

---

**快速修复**：
```bash
sudo bash fix-bt-nginx-site.sh
```




