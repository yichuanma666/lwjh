from __future__ import annotations

from typing import Dict, Iterable, List, Optional, Sequence

from .models import Paper
from .rate_limiter import SimpleRateLimiter
from .sources.arxiv import ArxivSource
from .sources.base import BaseSource
from .sources.crossref import CrossRefSource
from .sources.semantic_scholar import SemanticScholarSource


def build_sources(config: Dict) -> List[BaseSource]:
    """
    根据配置初始化启用的数据源实例。
    """
    enabled = config.get("enabled_sources", ["arxiv", "crossref"])
    rate_cfg = config.get("rate_limit", {}) or {}
    rpm = int(rate_cfg.get("requests_per_minute", 20))
    limiter = SimpleRateLimiter(max_calls=max(1, rpm), period=60.0)

    sources_cfg = config.get("sources", {}) or {}

    instances: List[BaseSource] = []
    for name in enabled:
        name_lower = name.lower()
        if name_lower == "arxiv":
            instances.append(ArxivSource(rate_limiter=limiter, config=sources_cfg.get("arxiv") or {}))
        elif name_lower == "crossref":
            instances.append(CrossRefSource(rate_limiter=limiter, config=sources_cfg.get("crossref") or {}))
        elif name_lower in ("semantic_scholar", "semanticscholar"):
            instances.append(
                SemanticScholarSource(
                    rate_limiter=limiter,
                    config=sources_cfg.get("semantic_scholar") or {},
                )
            )
        else:
            # 未知源暂时忽略
            continue
    return instances


def aggregate_search(
    query: str,
    sources: Sequence[BaseSource],
    max_results: int = 50,
    from_year: Optional[int] = None,
) -> List[Paper]:
    """
    在多个数据源上执行搜索，并将结果合并为一个列表。
    简单去重策略：按 (doi 或 标题+年份+首位作者) 去重。
    """
    all_papers: List[Paper] = []
    seen_keys: Dict[str, bool] = {}

    for src in sources:
        try:
            for paper in src.search(query=query, max_results=max_results, from_year=from_year):
                key = _dedup_key(paper)
                if key in seen_keys:
                    continue
                seen_keys[key] = True
                all_papers.append(paper)
        except Exception as e:
            # 日志可以后续接入 logging，这里简单打印或忽略
            print(f"[WARN] Source {src.name} failed: {e}")

    return all_papers


def _dedup_key(paper: Paper) -> str:
    if paper.doi:
        return f"doi:{paper.doi.lower()}"
    first_author = paper.authors[0].lower() if paper.authors else ""
    year = paper.published_at.year if paper.published_at else 0
    return f"title:{paper.title.lower()}|author:{first_author}|year:{year}"






