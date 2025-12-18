# 解决 "nano: command not found" 错误

## 快速解决方案（3 选 1）

### ✅ 方案 1：安装 nano（最简单，推荐）

```bash
# Ubuntu/Debian 系统
sudo apt install nano -y

# CentOS/RHEL 系统  
sudo yum install nano -y
```

安装后就可以正常使用 `nano` 命令了。

---

### ✅ 方案 2：使用 vi（系统通常自带）

如果无法安装软件，可以使用系统自带的 `vi` 编辑器：

```bash
# 用 vi 打开文件
vi config.yml

# vi 基本操作：
# 1. 按 'i' 键 → 进入编辑模式（可以输入文字了）
# 2. 编辑完成后，按 'Esc' 键 → 退出编辑模式
# 3. 输入 ':wq' → 保存并退出（按 Enter 确认）
# 4. 如果不想保存：按 'Esc' 后输入 ':q!' → 强制退出
```

**vi 快速参考**：
- `i` - 进入插入模式（开始编辑）
- `Esc` - 退出插入模式
- `:wq` - 保存并退出（write and quit）
- `:q!` - 不保存退出（quit without saving）

---

### ✅ 方案 3：使用 vim

如果系统有 vim（vi 的增强版）：

```bash
vim config.yml
```

操作方式和 vi 相同。

---

## 详细说明

完整的使用指南请查看：[EDITOR_GUIDE.md](EDITOR_GUIDE.md)

---

## 示例：编辑配置文件

假设你要编辑 `config.yml` 文件：

### 使用 nano：
```bash
nano config.yml
# 编辑后按 Ctrl+X，然后按 Y 确认，最后按 Enter 保存
```

### 使用 vi：
```bash
vi config.yml
# 按 i 进入编辑模式
# 编辑完成后：
# 1. 按 Esc
# 2. 输入 :wq
# 3. 按 Enter
```

---

## 推荐

**第一次部署**：建议安装 nano，操作更简单直观
```bash
sudo apt install nano -y  # 或 sudo yum install nano -y
```

**紧急情况**：直接使用 vi，系统通常自带，无需安装




