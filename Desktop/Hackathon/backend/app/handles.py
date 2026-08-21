from __future__ import annotations

import re

HANDLE_RE = re.compile(
    r"(?:https?://)?(?:www\.)?instagram\.com/([A-Za-z0-9._]+)/?.*",
    re.I,
)
BARE_HANDLE_RE = re.compile(r"^@?([A-Za-z0-9._]{1,30})$")


def extract_handle(value: str) -> str | None:
    text = (value or "").strip()
    match = HANDLE_RE.match(text)
    if match:
        handle = match.group(1).lower()
        if handle in {"p", "reel", "reels", "stories", "explore"}:
            return None
        return handle
    match = BARE_HANDLE_RE.match(text)
    if match:
        return match.group(1).lower()
    return None
