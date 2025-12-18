## 论文聚合/爬取项目（Python）

> 本项目旨在 **合规地聚合和检索多源学术论文元数据**，优先通过公开 API（如 arXiv、CrossRef、Semantic Scholar 等）获取数据，并预留扩展到网页爬取的接口。请在使用前务必阅读各数据源的使用条款和 robots.txt。

### 功能概览

- **多数据源检索**：支持从多个论文源按关键词、作者、时间范围等查询论文元数据。
- **统一结果格式**：不同来源的结果统一成一个标准结构，便于后续分析和存储。
- **本地存储**：支持保存为 CSV / JSON，预留 SQLite 支持。
- **速率限制与合规**：内置简单的限速机制，提醒遵守各 API / 网站使用条款。
- **可扩展架构**：新增数据源只需实现统一接口并在配置文件中启用。
- **开放获取论文下载**：自动识别开放获取（Open Access）论文，支持一键下载 PDF（仅限合法公开的论文）。
- **Unpaywall 集成**：集成了 Unpaywall API，通过 DOI 自动检测论文的开放获取版本，最大化发现合法的免费 PDF。
- **收费期刊元数据爬取**：可以检索收费期刊的元数据（标题、作者、摘要等），但仅提供合法访问链接，不绕过付费墙。

### 目录结构（建议）

- `README.md`：项目说明
- `requirements.txt`：Python 依赖
- `config.example.yml`：示例配置
- `src/`
  - `main.py`：命令行入口
  - `web/app.py`：FastAPI Web 服务入口
  - `config.py`：配置加载
  - `models.py`：统一论文数据模型
  - `storage.py`：结果存储（CSV/JSON/SQLite）
  - `rate_limiter.py`：简单限速器
  - `sources/`
    - `base.py`：数据源抽象基类
    - `arxiv.py`：arXiv 客户端
  - `crossref.py`：CrossRef 客户端
  - `semantic_scholar.py`：Semantic Scholar 客户端（可选，需要 API key）
- `templates/`：Web 页面模板（Jinja2）
- `static/`：前端样式等静态文件

### 快速开始（命令行）

1. **安装依赖**

   ```bash
   pip install -r requirements.txt
   ```

2. **复制并修改配置**

   ```bash
   copy config.example.yml config.yml  # Windows PowerShell 也可使用 cp
   ```

   按需填写 API Key（如 Semantic Scholar）、Unpaywall 邮箱（用于检测开放获取论文），调整默认搜索参数和限速设置。

3. **运行示例搜索**

   ```bash
   python -m src.main --query "large language model" --max-results 50 --sources arxiv crossref

### 启动交互式 Web 网页

1. **安装依赖**（如果前面已经装过可以跳过）

   ```bash
   pip install -r requirements.txt
   ```

2. **确保有配置文件**

   ```bash
   copy config.example.yml config.yml
   ```

3. **启动 Web 服务（开发模式）**

   在项目根目录 `qk` 下运行：

   ```bash
   uvicorn src.web.app:app --reload --port 8000
   ```

4. **用浏览器打开**

   在浏览器访问：`http://127.0.0.1:8000`

   页面上可以：
   - 输入关键词、题目包含（可选筛选）、起始年份、每源最大条数；
   - 勾选要使用的数据源（arxiv / crossref / semantic_scholar）；
   - 点击搜索按钮，下面会列出去重后的论文列表，标题可直接点开原文链接；
   - 对于开放获取论文，会显示“开放获取”徽章，并提供“下载 PDF”按钮；
   - 对于收费期刊论文，会显示“收费期刊”标签，仅提供元数据和合法访问链接；
   - 可以导出搜索结果为 CSV 文件，或批量下载开放获取论文的 PDF。
   ```

   结果会默认输出到控制台，并可通过参数指定输出文件格式与路径。

### 合规、风控与“全网爬取”的现实限制

- 本项目仅提供技术示例，**不会也不建议“无差别全网爬取”**。正确姿势是：
  - 优先使用各大论文源**官方开放 API**（本项目已经接入的就是这类接口）；
  - 如果必须做网页爬取，只针对**少量、特定站点**，并且要拿到明确授权或确保条款允许。
- 使用任何特定数据源前，请自行阅读并遵守其：
  - 服务条款（Terms of Service）
  - robots.txt
  - API 使用规范和速率限制
- 如需实现“真正的网页爬虫”（非 API），务必：
  - 尊重 robots.txt；
  - 控制访问频率，不对服务造成负担；
  - 避免抓取受版权或登录保护的全文，仅限元数据或允许的内容。

### ⚠️ 关于收费期刊和开放获取论文

- **开放获取论文**：本工具会自动识别开放获取（Open Access）论文，并提供 PDF 下载功能。这些论文是合法公开的，可以自由下载。
- **Unpaywall 集成**：
  - 本工具集成了 **Unpaywall API**，这是一个合法的开放获取检测服务
  - 通过 DOI 自动查找论文的开放获取版本（包括作者上传到机构库、预印本服务器等）
  - 这有助于最大化发现合法的免费 PDF，而不需要绕过任何付费墙
  - 需要在 `config.yml` 中配置有效的邮箱地址（用于 API 使用统计）
- **收费期刊论文**：对于收费期刊，本工具**仅提供元数据检索**（标题、作者、摘要、DOI 等），不提供全文下载。用户需要通过合法途径（如机构订阅、付费购买）访问全文。
- **合规要求**：
  - 本工具**不会绕过付费墙**或违反版权法
  - 请勿使用本工具批量下载收费期刊的全文
  - 使用前请确保遵守各期刊和数据库的服务条款
  - 仅下载开放获取论文，或通过合法途径访问收费论文
  - Unpaywall 仅查找合法的开放获取版本，不提供任何绕过付费墙的功能

### 服务器部署

需要将项目部署到生产服务器？请查看详细的部署指南：

- 📖 **[部署文档 (DEPLOYMENT.md)](DEPLOYMENT.md)** - 包含完整的部署步骤、配置说明和常见问题解答

支持的部署方式：
- **传统部署**：Systemd + Nginx（推荐用于生产环境）
- **Docker 部署**：使用 Docker 和 Docker Compose 快速部署
- **云平台部署**：适用于阿里云、腾讯云、AWS 等

### 后续可扩展方向

- 增加更多论文源（如：IEEE Xplore、ACM Digital Library 等）——前提是其条款允许自动化访问。
- 实现 Web UI 或 Jupyter Notebook 分析界面。
- 增加全文下载逻辑（仅在合法且被允许的前提下），并增加去重与文献管理功能。
- ✅ **已集成 Unpaywall API**：自动检测论文的开放获取版本，最大化发现合法的免费 PDF。
- 添加文献管理功能（如 BibTeX 导出、引用格式转换等）。


