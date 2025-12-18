# 解决 pip 安装失败："找不到满足要求的版本"

## 🔍 问题描述

错误信息：`ERROR: Could not find a version that satisfies the requirement requests>=2.31.0`

这表示 pip 无法找到满足版本要求的包。常见原因：
1. **pip 版本太旧**（最常见）
2. **Python 版本太旧**，不支持新版本包
3. **PyPI 索引缓存问题**
4. **网络问题**，无法访问 PyPI

## ✅ 解决方案

### 方案 1：升级 pip（最重要！）

```bash
# 确保虚拟环境已激活（如果有）
source venv/bin/activate  # 或：. venv/bin/activate

# 升级 pip 到最新版本
pip install --upgrade pip

# 或者使用 pip3
pip3 install --upgrade pip

# 如果上面命令失败，使用以下命令强制升级
python3 -m pip install --upgrade pip
```

### 方案 2：清除 pip 缓存并重新安装

```bash
# 清除 pip 缓存
pip cache purge
# 或
pip3 cache purge

# 使用 --no-cache-dir 重新安装
pip install --no-cache-dir --upgrade pip

# 然后重新安装依赖
pip install --no-cache-dir -r requirements.txt
```

### 方案 3：使用兼容旧系统的版本要求

如果升级 pip 后仍然失败，可以使用兼容版本的 requirements 文件：

```bash
# 首先尝试使用 requirements-old.txt（中等兼容性）
pip install -r requirements-old.txt

# 如果还是失败，使用 requirements-minimal.txt（最低版本要求）
pip install -r requirements-minimal.txt
```

这些文件已经包含在项目中：
- `requirements-old.txt` - 中等兼容性版本
- `requirements-minimal.txt` - 最低兼容性版本（推荐用于非常旧的系统）

### 方案 4：检查 Python 和 pip 版本

```bash
# 检查 Python 版本（需要 3.8+）
python3 --version

# 检查 pip 版本
pip --version
# 或
pip3 --version

# 如果 pip 版本低于 21.0，强烈建议升级
```

### 方案 5：手动安装单个包

如果批量安装失败，可以尝试逐个安装：

```bash
# 先升级 pip
pip install --upgrade pip

# 然后逐个安装（使用更宽松的版本要求）
pip install requests
pip install PyYAML
pip install dataclasses-json
pip install tenacity
pip install fastapi
pip install "uvicorn[standard]"
pip install jinja2
pip install python-multipart
```

### 方案 6：使用国内 PyPI 镜像（如果在中国）

如果访问 PyPI 较慢，可以使用国内镜像：

```bash
# 使用清华镜像
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade pip

# 然后使用镜像安装依赖
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple -r requirements.txt

# 或者临时设置镜像
pip install --upgrade pip -i https://pypi.tuna.tsinghua.edu.cn/simple
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

其他镜像源：
- 阿里云：`https://mirrors.aliyun.com/pypi/simple/`
- 中科大：`https://pypi.mirrors.ustc.edu.cn/simple/`
- 豆瓣：`https://pypi.douban.com/simple/`

## 🔧 完整修复流程（推荐）

按顺序执行以下命令：

```bash
# 1. 进入项目目录
cd /opt/qk  # 替换为你的项目路径

# 2. 激活虚拟环境（如果使用）
source venv/bin/activate

# 3. 升级 pip（最重要！）
python3 -m pip install --upgrade pip

# 4. 清除缓存
pip cache purge

# 5. 重新安装依赖
pip install -r requirements.txt

# 如果还是失败，尝试使用更宽松的版本
pip install requests PyYAML dataclasses-json tenacity fastapi "uvicorn[standard]" jinja2 python-multipart
```

## 📝 使用兼容版本的 requirements 文件

项目中已经包含了兼容版本的依赖文件：

**选项 1：requirements-old.txt（中等兼容性）**
- fastapi>=0.83.0
- 适用于大多数旧系统

**选项 2：requirements-minimal.txt（最低兼容性）**
- fastapi>=0.68.0
- 适用于非常旧的系统

使用方法：

```bash
# 尝试按顺序使用
pip install -r requirements-old.txt

# 如果还是失败，使用最低版本
pip install -r requirements-minimal.txt
```

如果都失败了，可以手动安装单个包（不指定版本，使用默认最新可用版本）：

```bash
pip install requests PyYAML dataclasses-json tenacity fastapi "uvicorn[standard]" jinja2 python-multipart
```

## 🚨 常见错误对照

| 错误信息 | 原因 | 解决方法 |
|---------|------|---------|
| `Could not find a version` | pip 太旧或缓存问题 | 升级 pip：`pip install --upgrade pip` |
| `No matching distribution` | 版本要求太高 | 使用兼容版本或升级 pip |
| `SSL: CERTIFICATE_VERIFY_FAILED` | SSL 证书问题 | 使用 `--trusted-host` 参数 |
| `Connection timeout` | 网络问题 | 使用国内镜像源 |

## 💡 预防措施

**部署前检查**：

```bash
# 1. 检查 Python 版本（需要 3.8+）
python3 --version

# 2. 检查 pip 版本（建议 21.0+）
pip3 --version

# 3. 升级 pip
pip3 install --upgrade pip

# 4. 测试安装一个简单包
pip3 install requests
```

## 📚 相关文档

- [故障排除清单.md](故障排除清单.md) - 其他常见问题
- [DEPLOYMENT.md](DEPLOYMENT.md) - 完整部署文档
- [解决requirements.txt未找到.md](解决requirements.txt未找到.md) - 文件缺失问题

## ⚠️ 重要提示

1. **升级 pip 是最重要的步骤**，大多数问题都能通过升级 pip 解决
2. **Python 版本要求**：建议使用 Python 3.8 或更高版本
3. **如果使用非常旧的系统**，考虑升级 Python 或使用 Docker 部署

---

**快速解决命令**：
```bash
python3 -m pip install --upgrade pip && pip install -r requirements.txt
```

