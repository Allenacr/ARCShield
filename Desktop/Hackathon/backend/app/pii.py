from __future__ import annotations

import re

from app.models import PiiHit

EMAIL_RE = re.compile(r"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}", re.I)
PHONE_RE = re.compile(
    r"(?:\+?\d{1,3}[\s.-]?)?(?:\(?\d{2,4}\)?[\s.-]?)?\d{3}[\s.-]?\d{4}"
)


def redact_span(text: str, start: int, end: int) -> str:
    return text[:start] + "█" * max(4, end - start) + text[end:]


def find_pii(locator: str, text: str) -> tuple[str, list[PiiHit]]:
    hits: list[PiiHit] = []
    redacted = text
    for match in reversed(list(EMAIL_RE.finditer(text))):
        hits.append(PiiHit(kind="email", locator=locator, redacted="[REDACTED EMAIL]"))
        redacted = redact_span(redacted, match.start(), match.end())

    for match in reversed(list(PHONE_RE.finditer(redacted))):
        snippet = match.group(0)
        digits = re.sub(r"\D", "", snippet)
        if len(digits) < 10:
            continue
        hits.append(PiiHit(kind="phone", locator=locator, redacted="[REDACTED PHONE]"))
        redacted = redact_span(redacted, match.start(), match.end())
    return redacted, hits


def redact_profile_texts(
    bio: str, captions: list[tuple[str, str]]
) -> tuple[str, list[tuple[str, str]], list[PiiHit]]:
    all_hits: list[PiiHit] = []
    bio_out, hits = find_pii("bio", bio)
    all_hits.extend(hits)
    out_caps: list[tuple[str, str]] = []
    for post_id, caption in captions:
        cap_out, cap_hits = find_pii(f"caption:{post_id}", caption)
        all_hits.extend(cap_hits)
        out_caps.append((post_id, cap_out))
    return bio_out, out_caps, all_hits
