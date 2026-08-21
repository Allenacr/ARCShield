from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path

from app.models import NormalizedProfile

DATA_PATH = Path(__file__).parent / "data" / "demo_cases.json"


@lru_cache(maxsize=1)
def load_cases() -> dict[str, NormalizedProfile]:
    payload = json.loads(DATA_PATH.read_text(encoding="utf-8"))
    cases: dict[str, NormalizedProfile] = {}
    for raw in payload["cases"]:
        profile = NormalizedProfile.model_validate({**raw, "source": "demo"})
        cases[profile.handle.lower()] = profile
    return cases


def list_handles() -> list[str]:
    return sorted(load_cases().keys())


def get_demo(handle: str) -> NormalizedProfile | None:
    return load_cases().get(handle.lower())
