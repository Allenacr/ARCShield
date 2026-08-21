from __future__ import annotations

import asyncio
from datetime import datetime, timezone
from itertools import count
from uuid import uuid4

from app.demo_loader import get_demo, list_handles
from app.handles import extract_handle
from app.injection import scan_field
from app.investigators import audience, chief, content, profile as profile_agent, visual
from app.models import (
    AuditEvent,
    CaseRecord,
    Finding,
    InjectionFlag,
    NormalizedProfile,
)
from app.pii import redact_profile_texts
from app.sanitization import sanitize_text, wrap_untrusted

_case_seq = count(47)
CASES: dict[str, CaseRecord] = {}
QUEUES: dict[str, list[asyncio.Queue]] = {}
HISTORY: dict[str, list[dict]] = {}

ALLOWED_TOOLS = {
    "profile_investigator": {"bio", "highlights", "metrics", "website"},
    "content_investigator": {"captions", "engagement"},
    "visual_investigator": {"visual_tags"},
    "audience_investigator": {"bio", "captions", "metrics"},
    "chief_investigator": {"findings"},
}


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _audit(case: CaseRecord, actor: str, action: str, detail: str, accessed: list[str]) -> AuditEvent:
    event = AuditEvent(
        ts=_now(),
        actor=actor,
        action=action,
        detail=detail,
        data_accessed=accessed,
    )
    case.audit.append(event)
    return event


async def _emit(case_id: str, payload: dict) -> None:
    HISTORY.setdefault(case_id, []).append(payload)
    for queue in QUEUES.get(case_id, []):
        await queue.put(payload)


def scan_injections(profile: NormalizedProfile, bio: str, captions: dict[str, str]) -> list[InjectionFlag]:
    flags = scan_field("bio", "bio", bio)
    for post_id, text in captions.items():
        flags.extend(scan_field("caption", f"caption:{post_id}", text))
    return flags


def injection_findings(flags: list[InjectionFlag]) -> list[Finding]:
    if not flags:
        return []
    from app.models import EvidenceRef

    return [
        Finding(
            id="sec-injection",
            agent="injection_detector",
            title="Prompt-injection patterns",
            statement=(
                f"{len(flags)} untrusted-text pattern(s) flagged. "
                "Investigators continued with delimited, sanitized copy; flags are visible, not silent."
            ),
            tags=["injection", "security"],
            confidence=0.95,
            flags=["injection"],
            evidence=[
                EvidenceRef(
                    kind="caption" if f.field == "caption" else "bio",
                    locator=f.locator,
                    excerpt=f.excerpt,
                    post_id=f.locator.split(":")[-1] if f.locator.startswith("caption:") else None,
                )
                for f in flags
            ],
        )
    ]


