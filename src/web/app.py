from pathlib import Path
from typing import List, Optional
import io
import csv

from fastapi import FastAPI, Form, Request
from fastapi.responses import HTMLResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from ..aggregator import aggregate_search, build_sources
from ..config import load_config
from ..models import Paper

BASE_DIR = Path(__file__).resolve().parent.parent.parent
TEMPLATES_DIR = BASE_DIR / "templates"
STATIC_DIR = BASE_DIR / "static"


app = FastAPI(title="论文聚合搜索 Web 界面")

app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")
templates = Jinja2Templates(directory=TEMPLATES_DIR)


@app.get("/", response_class=HTMLResponse)
async def index(request: Request) -> HTMLResponse:
    return templates.TemplateResponse(
        "index.html",
        {
            "request": request,
            "query": "",
            "title_filter": "",
            "from_year": "",
            "max_results": 30,
            "sources": [],
            "available_sources": ["arxiv", "crossref", "semantic_scholar"],
            "papers": [],
            "error": None,
        },
    )


@app.post("/search", response_class=HTMLResponse)
async def search(
    request: Request,
    query: str = Form(...),
    from_year: Optional[str] = Form(None),
    title_filter: Optional[str] = Form(None),
    max_results: int = Form(30),
    sources: Optional[List[str]] = Form(None),
) -> HTMLResponse:
    cfg = load_config(None)
    if sources:
        cfg["enabled_sources"] = sources

    # 处理 from_year: 空字符串或 None 转为 None，否则转为整数
    from_year_int: Optional[int] = None
    if from_year and from_year.strip():
        try:
            from_year_int = int(from_year.strip())
        except ValueError:
            from_year_int = None

    try:
        src_instances = build_sources(cfg)
        papers: List[Paper] = aggregate_search(
            query=query,
            sources=src_instances,
            max_results=max_results,
            from_year=from_year_int,
        )
        # 题目进一步筛选
        if title_filter and title_filter.strip():
            key = title_filter.strip().lower()
            papers = [
                p for p in papers if key in (p.title or "").lower()
            ]
        error = None
    except Exception as e:
        papers = []
        error = str(e)

    return templates.TemplateResponse(
        "index.html",
        {
            "request": request,
            "query": query,
            "title_filter": title_filter or "",
            "from_year": from_year_int if from_year_int else "",
            "max_results": max_results,
            "sources": sources or [],
            "available_sources": ["arxiv", "crossref", "semantic_scholar"],
            "papers": papers,
            "error": error,
        },
    )


@app.post("/download")
async def download(
    request: Request,
    query: str = Form(...),
    from_year: Optional[str] = Form(None),
    title_filter: Optional[str] = Form(None),
    max_results: int = Form(30),
    sources: Optional[List[str]] = Form(None),
):
    """
    根据当前表单条件重新检索，并将结果导出为 CSV 文件下载。
    """
    cfg = load_config(None)
    if sources:
        cfg["enabled_sources"] = sources

    from_year_int: Optional[int] = None
    if from_year and str(from_year).strip():
        try:
            from_year_int = int(str(from_year).strip())
        except ValueError:
            from_year_int = None

    src_instances = build_sources(cfg)
    papers: List[Paper] = aggregate_search(
        query=query,
        sources=src_instances,
        max_results=max_results,
        from_year=from_year_int,
    )

    if title_filter and title_filter.strip():
        key = title_filter.strip().lower()
        papers = [p for p in papers if key in (p.title or "").lower()]

    # 生成内存中的 CSV
    output = io.StringIO(newline="")
    writer = csv.writer(output)
    writer.writerow(["title", "authors", "year", "source", "doi", "url", "journal", "abstract"])
    for p in papers:
        authors = ", ".join(p.authors)
        year = p.published_at.year if p.published_at else ""
        writer.writerow(
            [
                p.title,
                authors,
                year,
                p.source,
                p.doi or "",
                p.url or "",
                p.journal or "",
                (p.abstract or "").replace("\n", " "),
            ]
        )

    output.seek(0)
    filename = f"papers_{query.replace(' ', '_')}.csv"
    headers = {
        "Content-Disposition": f'attachment; filename="{filename}"'
    }
    return StreamingResponse(output, media_type="text/csv; charset=utf-8", headers=headers)


