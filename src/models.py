from dataclasses import dataclass, field
from datetime import datetime
from typing import List, Optional


@dataclass
class Paper:
    """
    统一的论文数据模型，不同数据源的结果都会被转换为此结构。
    """

    id: str
    title: str
    abstract: Optional[str]
    authors: List[str]
    published_at: Optional[datetime]
    source: str  # 数据源标识，如 "arxiv"、"crossref"
    url: Optional[str] = None
    doi: Optional[str] = None
    journal: Optional[str] = None
    extra: dict = field(default_factory=dict)