async def run_pipeline(case: CaseRecord, profile: NormalizedProfile, reveal_pii: bool) -> None:
    await _emit(case.id, {"type": "status", "status": "sanitizing", "line": "Sanitizing untrusted profile text."})
    case.status = "sanitizing"
    _audit(case, "sanitizer", "sanitize", "NFKC + control/zero-width strip", ["bio", "captions"])

    raw_bio = sanitize_text(profile.bio)
    raw_caps = {p.id: sanitize_text(p.caption) for p in profile.posts}
    flags = scan_injections(profile, raw_bio, raw_caps)
    case.injection_flags = flags
    _audit(
        case,
        "injection_detector",
        "scan",
        f"{len(flags)} pattern hit(s)",
        ["bio", "captions"],
    )
    await _emit(
        case.id,
        {
            "type": "injection",
            "count": len(flags),
            "line": f"Injection scan complete — {len(flags)} flag(s).",
        },
    )

    bio_work, cap_pairs, pii_hits = redact_profile_texts(raw_bio, list(raw_caps.items()))
    cap_work = dict(cap_pairs)
    case.pii_hits = pii_hits
    case.pii_redacted = not reveal_pii
    if reveal_pii:
        bio_work, cap_work = raw_bio, raw_caps
        _audit(case, "pii", "reveal", "Operator revealed PII for this case", ["contact"])
    else:
        _audit(case, "pii", "redact", f"{len(pii_hits)} PII span(s) barred", ["bio", "captions"])

    case.sanitized_preview = {
        "bio": wrap_untrusted(bio_work),
        "post_ids": list(cap_work.keys()),
        "delimiter": "UNTRUSTED_PROFILE_TEXT",
    }
    await _emit(case.id, {"type": "status", "status": "investigating", "line": "Four investigators dispatched in parallel."})
    case.status = "investigating"

    async def run_agent(name: str, tools: set[str], fn) -> list[Finding]:
        if tools - ALLOWED_TOOLS[name]:
            raise RuntimeError(f"tool allowlist violation: {name}")
        await _emit(case.id, {"type": "agent", "agent": name, "state": "start", "line": f"{name} opened evidence."})
        await asyncio.sleep(0.05)
        result = fn()
        _audit(case, name, "investigate", f"{len(result)} finding(s)", sorted(tools))
        await _emit(
            case.id,
            {
                "type": "agent",
                "agent": name,
                "state": "pin",
                "findings": [f.model_dump() for f in result],
                "line": f"{name} pinned {len(result)} finding(s).",
            },
        )
        return result

    profile_f, content_f, visual_f, audience_f = await asyncio.gather(
        run_agent(
            "profile_investigator",
            {"bio", "highlights", "metrics", "website"},
            lambda: profile_agent.investigate(profile, bio_work),
        ),
        run_agent(
            "content_investigator",
            {"captions", "engagement"},
            lambda: content.investigate(profile, cap_work),
        ),
        run_agent(
            "visual_investigator",
            {"visual_tags"},
            lambda: visual.investigate(profile),
        ),
        run_agent(
            "audience_investigator",
            {"bio", "captions", "metrics"},
            lambda: audience.investigate(profile, cap_work),
        ),
    )

    merged = profile_f + content_f + visual_f + audience_f + injection_findings(flags)

    case.status = "synthesis"
    await _emit(case.id, {"type": "status", "status": "synthesis", "line": "Chief investigator cross-checking testimony."})
    findings, contradictions, overall, dossier_core = chief.synthesize(merged)
    case.findings = findings
    case.contradictions = contradictions
    case.overall_confidence = overall
    case.category = dossier_core.get("category")
    case.description = dossier_core.get("business_description")
    case.service_tags = dossier_core.get("service_tags") or []
    case.content_themes = dossier_core.get("content_themes") or []
    case.audience = dossier_core.get("target_audience")
    _audit(case, "chief_investigator", "synthesize", f"confidence={overall}", ["findings"])
    await _emit(
        case.id,
        {
            "type": "chief",
            "findings": [f.model_dump() for f in findings if f.agent == "chief_investigator"],
            "contradictions": contradictions,
            "overall_confidence": overall,
            "line": "Chief stamped working theory. Awaiting approval to close.",
        },
    )

    case.status = "awaiting_approval"
    await _emit(case.id, {"type": "status", "status": "awaiting_approval", "line": "Approval gate: no export until signed."})
    await _emit(case.id, {"type": "done"})


def open_case(url: str, reveal_pii: bool) -> tuple[CaseRecord | None, NormalizedProfile | None, str | None]:
    handle = extract_handle(url)
    if not handle:
        return None, None, "Could not parse an Instagram handle from that input."

    profile = get_demo(handle)
    n = next(_case_seq)
    case_id = str(uuid4())
    case = CaseRecord(
        id=case_id,
        case_number=f"{n:03d}",
        status="intake",
        handle=handle,
        url=profile.url if profile else url,
        source="demo",
        retention="ephemeral",
        pii_redacted=not reveal_pii,
    )
    if not profile:
        case.status = "rejected"
        _audit(
            case,
            "intake",
            "reject",
            "Handle not in demo corpus; live scrape disabled. Verified-owner Graph API is roadmap.",
            [],
        )
        CASES[case_id] = case
        return case, None, None

    _audit(case, "intake", "open", f"Demo fixture loaded for @{handle}", ["demo_fixture"])
    CASES[case_id] = case
    QUEUES[case_id] = []
    HISTORY[case_id] = []
    return case, profile, None


def close_dossier(case: CaseRecord) -> dict:
    case.approved = True
    case.status = "closed"
    dossier = {
        "case_number": case.case_number,
        "handle": case.handle,
        "url": case.url,
        "source": case.source,
        "business_description": case.description,
        "category": case.category,
        "service_tags": case.service_tags,
        "content_themes": case.content_themes,
        "target_audience": case.audience,
        "overall_confidence": case.overall_confidence,
        "contradictions": case.contradictions,
        "injection_flags": [f.model_dump() for f in case.injection_flags],
        "pii_policy": "redacted" if case.pii_redacted else "revealed",
        "findings": [f.model_dump() for f in case.findings],
        "audit": [a.model_dump() for a in case.audit],
        "retention": case.retention,
        "integration": {
            "crm": {
                "company": case.handle,
                "category": case.category,
                "tags": case.service_tags,
            },
            "ads": {
                "audience_notes": case.audience,
                "themes": case.content_themes,
            },
        },
    }
    case.dossier = dossier
    _audit(case, "approval_gate", "approve", "Case closed — dossier generated", ["findings"])
    return dossier


def available_demos() -> list[str]:
    return list_handles()
