from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Iterable, Optional

from ..models import Paper


class BaseSource(ABC):
    """
    所有论文源的抽象基类。
    """

    name: str

    def __init__(self, rate_limiter=None, config: Optional[dict] = None) -> None:
        self.rate_limiter = rate_limiter
        self.config = config or {}

    @abstractmethod
    def search(
        self,
        query: str,
        max_results: int = 50,
        from_year: Optional[int] = None,
    ) -> Iterable[Paper]:
        """
        按关键词和可选年份范围搜索论文。
        """


