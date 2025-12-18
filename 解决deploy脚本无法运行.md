# 解决 "command not found" 错误

如果遇到 `sudo: ./deploy/deploy.sh: command not found` 错误，请按以下步骤解决：

## 🔍 问题诊断

首先检查脚本是否存在：

```bash
# 查看当前目录
pwd

# 检查文件是否存在
ls -la deploy/deploy.sh

# 或者检查完整路径
ls -la /opt/qk/deploy/deploy.sh  # 根据你的实际路径调整
```

## ✅ 解决方案

### 方案 1：添加执行权限（最常见）

脚本文件可能没有执行权限，需要添加：

```bash
# 确保在项目根目录
cd /opt/qk  # 或你的项目路径

# 添加执行权限
chmod +x deploy/deploy.sh

# 验证权限（应该看到 x 标志）
ls -l deploy/deploy.sh
# 输出应该类似：-rwxr-xr-x ... deploy/deploy.sh

# 现在再运行
sudo ./deploy/deploy.sh
```

### 方案 2：修复行结束符问题（Windows 上传后常见）

如果文件是从 Windows 上传的，可能有行结束符问题：

```bash
# 安装 dos2unix（如果没有）
sudo apt install dos2unix -y  # Ubuntu/Debian
# 或
sudo yum install dos2unix -y  # CentOS/RHEL

# 转换文件格式
dos2unix deploy/deploy.sh

# 或者使用 sed 命令
sed -i 's/\r$//' deploy/deploy.sh

# 然后再添加执行权限
chmod +x deploy/deploy.sh

# 运行脚本
sudo ./deploy/deploy.sh
```

### 方案 3：使用 bash 直接运行

如果权限问题解决不了，可以直接用 bash 运行：

```bash
# 直接使用 bash 执行（不需要执行权限）
sudo bash deploy/deploy.sh

# 或者使用完整路径
sudo bash /opt/qk/deploy/deploy.sh
```

### 方案 4：检查文件路径

确保你在正确的目录：

```bash
# 查看当前目录
pwd

# 如果不在项目目录，切换到项目目录
cd /opt/qk  # 替换为你的实际项目路径

# 确认文件存在
ls -la deploy/deploy.sh

# 然后运行
sudo ./deploy/deploy.sh
```

### 方案 5：检查文件内容

如果文件损坏或为空：

```bash
# 查看文件前几行（应该看到 #!/bin/bash）
head -n 5 deploy/deploy.sh

# 查看文件大小（不应该是 0）
ls -lh deploy/deploy.sh
```

如果文件为空或损坏，需要重新上传文件。

## 🚀 完整修复流程（推荐）

按顺序执行以下命令：

```bash
# 1. 进入项目目录
cd /opt/qk  # 替换为你的实际路径

# 2. 检查文件是否存在
ls -la deploy/deploy.sh

# 3. 修复行结束符（如果从 Windows 上传）
sudo apt install dos2unix -y  # 如果没有安装
dos2unix deploy/deploy.sh

# 4. 添加执行权限
chmod +x deploy/deploy.sh

# 5. 验证权限
ls -l deploy/deploy.sh

# 6. 运行脚本
sudo ./deploy/deploy.sh
```

## 🔧 替代方法：手动部署

如果脚本始终无法运行，可以按照部署文档手动执行每个步骤：

1. 查看 [DEPLOYMENT.md](DEPLOYMENT.md) 中的"方式一：传统部署"部分
2. 或者查看 [QUICK_START_DEPLOY.md](QUICK_START_DEPLOY.md) 中的"方式二：手动部署"

手动部署虽然步骤多一点，但更可控，也更容易排查问题。

## 📝 常见错误信息对照

| 错误信息 | 原因 | 解决方法 |
|---------|------|---------|
| `command not found` | 没有执行权限或路径错误 | `chmod +x deploy/deploy.sh` |
| `bad interpreter` | 行结束符问题 | `dos2unix deploy/deploy.sh` |
| `Permission denied` | 没有执行权限 | `chmod +x deploy/deploy.sh` |
| `No such file or directory` | 文件不存在或路径错误 | 检查 `ls -la deploy/deploy.sh` |

## 💡 预防措施

为了避免这个问题，上传文件到服务器时：

1. **使用 Git**（推荐）：
   ```bash
   git clone 你的仓库地址
   ```

2. **使用 SFTP/SCP 时注意**：
   - 确保文件完整性
   - 上传后检查文件大小
   - 记得添加执行权限：`chmod +x deploy/deploy.sh`

3. **在服务器上直接创建**（如果有条件）：
   ```bash
   # 使用 cat 或其他方式直接创建脚本
   ```

---

如果以上方法都无法解决，请检查：
- 脚本文件是否完整上传
- 服务器系统是否支持 bash（`which bash`）
- 是否有足够的权限（`whoami`）




