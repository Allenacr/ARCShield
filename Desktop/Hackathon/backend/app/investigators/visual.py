from __future__ import annotations

from collections import Counter

from app.models import EvidenceRef, Finding, NormalizedProfile

AGENT = "visual_investigator"

FAMILY_MAP = {
    "food": ["bread", "pastry", "cake", "bun", "coffee", "icing", "galette"],
    "interior": ["counter", "cafe", "lighting", "desk", "office"],
    "fitness": ["barbell", "gym", "dumbbell", "stretch"],
    "community": ["group", "children", "workshop", "founders", "breakfast"],
    "proof assets": ["dashboard", "chart", "screenshot", "slide", "whiteboard"],
    "promo": ["sign", "discount", "poster", "balloons"],
}


def investigate(profile: NormalizedProfile) -> list[Finding]:
    findings: list[Finding] = []
    all_tags: list[str] = []
    for post in profile.posts:
        all_tags.extend(t.lower() for t in post.visual_tags)

    families: dict[str, list[str]] = {k: [] for k in FAMILY_MAP}
    for tag in all_tags:
        for fam, keys in FAMILY_MAP.items():
            if any(k in tag for k in keys):
                families[fam].append(tag)

    ranked = sorted(
        ((fam, tags) for fam, tags in families.items() if tags),
        key=lambda x: len(x[1]),
        reverse=True,
    )
    if ranked:
        top_fam, top_tags = ranked[0]
        findings.append(
            Finding(
                id="vis-family",
                agent=AGENT,
                title="Visual family",
                statement=(
                    f"Imagery clusters as “{top_fam}” "
                    f"({len(top_tags)} tagged frames). Secondary: "
                    + ", ".join(f for f, _ in ranked[1:3] or [("none", [])])
                    + "."
                ),
                tags=[top_fam, *[f for f, _ in ranked[1:3]]],
                confidence=0.7 if len(all_tags) >= 8 else 0.55,
                evidence=[
                    EvidenceRef(
                        kind="visual",
                        locator=f"visual:{post.id}",
                        excerpt=", ".join(post.visual_tags),
                        post_id=post.id,
                    )
                    for post in profile.posts
                    if post.visual_tags
                ][:4],
            )
        )

    counts = Counter(all_tags)
    palette = [t for t, n in counts.most_common(6)]
    findings.append(
        Finding(
            id="vis-objects",
            agent=AGENT,
            title="Repeated objects",
            statement="Recurring visual objects: " + ", ".join(palette) + "."
            if palette
            else "No visual tags on file.",
            tags=palette[:5],
            confidence=0.68 if palette else 0.2,
            evidence=[
                EvidenceRef(kind="visual", locator="visual:corpus", excerpt=", ".join(palette))
            ],
        )
    )

    mismatch_posts = [
        p
        for p in profile.posts
        if any("balloon" in t or "party" in t for t in p.visual_tags)
        and profile.category_hint
        and "marketing" in (profile.category_hint or "").lower()
    ]
    if mismatch_posts:
        p = mismatch_posts[0]
        findings.append(
            Finding(
                id="vis-mismatch",
                agent=AGENT,
                title="Visual outlier",
                statement="At least one frame is off-category versus the stated business type.",
                tags=["outlier", "contradiction-candidate"],
                confidence=0.8,
                flags=["visual_category_drift"],
                evidence=[
                    EvidenceRef(
                        kind="visual",
                        locator=f"visual:{p.id}",
                        excerpt=", ".join(p.visual_tags),
                        post_id=p.id,
                    )
                ],
            )
        )
    return findings
