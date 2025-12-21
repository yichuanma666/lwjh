import argparse
from typing import List

from .aggregator import aggregate_search, build_sources
from .config import load_config
from .models import Paper
from .storage import save_papers


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="多源论文聚合/爬取工具（arXiv / CrossRef / Semantic Scholar 等）",
    )
    parser.add_argument("--query", "-q", type=str, required=True, help="搜索关键词，如: \"large language model\"")
    parser.add_argument("--max-results", "-m", type=int, default=50, help="每个源最多返回多少条结果")
    parser.add_argument("--from-year", type=int, default=None, help="仅保留该年份之后的论文")
    parser.add_argument(
        "--sources",
        nargs="*",
        default=None,
        help="指定要启用的数据源名称列表，如: arxiv crossref semantic_scholar；默认使用配置文件设置。",
    )
    parser.add_argument(
        "--storage-backend",
        choices=["csv", "json"],
        default=None,
        help="存储后端，默认读取配置文件（csv/json）。",
    )
    parser.add_argument(
        "--output-path",
        type=str,
        default=None,
        help="输出文件路径，默认读取配置文件。",
    )
    parser.add_argument(
        "--config",
        type=str,
        default=None,
        help="配置文件路径，默认使用项目根目录下的 config.yml。",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    cfg = load_config(args.config)

    if args.sources:
        cfg["enabled_sources"] = args.sources

    sources = build_sources(cfg)
    if not sources:
        raise RuntimeError("没有启用任何数据源，请检查 config.yml 中的 enabled_sources 配置。")

    print(f"使用数据源: {[s.name for s in sources]}")
    print(f"正在搜索: {args.query!r}，每源最多 {args.max_results} 条……")

    papers: List[Paper] = aggregate_search(
        query=args.query,
        sources=sources,
        max_results=args.max_results,
        from_year=args.from_year,
    )

    print(f"共获取到去重后论文数: {len(papers)}")

    storage_cfg = cfg.get("storage", {}) or {}
    backend = args.storage_backend or storage_cfg.get("backend", "csv")
    output_path = args.output_path or storage_cfg.get("output_path", "data/results.csv")

    save_papers(papers, backend=backend, output_path=output_path)
    print(f"结果已保存到: {output_path}，格式: {backend}")


if __name__ == "__main__":
    main()






