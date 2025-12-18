# 快速修复 pip 安装问题

## 🚀 一键解决方案

如果你的服务器无法安装依赖包（如 fastapi、requests 等），按以下顺序尝试：

### 步骤 1：升级 pip（最重要！）

```bash
python3 -m pip install --upgrade pip
```

### 步骤 2：尝试使用兼容版本

按顺序尝试以下文件：

```bash
# 方法 1：使用中等兼容版本
pip install -r requirements-old.txt

# 如果失败，方法 2：使用最低兼容版本
pip install -r requirements-minimal.txt

# 如果还是失败，方法 3：不指定版本（安装默认最新可用版本）
pip install requests PyYAML dataclasses-json tenacity fastapi "uvicorn[standard]" jinja2 python-multipart
```

## 📦 三个兼容级别

项目中包含三个 requirements 文件，按兼容性从高到低：

1. **requirements.txt** - 最新版本（推荐用于新系统）
2. **requirements-old.txt** - 中等兼容性（fastapi>=0.83.0）
3. **requirements-minimal.txt** - 最低兼容性（fastapi>=0.68.0）

## ⚡ 最快解决方法

```bash
# 复制粘贴这一整段命令
python3 -m pip install --upgrade pip && \
pip install -r requirements-minimal.txt || \
pip install requests PyYAML dataclasses-json tenacity fastapi "uvicorn[standard]" jinja2 python-multipart
```

## 🔍 如果都失败了

1. **检查 Python 版本**：需要 3.8+
   ```bash
   python3 --version
   ```

2. **检查网络连接**：能否访问 PyPI
   ```bash
   ping pypi.org
   ```

3. **使用国内镜像**（如果在中国）：
   ```bash
   pip install -i https://pypi.tuna.tsinghua.edu.cn/simple -r requirements-minimal.txt
   ```

## 📚 详细说明

查看 [解决pip安装失败.md](解决pip安装失败.md) 获取更详细的故障排除指南。




