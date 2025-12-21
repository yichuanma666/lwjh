# 部署配置文件

本目录包含用于服务器部署的配置文件。

## 文件说明

### `qk-paper-search.service`
Systemd 服务配置文件，用于将应用作为系统服务运行。

**使用方法**：
```bash
# 根据实际情况修改服务文件中的路径和用户
sudo cp qk-paper-search.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable qk-paper-search
sudo systemctl start qk-paper-search
```

### `nginx.conf.example`
Nginx 反向代理配置示例。

**使用方法**：
```bash
# 修改配置文件中的域名和路径
sudo cp nginx.conf.example /etc/nginx/sites-available/qk-paper-search
# 根据实际情况编辑配置文件
sudo nano /etc/nginx/sites-available/qk-paper-search
# 创建软链接启用站点
sudo ln -s /etc/nginx/sites-available/qk-paper-search /etc/nginx/sites-enabled/
# 测试并重新加载
sudo nginx -t && sudo systemctl reload nginx
```

### `deploy.sh`
自动化部署脚本，可以一键完成大部分部署步骤。

**使用方法**：
```bash
# 赋予执行权限
chmod +x deploy.sh
# 编辑脚本中的配置变量（路径、用户、域名等）
nano deploy.sh
# 运行部署脚本（需要 root 权限）
sudo ./deploy.sh
```

## 详细说明

请查看项目根目录的 [DEPLOYMENT.md](../DEPLOYMENT.md) 获取完整的部署指南。




