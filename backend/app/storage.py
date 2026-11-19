import json
import os
import threading
from typing import Dict, Any

_STORE_LOCK = threading.RLock()
STATE_FILE_PATH = os.environ.get("PAYNORA_STATE_FILE", "/data/paynora_state.json")


def _resolve_path() -> str:
    """Use /data/paynora_state.json in Docker if writable, otherwise local data directory."""
    target = STATE_FILE_PATH
    parent = os.path.dirname(target) or "."
    try:
        os.makedirs(parent, exist_ok=True)
        if os.access(parent, os.W_OK):
            return target
    except Exception:
        pass
    local_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data")
    os.makedirs(local_dir, exist_ok=True)
    return os.path.join(local_dir, "paynora_state.json")


def load_section(section: str, default: Any) -> Any:
    with _STORE_LOCK:
        path = _resolve_path()
        if not os.path.exists(path):
            return default
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            return data.get(section, default)
        except Exception:
            return default


def save_section(section: str, value: Any) -> None:
    with _STORE_LOCK:
        path = _resolve_path()
        data: Dict[str, Any] = {}
        if os.path.exists(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    data = json.load(f)
            except Exception:
                data = {}
        data[section] = value
        tmp_path = f"{path}.tmp"
        try:
            with open(tmp_path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, default=str)
            os.replace(tmp_path, path)
        except Exception:
            pass
