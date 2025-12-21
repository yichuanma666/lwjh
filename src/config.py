from pathlib import Path
from typing import Any, Dict

import yaml


def load_config(path: str | None = None) -> Dict[str, Any]:
    """
    加载 YAML 配置，默认读取项目根目录下的 config.yml。
    """
    if path is None:
        path = "config.yml"

    cfg_path = Path(path)
    if not cfg_path.exists():
        raise FileNotFoundError(
            f"Config file '{path}' not found. 请先复制 config.example.yml 为 config.yml 并根据需要修改。"
        )

    with cfg_path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    # 兼容顶层 default 节点
    if "default" in data:
        return data["default"]
    return data


