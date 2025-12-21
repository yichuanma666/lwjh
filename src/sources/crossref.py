from __future__ import annotations

from datetime import datetime
from typing import Iterable, Optional

import requests

from ..models import Paper
from ..rate_limiter import SimpleRateLimiter
from .base import BaseSource
from .unpaywall import UnpaywallClient


CROSSREF_API_URL = "https://api.crossref.org/works"


class CrossRefSource(BaseSource):
    name = "crossref"

    def __init__(self, rate_limiter: Optional[SimpleRateLimiter] = None, config: Optional[dict] = None) -> None:
        super().__init__(rate_limiter=rate_limiter, config=config)
        # 初始化 Unpaywall 客户端（如果配置了邮箱）
        unpaywall_email = self.config.get("unpaywall_email")
        if unpaywall_email:
            self.unpaywall = UnpaywallClient(email=unpaywall_email, rate_limiter=rate_limiter)
        else:
            self.unpaywall = None

    def search(
        self,
        query: str,
        max_results: int = 50,
        from_year: Optional[int] = None,
    ) -> Iterable[Paper]:
        params = {
            "query": query,
            "rows": max_results,
        }
        if from_year is not None:
            params["filter"] = f"from-pub-date:{from_year}-01-01"

        headers = {
            "User-Agent": self.config.get(
                "user_agent",
                "AcademicPaperAggregator/0.1 (mailto:your-email@example.com)",
            )
        }

        if self.rate_limiter:
            self.rate_limiter.acquire()
        resp = requests.get(CROSSREF_API_URL, params=params, headers=headers, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        items = data.get("message", {}).get("items", [])

        for item in items:
            yield self._parse_item(item)

    def _parse_item(self, item: dict) -> Paper:
        doi = item.get("DOI", "")
        title_list = item.get("title") or []
        title = title_list[0] if title_list else ""

        abstract = item.get("abstract")

        authors_data = item.get("author") or []
        authors = []
        for a in authors_data:
            given = a.get("given") or ""
            family = a.get("family") or ""
            full = (given + " " + family).strip()
            if full:
                authors.append(full)

        published_at = None
        for key in ["published-print", "published-online", "created"]:
            if key in item and "date-parts" in item[key]:
                try:
                    y, m, d = (item[key]["date-parts"][0] + [1, 1, 1])[:3]
                    published_at = datetime(int(y), int(m), int(d))
                    break
                except Exception:
                    continue

        journal = None
        container = item.get("container-title") or []
        if container:
            journal = container[0]

        url = item.get("URL")

        # 检测开放获取状态
        is_open_access = False
        pdf_url = None
        
        # 检查 license 字段
        license_info = item.get("license", [])
        if license_info:
            for lic in license_info:
                if lic.get("content-version") == "vor" or lic.get("delay") == 0:
                    is_open_access = True
                    # 尝试获取 PDF URL
                    pdf_url = lic.get("URL")
                    break
        
        # 如果没有从 license 获取到，尝试从 link 字段获取
        if not pdf_url:
            links = item.get("link", [])
            for link in links:
                if link.get("content-type") == "application/pdf":
                    pdf_url = link.get("URL")
                    break
                elif link.get("intended-application") == "similarity-checking":
                    # 某些情况下，相似性检查链接可能指向开放获取版本
                    pass

        # 如果 CrossRef 没有检测到开放获取，尝试使用 Unpaywall 检测
        unpaywall_detected = False
        if not is_open_access and doi and self.unpaywall:
            try:
                unpaywall_result = self.unpaywall.check_open_access(doi)
                if unpaywall_result and unpaywall_result.get("is_oa"):
                    is_open_access = True
                    if unpaywall_result.get("pdf_url") and not pdf_url:
                        pdf_url = unpaywall_result["pdf_url"]
                    unpaywall_detected = True
            except Exception:
                # Unpaywall 检测失败，继续使用 CrossRef 的结果
                pass

        extra = {
            "type": item.get("type"),
            "is_open_access": is_open_access,
        }
        if pdf_url:
            extra["pdf_url"] = pdf_url
        if unpaywall_detected:
            extra["unpaywall_detected"] = True

        return Paper(
            id=doi or url or title,
            title=title,
            abstract=abstract,
            authors=authors,
            published_at=published_at,
            source=self.name,
            url=url,
            doi=doi,
            journal=journal,
            extra=extra,
        )


