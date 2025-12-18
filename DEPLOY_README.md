# 部署文件位置说明

## 📁 部署脚本位置

部署脚本位于：**`deploy/deploy.sh`**

```
项目根目录/
├── deploy/
│   ├── deploy.sh              ← 部署脚本在这里！
│   ├── qk-paper-search.service
│   ├── nginx.conf.example
│   └── README.md
├── DEPLOYMENT.md              ← 详细部署文档
├── QUICK_START_DEPLOY.md      ← 快速部署指南
└── ...
```

## 🚀 如何使用

### 在 Linux 服务器上运行：

```bash
# 1. 进入项目目录
cd /opt/qk  # 或你的项目路径

# 2. 给脚本添加执行权限
chmod +x deploy/deploy.sh

# 3. 编辑脚本中的配置（可选）
nano deploy/deploy.sh
# 修改这些变量：
#   PROJECT_DIR="/opt/qk"
#   SERVICE_USER="www-data"
#   DOMAIN_NAME="your-domain.com"

# 4. 修复行结束符（如果从 Windows 上传，可选但推荐）
# sudo apt install dos2unix -y && dos2unix deploy/deploy.sh

# 5. 运行部署脚本（需要 root 权限）
sudo ./deploy/deploy.sh

# 如果遇到 "command not found" 错误，请查看：
# - 解决deploy脚本无法运行.md
# 或尝试：sudo bash deploy/deploy.sh
```

## ⚠️ 重要提示

- **此脚本只能在 Linux 服务器上运行**，不能在 Windows 本地运行
- 脚本需要 root 权限（使用 `sudo`）
- 部署前请确保已上传整个项目文件夹到服务器
- **如果遇到 "command not found" 错误**，请先执行 `chmod +x deploy/deploy.sh` 添加执行权限

## 📖 更多帮助

- **详细部署指南**：查看 [DEPLOYMENT.md](DEPLOYMENT.md)
- **快速部署参考**：查看 [QUICK_START_DEPLOY.md](QUICK_START_DEPLOY.md)
- **配置文件说明**：查看 [deploy/README.md](deploy/README.md)

## 🔍 找不到文件？

如果看不到 `deploy/deploy.sh` 文件：

1. **在 Windows 资源管理器中**：确保显示所有文件（包括隐藏文件）
2. **使用命令行查看**：
   ```bash
   ls deploy/          # Linux/Mac
   dir deploy\         # Windows
   ```
3. **检查文件是否存在**：
   ```bash
   ls -la deploy/deploy.sh    # Linux/Mac
   ```

---

**部署脚本路径**：`deploy/deploy.sh` ✅

