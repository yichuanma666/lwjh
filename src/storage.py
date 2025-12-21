from pathlib import Path
from typing import Iterable, Literal

from .models import Paper


def save_papers(
    papers: Iterable[Paper],
    backend: Literal["csv", "json"] = "csv",
    output_path: str = "data/results.csv",
) -> None:
    """
    将论文列表保存到本地文件。
    目前支持 csv / json，后续可扩展为 sqlite。
    """
    path = Path(output_path)
    path.parent.mkdir(parents=True, exist_ok=True)

    if backend == "csv":
        _save_csv(papers, path)
    elif backend == "json":
        _save_json(papers, path)
    else:
        raise ValueError(f"Unsupported backend: {backend}")


def _paper_to_dict(p: Paper) -> dict:
    return {
        "id": p.id,
        "title": p.title,
        "abstract": p.abstract,
        "authors": "; ".join(p.authors),
        "published_at": p.published_at.isoformat() if p.published_at else None,
        "source": p.source,
        "url": p.url,
        "doi": p.doi,
        "journal": p.journal,
        **{f"extra_{k}": v for k, v in p.extra.items()},
    }


def _save_csv(papers: Iterable[Paper], path: Path) -> None:
    import csv

    rows = [_paper_to_dict(p) for p in papers]
    if not rows:
        return

    fieldnames = sorted(rows[0].keys())
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def _save_json(papers: Iterable[Paper], path: Path) -> None:
    import json

    rows = [_paper_to_dict(p) for p in papers]
    with path.open("w", encoding="utf-8") as f:
        json.dump(rows, f, ensure_ascii=False, indent=2)


