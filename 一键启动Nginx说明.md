# 一键启动 Nginx 服务

## 📁 脚本文件

**start-nginx.sh** - 一键启动 Nginx 服务脚本（支持宝塔面板和标准安装）

## 🚀 快速使用

### 方法 1：直接运行

```bash
# 添加执行权限并运行
chmod +x start-nginx.sh && sudo ./start-nginx.sh
```

### 方法 2：使用 bash 运行

```bash
# 直接用 bash 运行
sudo bash start-nginx.sh
```

## ✨ 脚本功能

- ✅ **自动检测环境**（宝塔面板或标准安装）
- ✅ **检查 Nginx 是否运行**
- ✅ **如果运行，重新加载配置**
- ✅ **如果未运行，启动服务**
- ✅ **检查端口监听状态**

## 🔧 宝塔面板环境

如果你使用宝塔面板，脚本会自动检测并：

1. 使用宝塔 Nginx 路径：`/www/server/nginx/sbin/nginx`
2. 支持宝塔命令：`bt reload nginx`
3. 检查宝塔服务状态

## 📝 手动启动方法

### 宝塔面板

```bash
# 方法 1：使用宝塔命令
bt reload nginx

# 方法 2：直接启动
/www/server/nginx/sbin/nginx

# 方法 3：通过宝塔面板界面
# 登录宝塔 → 软件商店 → Nginx → 设置 → 启动/重启
```

### 标准安装

```bash
# 启动服务
sudo systemctl start nginx

# 设置开机自启
sudo systemctl enable nginx

# 检查状态
sudo systemctl status nginx
```

## 🔍 验证启动

启动后验证：

```bash
# 检查进程
ps aux | grep nginx

# 检查端口
netstat -tlnp | grep :80

# 测试访问
curl http://127.0.0.1
curl http://120.55.70.199
```

## 📚 相关文档

- [解决nginx未启动.md](解决nginx未启动.md) - 详细故障排查
- [fix-nginx-site.sh](fix-nginx-site.sh) - Nginx 配置修复脚本
- [如何访问应用.md](如何访问应用.md) - 访问应用的方法

---

**快速命令**：
```bash
sudo bash start-nginx.sh
```




