from __future__ import annotations

import re
import unicodedata

CONTROL_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")
ZERO_WIDTH_RE = re.compile(r"[\u200b-\u200f\u202a-\u202e\ufeff]")

UNTRUSTED_OPEN = "<UNTRUSTED_PROFILE_TEXT>"
UNTRUSTED_CLOSE = "</UNTRUSTED_PROFILE_TEXT>"


def sanitize_text(value: str) -> str:
    text = unicodedata.normalize("NFKC", value or "")
    text = ZERO_WIDTH_RE.sub("", text)
    text = CONTROL_RE.sub("", text)
    return text.strip()


def wrap_untrusted(value: str) -> str:
    inner = sanitize_text(value).replace(UNTRUSTED_OPEN, "").replace(UNTRUSTED_CLOSE, "")
    return f"{UNTRUSTED_OPEN}\n{inner}\n{UNTRUSTED_CLOSE}"
