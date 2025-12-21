"""
论文 PDF 下载器（仅限开放获取论文）

⚠️ 合规说明：
- 本工具仅下载开放获取（Open Access）论文
- 对于收费期刊论文，只提供元数据和合法访问链接
- 请勿使用本工具绕过付费墙或违反版权法
- 使用前请确保遵守各期刊和数据库的服务条款
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Optional
from urllib.parse import urlparse

import requests
from tenacity import retry, stop_after_attempt, wait_exponential

from .models import Paper
from .rate_limiter import SimpleRateLimiter


class PDFDownloader:
    """PDF 下载器，仅处理开放获取论文"""

    def __init__(self, rate_limiter: Optional[SimpleRateLimiter] = None, output_dir: str = "downloads"):
        self.rate_limiter = rate_limiter
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def is_open_access(self, paper: Paper) -> bool:
        """检查论文是否为开放获取"""
        # arXiv 默认都是开放获取
        if paper.source == "arxiv":
            return True
        
        # 从 extra 字段检查
        return paper.extra.get("is_open_access", False)

    def get_pdf_url(self, paper: Paper) -> Optional[str]:
        """获取论文的 PDF URL（仅限开放获取）"""
        if not self.is_open_access(paper):
            return None

        # 优先使用 extra 中的 pdf_url
        if paper.extra.get("pdf_url"):
            return paper.extra["pdf_url"]

        # arXiv 论文
        if paper.source == "arxiv" and paper.url:
            # 将 /abs/ 替换为 /pdf/，并确保以 .pdf 结尾
            pdf_url = paper.url.replace("/abs/", "/pdf/")
            if not pdf_url.endswith(".pdf"):
                pdf_url = pdf_url + ".pdf"
            return pdf_url

        # DOI 解析（尝试通过 DOI 获取开放获取 PDF）
        if paper.doi:
            # 尝试通过 DOI 解析服务获取 PDF
            doi_url = f"https://doi.org/{paper.doi}"
            # 某些开放获取论文可能通过 DOI 解析器提供 PDF
            # 但这里不直接下载，而是返回 DOI URL 让用户访问
            return None

        return None

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=2, max=10))
    def download_pdf(self, paper: Paper, filename: Optional[str] = None) -> Optional[Path]:
        """
        下载论文 PDF（仅限开放获取）
        
        返回下载的文件路径，如果失败返回 None
        """
        if not self.is_open_access(paper):
            raise ValueError(f"论文 '{paper.title}' 不是开放获取，无法下载")

        pdf_url = self.get_pdf_url(paper)
        if not pdf_url:
            return None

        # 生成文件名
        if not filename:
            # 使用标题生成安全的文件名
            safe_title = re.sub(r'[^\w\s-]', '', paper.title)[:100]
            safe_title = re.sub(r'[-\s]+', '-', safe_title)
            filename = f"{safe_title}.pdf"
        
        output_path = self.output_dir / filename

        # 限速
        if self.rate_limiter:
            self.rate_limiter.acquire()

        # 下载 PDF
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        }
        resp = requests.get(pdf_url, headers=headers, timeout=60, stream=True)
        resp.raise_for_status()

        # 检查内容类型
        content_type = resp.headers.get("content-type", "").lower()
        if "pdf" not in content_type and not pdf_url.endswith(".pdf"):
            # 可能不是 PDF，返回 None
            return None

        # 保存文件
        with open(output_path, "wb") as f:
            for chunk in resp.iter_content(chunk_size=8192):
                f.write(chunk)

        return output_path

    def download_multiple(self, papers: list[Paper], progress_callback=None) -> dict[str, Optional[Path]]:
        """
        批量下载多篇论文的 PDF（仅限开放获取）
        
        progress_callback: 可选的回调函数，接收 (current, total, paper_title, success) 参数
        """
        results = {}
        total = len(papers)
        
        for idx, paper in enumerate(papers):
            try:
                if progress_callback:
                    progress_callback(idx + 1, total, paper.title, None)  # None 表示进行中
                
                path = self.download_pdf(paper)
                results[paper.id] = path
                
                if progress_callback:
                    progress_callback(idx + 1, total, paper.title, path is not None)
            except Exception as e:
                results[paper.id] = None
                if progress_callback:
                    progress_callback(idx + 1, total, paper.title, False)
        
        return results





