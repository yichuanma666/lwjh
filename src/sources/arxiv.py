from __future__ import annotations

from datetime import datetime
from typing import Iterable, Optional

import requests
from xml.etree import ElementTree as ET

from ..models import Paper
from ..rate_limiter import SimpleRateLimiter
from .base import BaseSource


ARXIV_API_URL = "http://export.arxiv.org/api/query"


class ArxivSource(BaseSource):
    name = "arxiv"

    def __init__(self, rate_limiter: Optional[SimpleRateLimiter] = None, config: Optional[dict] = None) -> None:
        super().__init__(rate_limiter=rate_limiter, config=config)

    def search(
        self,
        query: str,
        max_results: int = 50,
        from_year: Optional[int] = None,
    ) -> Iterable[Paper]:
        params = {
            "search_query": f"all:{query}",
            "start": 0,
            "max_results": max_results,
        }
        if self.rate_limiter:
            self.rate_limiter.acquire()
        resp = requests.get(ARXIV_API_URL, params=params, timeout=30)
        resp.raise_for_status()

        root = ET.fromstring(resp.text)
        ns = {"atom": "http://www.w3.org/2005/Atom"}
        for entry in root.findall("atom:entry", ns):
            yield self._parse_entry(entry, from_year)

    def _parse_entry(self, entry, from_year: Optional[int]) -> Paper:
        def _text(elem, tag: str) -> Optional[str]:
            ns = "{http://www.w3.org/2005/Atom}"
            found = elem.find(f"{ns}{tag}")
            return found.text if found is not None else None

        ns = "{http://www.w3.org/2005/Atom}"
        arxiv_id = _text(entry, "id") or ""
        title = (_text(entry, "title") or "").strip().replace("\n", " ")
        abstract = (_text(entry, "summary") or "").strip()

        authors = [
            (a.find(f"{ns}name").text or "").strip()
            for a in entry.findall(f"{ns}author")
            if a.find(f"{ns}name") is not None
        ]

        published_raw = _text(entry, "published")
        published_at = None
        if published_raw:
            try:
                published_at = datetime.fromisoformat(published_raw.replace("Z", "+00:00"))
            except Exception:
                published_at = None

        # 构造 PDF 下载链接（仅用于前端一键跳转，不做代理下载）
        extra = {}
        if arxiv_id:
            pdf_url = arxiv_id.replace("/abs/", "/pdf/")
            if not pdf_url.endswith(".pdf"):
                pdf_url = pdf_url + ".pdf"
            extra["pdf_url"] = pdf_url

        # from_year 过滤在外层调用处处理，以保持逻辑简单
        return Paper(
            id=arxiv_id,
            title=title,
            abstract=abstract,
            authors=authors,
            published_at=published_at,
            source=self.name,
            url=arxiv_id,
            doi=None,
            journal=None,
            extra=extra,
        )


