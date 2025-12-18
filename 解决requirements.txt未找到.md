# 解决 "未找到 requirements.txt" 错误

## 🔍 问题原因

这个错误表示部署脚本在服务器上找不到 `requirements.txt` 文件。可能的原因：

1. **项目文件没有完整上传到服务器**
2. **部署脚本在错误的目录下运行**
3. **文件路径不正确**

## ✅ 解决方案

### 方案 1：检查文件是否上传（最常见）

```bash
# 1. 进入项目目录
cd /opt/qk  # 替换为你的实际项目路径

# 2. 检查 requirements.txt 是否存在
ls -la requirements.txt

# 3. 查看当前目录的所有文件
ls -la

# 4. 确认文件内容
cat requirements.txt
```

如果文件不存在，说明项目文件没有完整上传。需要重新上传所有项目文件。

### 方案 2：手动创建 requirements.txt

如果文件确实丢失，可以手动创建：

```bash
cd /opt/qk  # 你的项目目录

# 创建 requirements.txt 文件
cat > requirements.txt << 'EOF'
requests>=2.31.0
PyYAML>=6.0.2
dataclasses-json>=0.6.7
tenacity>=9.0.0
fastapi>=0.115.0
uvicorn[standard]>=0.30.0
jinja2>=3.1.4
python-multipart>=0.0.9
EOF

# 验证文件
cat requirements.txt
```

### 方案 3：从项目源重新上传文件

如果项目在本地或其他地方有备份：

```bash
# 在本地（Windows）使用 scp 或 SFTP 上传
# 使用 scp 命令（在本地执行）：
scp requirements.txt 用户名@服务器IP:/opt/qk/

# 或者使用 SFTP 工具（如 FileZilla、WinSCP）上传整个项目目录
```

### 方案 4：检查部署脚本的目录设置

确认部署脚本中的 `PROJECT_DIR` 变量是否正确：

```bash
# 查看部署脚本的配置
cat deploy/deploy.sh | grep PROJECT_DIR

# 如果路径不对，编辑脚本
vi deploy/deploy.sh
# 或
nano deploy/deploy.sh

# 找到这一行并修改：
# PROJECT_DIR="/opt/qk"  # 改为你的实际路径
```

### 方案 5：手动安装依赖（临时方案）

如果只是想快速测试，可以手动安装依赖：

```bash
cd /opt/qk  # 项目目录

# 创建虚拟环境（如果还没有）
python3 -m venv venv
source venv/bin/activate

# 手动安装依赖
pip install --upgrade pip
pip install requests>=2.31.0
pip install PyYAML>=6.0.2
pip install dataclasses-json>=0.6.7
pip install tenacity>=9.0.0
pip install fastapi>=0.115.0
pip install "uvicorn[standard]>=0.30.0"
pip install jinja2>=3.1.4
pip install python-multipart>=0.0.9
```

## 🔧 完整的项目文件清单

确保以下文件都已上传到服务器：

```
项目根目录/
├── requirements.txt          ← 这个文件必须存在！
├── config.example.yml
├── config.yml               （可选，可以后续创建）
├── src/
│   ├── __init__.py
│   ├── main.py
│   ├── config.py
│   ├── models.py
│   ├── aggregator.py
│   ├── storage.py
│   ├── web/
│   │   └── app.py
│   └── sources/
│       ├── __init__.py
│       ├── base.py
│       ├── arxiv.py
│       ├── crossref.py
│       └── ...
├── templates/
│   └── index.html
├── static/
│   └── style.css
└── deploy/
    ├── deploy.sh
    └── ...
```

## 📋 检查清单

在运行部署脚本前，确认：

- [ ] `requirements.txt` 文件存在于项目根目录
- [ ] 项目文件已完整上传到服务器
- [ ] 部署脚本中的 `PROJECT_DIR` 路径正确
- [ ] 当前工作目录正确（`pwd` 命令查看）

## 🚀 快速修复步骤

```bash
# 1. 检查当前目录
pwd

# 2. 进入项目目录（如果不在）
cd /opt/qk  # 替换为你的实际路径

# 3. 检查文件是否存在
ls -la requirements.txt

# 4. 如果不存在，创建文件（复制上面的内容）
cat > requirements.txt << 'EOF'
requests>=2.31.0
PyYAML>=6.0.2
dataclasses-json>=0.6.7
tenacity>=9.0.0
fastapi>=0.115.0
uvicorn[standard]>=0.30.0
jinja2>=3.1.4
python-multipart>=0.0.9
EOF

# 5. 验证文件
cat requirements.txt

# 6. 重新运行部署脚本
sudo ./deploy/deploy.sh
```

## 💡 预防措施

**上传项目到服务器时**：

1. **使用 Git（推荐）**：
   ```bash
   git clone 你的仓库地址 /opt/qk
   ```

2. **使用 SFTP/SCP 时**：
   - 确保上传整个项目目录
   - 上传后检查关键文件是否存在
   - 验证文件大小是否正确

3. **使用压缩包**：
   ```bash
   # 在本地打包
   tar -czf qk.tar.gz 项目目录/
   
   # 上传到服务器
   scp qk.tar.gz user@server:/tmp/
   
   # 在服务器上解压
   cd /opt
   tar -xzf /tmp/qk.tar.gz
   ```

## 📝 相关文档

- [故障排除清单.md](故障排除清单.md) - 其他常见问题
- [DEPLOYMENT.md](DEPLOYMENT.md) - 完整部署文档
- [解决deploy脚本无法运行.md](解决deploy脚本无法运行.md) - 脚本运行问题




