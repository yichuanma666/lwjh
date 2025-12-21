import os
import re
from pathlib import Path
from typing import List, Optional

import requests

from .aggregator import aggregate_search, build_sources
from .config import load_config
from .models import Paper
from .rate_limiter import SimpleRateLimiter


def _safe_filename(text: str, max_len: int = 80) -> str:
    text = re.sub(r"[\\/:*?\"<>|]", "_", text)
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) > max_len:
        text = text[: max_len - 3] + "..."
    return text or "paper"


def download_arxiv_pdfs(
    query: str,
    from_year: Optional[int] = None,
    max_results: int = 50,
    output_dir: str = "downloads/arxiv",
) -> None:
    """
    按当前聚合逻辑搜索，但仅下载 arXiv 论文的 PDF 到本地目录。
    仅用于个人学习，请勿大规模、频繁请求。
    """
    cfg = load_config(None)
    sources = build_sources(cfg)

    papers: List[Paper] = aggregate_search(
        query=query,
        sources=sources,
        max_results=max_results,
        from_year=from_year,
    )

    arxiv_papers = [p for p in papers if p.source == "arxiv" and p.extra.get("pdf_url")]
    if not arxiv_papers:
        print("没有找到可下载的 arXiv 论文。")
        return

    out_dir = Path(output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    # 额外限速，避免请求过快
    limiter = SimpleRateLimiter(max_calls=5, period=60.0)

    print(f"共 {len(arxiv_papers)} 篇 arXiv 论文，将下载到: {out_dir.resolve()}")
    for idx, p in enumerate(arxiv_papers, start=1):
        pdf_url = p.extra["pdf_url"]
        safe_title = _safe_filename(p.title or p.id)
        filename = out_dir / f"{safe_title}.pdf"

        if filename.exists():
            print(f"[{idx}/{len(arxiv_papers)}] 已存在，跳过: {filename.name}")
            continue

        print(f"[{idx}/{len(arxiv_papers)}] 下载: {pdf_url}")
        limiter.acquire()
        try:
            resp = requests.get(pdf_url, timeout=60)
            resp.raise_for_status()
            with open(filename, "wb") as f:
                f.write(resp.content)
        except Exception as e:
            print(f"下载失败: {pdf_url} -> {e}")

    print("下载完成。")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="根据搜索条件批量爬取（下载）arXiv 论文 PDF（仅供个人学习使用）"
    )
    parser.add_argument("--query", "-q", required=True, type=str, help="搜索关键词")
    parser.add_argument("--from-year", type=int, default=None, help="只下载该年份之后的论文")
    parser.add_argument("--max-results", type=int, default=50, help="每个源最大结果数")
    parser.add_argument(
        "--output-dir",
        type=str,
        default="downloads/arxiv",
        help="PDF 保存目录",
    )
    args = parser.parse_args()

    download_arxiv_pdfs(
        query=args.query,
        from_year=args.from_year,
        max_results=args.max_results,
        output_dir=args.output_dir,
    )






