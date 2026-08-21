from __future__ import annotations

from app.models import Finding

AGENT = "chief_investigator"

LUXURY = ("luxury", "destination")
DISCOUNT = ("%", "off", "day-old", "day-olds")
B2B = ("b2b", "saas", "abm", "cac", "procurement")
PARTY = ("balloon", "kids’ parties", "kids' parties", "birthday")


def _text(f: Finding) -> str:
    return (f.statement + " " + " ".join(f.tags)).lower()


def synthesize(findings: list[Finding]) -> tuple[list[Finding], list[dict], float, dict]:
    contradictions: list[dict] = []

    luxury = [f for f in findings if any(w in _text(f) for w in LUXURY)]
    discount = [f for f in findings if any(w in _text(f) for w in DISCOUNT)]
    if not discount:
        discount = [f for f in findings if "offers & pricing" in f.tags or "discount" in _text(f)]

    def pair(a_list: list[Finding], b_list: list[Finding], note: str) -> None:
        if a_list and b_list:
            a, b = a_list[0], b_list[0]
            a.contradicted_by.append(b.id)
            b.contradicted_by.append(a.id)
            a.flags.append("contradiction")
            b.flags.append("contradiction")
            a.confidence = max(0.35, a.confidence - 0.15)
            b.confidence = max(0.35, b.confidence - 0.15)
            contradictions.append(
                {
                    "left": a.id,
                    "right": b.id,
                    "note": note,
                }
            )

    pair(
        [f for f in findings if "luxury" in _text(f)],
        [f for f in findings if any(w in _text(f) for w in ("off", "discount", "day-old"))],
        "Premium positioning vs discount/day-old language.",
    )
    pair(
        [f for f in findings if any(w in _text(f) for w in B2B)],
        [f for f in findings if any(w in _text(f) for w in PARTY) or "visual_category_drift" in f.flags],
        "Industrial B2B claim vs off-category party/visual evidence.",
    )

    for f in findings:
        if "injection" in f.flags or any("injection" in x for x in f.flags):
            f.confidence = min(f.confidence, 0.25)

    scored = [f.confidence for f in findings] or [0]
    overall = round(sum(scored) / len(scored), 3)

    category = None
    description = None
    services: list[str] = []
    themes: list[str] = []
    audience = None

    for f in findings:
        if f.id == "prf-identity":
            description = f.statement
        if f.id == "prf-services":
            services = [t for t in f.tags if t not in {"identity", "unclassified", "unspecified"}]
        if f.id == "cnt-themes":
            themes = f.tags
        if f.id == "aud-segments":
            audience = f.statement
        if f.id == "prf-identity" and f.tags:
            category = next((t for t in f.tags if t != "identity"), None)

    if not category:
        category = findings[0].tags[0] if findings and findings[0].tags else "Unclassified"

    summary = Finding(
        id="chief-summary",
        agent=AGENT,
        title="Chief synthesis",
        statement=(
            f"Working theory: {category}. "
            + (description or "")
            + (f" Audience: {audience}" if audience else "")
            + (
                f" {len(contradictions)} contradiction(s) remain unresolved."
                if contradictions
                else " No material contradictions in the sampled evidence."
            )
        ),
        tags=[category or "unknown", "synthesis"],
        confidence=overall,
        evidence=[e for f in findings[:3] for e in f.evidence[:1]],
        flags=["contradiction"] if contradictions else [],
    )

    dossier = {
        "business_description": description,
        "category": category,
        "service_tags": services[:12],
        "content_themes": themes,
        "target_audience": audience,
        "overall_confidence": overall,
        "contradiction_count": len(contradictions),
    }
    return findings + [summary], contradictions, overall, dossier
