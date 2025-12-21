"""
Unpaywall API 客户端

Unpaywall 是一个合法的开放获取检测服务，通过 DOI 查找论文的开放获取版本。
API 文档：https://unpaywall.org/products/api

⚠️ 合规说明：
- Unpaywall 仅查找合法的开放获取版本，不绕过付费墙
- 需要提供有效的邮箱地址（用于 API 使用统计）
- 请遵守 Unpaywall 的使用条款和速率限制
"""

from __future__ import annotations

from typing import Optional

import requests

from ..rate_limiter import SimpleRateLimiter


UNPAYWALL_API_URL = "https://api.unpaywall.org/v2"


class UnpaywallClient:
    """Unpaywall API 客户端，用于检测开放获取论文"""

    def __init__(
        self,
        email: str = "your-email@example.com",
        rate_limiter: Optional[SimpleRateLimiter] = None,
    ):
        """
        初始化 Unpaywall 客户端

        Args:
            email: 有效的邮箱地址（用于 API 使用统计，建议使用真实邮箱）
            rate_limiter: 可选的速率限制器
        """
        self.email = email
        self.rate_limiter = rate_limiter

    def check_open_access(self, doi: str) -> Optional[dict]:
        """
        通过 DOI 检查论文是否为开放获取，并获取 PDF 链接

        Args:
            doi: 论文的 DOI（例如：10.1038/nature12373）

        Returns:
            如果找到开放获取版本，返回包含以下字段的字典：
            - is_oa: bool，是否为开放获取
            - best_oa_location: dict，最佳开放获取位置（包含 pdf_url）
            - oa_locations: list，所有开放获取位置列表
            如果未找到或出错，返回 None
        """
        if not doi:
            return None

        # 清理 DOI（移除 https://doi.org/ 前缀）
        clean_doi = doi.replace("https://doi.org/", "").replace("http://dx.doi.org/", "").strip()

        if not clean_doi:
            return None

        url = f"{UNPAYWALL_API_URL}/{clean_doi}"
        params = {"email": self.email}

        try:
            if self.rate_limiter:
                self.rate_limiter.acquire()

            resp = requests.get(url, params=params, timeout=10)
            resp.raise_for_status()
            data = resp.json()

            # 检查是否为开放获取
            if not data.get("is_oa", False):
                return None

            # 获取最佳 PDF 链接
            best_location = data.get("best_oa_location")
            pdf_url = None
            if best_location and best_location.get("url_for_pdf"):
                pdf_url = best_location["url_for_pdf"]
            elif best_location and best_location.get("url"):
                # 如果没有专门的 PDF URL，使用通用 URL
                pdf_url = best_location["url"]

            return {
                "is_oa": True,
                "pdf_url": pdf_url,
                "best_oa_location": best_location,
                "oa_locations": data.get("oa_locations", []),
                "year": data.get("year"),
                "title": data.get("title"),
            }
        except requests.exceptions.RequestException:
            # API 调用失败，静默返回 None
            return None
        except Exception:
            return None

    def get_pdf_url(self, doi: str) -> Optional[str]:
        """
        快速获取论文的 PDF URL（如果存在开放获取版本）

        Args:
            doi: 论文的 DOI

        Returns:
            PDF URL，如果不存在则返回 None
        """
        result = self.check_open_access(doi)
        if result and result.get("pdf_url"):
            return result["pdf_url"]
        return None





