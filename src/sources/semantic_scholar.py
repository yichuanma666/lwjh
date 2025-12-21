from __future__ import annotations

from datetime import datetime
from typing import Iterable, Optional

import requests

from ..models import Paper
from ..rate_limiter import SimpleRateLimiter
from .base import BaseSource


class SemanticScholarSource(BaseSource):
    name = "semantic_scholar"

    def __init__(self, rate_limiter: Optional[SimpleRateLimiter] = None, config: Optional[dict] = None) -> None:
        super().__init__(rate_limiter=rate_limiter, config=config)
        self.base_url = self.config.get("base_url", "https://api.semanticscholar.org/graph/v1")
        self.api_key = self.config.get("api_key")

    def search(
        self,
        query: str,
        max_results: int = 50,
        from_year: Optional[int] = None,
    ) -> Iterable[Paper]:
        """
        使用 Semantic Scholar 的 /paper/search 接口。
        需要 API Key，且请严格遵守其官方文档的速率限制。
        """
        if not self.api_key:
            raise RuntimeError("Semantic Scholar API Key 未配置，请在 config.yml 中设置 sources.semantic_scholar.api_key")

        url = f"{self.base_url}/paper/search"
        headers = {
            "x-api-key": self.api_key,
        }

        params = {
            "query": query,
            "limit": min(max_results, 100),
            "fields": "title,abstract,authors,year,externalIds,url,journal",
        }
        if from_year is not None:
            params["year"] = f"{from_year}-"

        if self.rate_limiter:
            self.rate_limiter.acquire()
        resp = requests.get(url, headers=headers, params=params, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        papers = data.get("data", [])

        for item in papers:
            yield self._parse_item(item)

    def _parse_item(self, item: dict) -> Paper:
        paper_id = item.get("paperId") or item.get("url") or ""
        title = item.get("title") or ""
        abstract = item.get("abstract")
        year = item.get("year")
        published_at = None
        if year:
            try:
                published_at = datetime(int(year), 1, 1)
            except Exception:
                published_at = None

        authors = [a.get("name", "") for a in item.get("authors") or [] if a.get("name")]

        external_ids = item.get("externalIds") or {}
        doi = external_ids.get("DOI")

        journal = None
        if isinstance(item.get("journal"), dict):
            journal = item["journal"].get("name")

        url = item.get("url")

        return Paper(
            id=paper_id,
            title=title,
            abstract=abstract,
            authors=authors,
            published_at=published_at,
            source=self.name,
            url=url,
            doi=doi,
            journal=journal,
        )


