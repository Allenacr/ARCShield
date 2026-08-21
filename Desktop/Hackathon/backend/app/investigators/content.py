from __future__ import annotations

from collections import Counter

from app.models import EvidenceRef, Finding, NormalizedProfile, PostRecord

AGENT = "content_investigator"

THEME_RULES: list[tuple[str, list[str]]] = [
    ("product showcase", ["loaf", "cake", "bun", "pastry", "galette"]),
    ("events & bookings", ["wedding", "bookings", "workshop", "clinic", "saturday"]),
    ("community", ["member", "neighbors", "community", "nurses"]),
    ("offers & pricing", ["%", "off", "$", "intro", "sold out"]),
    ("b2b proof", ["cac", "abm", "teardown", "vendor", "procurement"]),
    ("hiring", ["hiring", "remote"]),
    ("hours & access", ["hours", "weekdays", "walk-ins"]),
]


def investigate(profile: NormalizedProfile, captions: dict[str, str]) -> list[Finding]:
    findings: list[Finding] = []
    posts = profile.posts
    theme_hits: dict[str, list[PostRecord]] = {name: [] for name, _ in THEME_RULES}

    for post in posts:
        text = captions.get(post.id, post.caption).lower()
        for name, keys in THEME_RULES:
            if any(k in text for k in keys):
                theme_hits[name].append(post)

    active = [(name, items) for name, items in theme_hits.items() if items]
    active.sort(key=lambda x: len(x[1]), reverse=True)
    themes = [name for name, _ in active[:5]]

    if themes:
        lead_name, lead_posts = active[0]
        findings.append(
            Finding(
                id="cnt-themes",
                agent=AGENT,
                title="Content themes",
                statement=(
                    f"Dominant themes across {len(posts)} sampled posts: "
                    + ", ".join(themes)
                    + f". Lead cluster is “{lead_name}”."
                ),
                tags=themes,
                confidence=min(0.9, 0.55 + 0.08 * len(themes)),
                evidence=[
                    EvidenceRef(
                        kind="caption",
                        locator=f"caption:{p.id}",
                        excerpt=captions.get(p.id, p.caption)[:180],
                        post_id=p.id,
                    )
                    for p in lead_posts[:3]
                ],
            )
        )

    ctas = []
    for post in posts:
        cap = captions.get(post.id, post.caption)
        low = cap.lower()
        if "dm" in low:
            ctas.append(("DM funnel", post, cap))
        if "book" in low:
            ctas.append(("booking CTA", post, cap))
        if "site" in low or "highlights" in low:
            ctas.append(("owned-media CTA", post, cap))

    if ctas:
        kinds = list(dict.fromkeys(c[0] for c in ctas))
        sample = ctas[0]
        findings.append(
            Finding(
                id="cnt-cta",
                agent=AGENT,
                title="Conversion language",
                statement="Captions push: " + ", ".join(kinds) + ".",
                tags=kinds,
                confidence=0.81,
                evidence=[
                    EvidenceRef(
                        kind="caption",
                        locator=f"caption:{sample[1].id}",
                        excerpt=sample[2][:180],
                        post_id=sample[1].id,
                    )
                ],
            )
        )

    likes = [p.likes for p in posts] or [0]
    avg = sum(likes) / len(likes)
    top = max(posts, key=lambda p: p.likes) if posts else None
    if top:
        findings.append(
            Finding(
                id="cnt-resonance",
                agent=AGENT,
                title="Resonance outlier",
                statement=(
                    f"Highest engagement is {top.id} ({top.likes} likes vs avg {avg:.0f}). "
                    "Use this post as the strongest evidence of what the audience rewards."
                ),
                tags=["engagement"],
                confidence=0.74,
                evidence=[
                    EvidenceRef(
                        kind="caption",
                        locator=f"caption:{top.id}",
                        excerpt=captions.get(top.id, top.caption)[:180],
                        post_id=top.id,
                    ),
                    EvidenceRef(
                        kind="metric",
                        locator=f"likes:{top.id}",
                        excerpt=str(top.likes),
                        post_id=top.id,
                    ),
                ],
            )
        )

    joined = " ".join(captions.values()).lower()
    if "luxury" in joined and any(x in joined for x in ("% off", "day-old", "day-olds", "discount")):
        lux_post = next((p for p in posts if "luxury" in captions.get(p.id, p.caption).lower()), posts[0])
        cheap_post = next(
            (p for p in posts if any(x in captions.get(p.id, p.caption).lower() for x in ("% off", "day-old", "40%"))),
            posts[0],
        )
        findings.append(
            Finding(
                id="cnt-positioning",
                agent=AGENT,
                title="Positioning split",
                statement="Copy claims luxury destination status while also promoting discount/day-old stock.",
                tags=["luxury", "discount"],
                confidence=0.83,
                flags=["contradiction-candidate"],
                evidence=[
                    EvidenceRef(
                        kind="caption",
                        locator=f"caption:{lux_post.id}",
                        excerpt=captions.get(lux_post.id, lux_post.caption)[:180],
                        post_id=lux_post.id,
                    ),
                    EvidenceRef(
                        kind="caption",
                        locator=f"caption:{cheap_post.id}",
                        excerpt=captions.get(cheap_post.id, cheap_post.caption)[:180],
                        post_id=cheap_post.id,
                    ),
                ],
            )
        )

    tokens = Counter()
    for cap in captions.values():
        tokens.update(w.strip(".,:—").lower() for w in cap.split() if len(w) > 4)
    top_terms = [t for t, _ in tokens.most_common(8)]
    if top_terms:
        findings.append(
            Finding(
                id="cnt-lexicon",
                agent=AGENT,
                title="Recurring lexicon",
                statement="Repeated caption vocabulary: " + ", ".join(top_terms) + ".",
                tags=top_terms[:5],
                confidence=0.6,
                evidence=[
                    EvidenceRef(kind="caption", locator="corpus", excerpt=", ".join(top_terms))
                ],
            )
        )
    return findings
