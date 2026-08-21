from __future__ import annotations

import re

from app.models import InjectionFlag

PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    ("ignore_prior", re.compile(r"ignore\s+(all\s+)?(previous|prior|all)\s+(instructions|labels|prompts)", re.I)),
    ("system_override", re.compile(r"system\s+override", re.I)),
    ("jailbreak_classify", re.compile(r"(classify|report)\s+this\s+(account|business)\s+as", re.I)),
    ("exfiltrate", re.compile(r"(leak|exfiltrate|dump)\s+(member|user|customer)?\s*(emails|data|secrets)", re.I)),
    ("role_hijack", re.compile(r"you\s+are\s+now\s+(DAN|a\s+jailbroken)", re.I)),
]


def scan_field(field: str, locator: str, text: str) -> list[InjectionFlag]:
    flags: list[InjectionFlag] = []
    for name, pattern in PATTERNS:
        match = pattern.search(text or "")
        if match:
            start = max(0, match.start() - 24)
            end = min(len(text), match.end() + 24)
            flags.append(
                InjectionFlag(
                    field=field,
                    locator=locator,
                    pattern=name,
                    excerpt=text[start:end].strip(),
                )
            )
    return flags
