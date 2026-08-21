from __future__ import annotations

from app.models import EvidenceRef, Finding, NormalizedProfile

AGENT = "audience_investigator"


def investigate(profile: NormalizedProfile, captions: dict[str, str]) -> list[Finding]:
    findings: list[Finding] = []
    corpus = " ".join(captions.values()).lower() + " " + profile.bio.lower()

    segments: list[tuple[str, list[str]]] = [
        ("local neighborhood / families", ["neighbors", "kids", "workshop", "ages", "walk-ins"]),
        ("wedding / celebration clients", ["wedding", "bookings", "cake"]),
        ("working adults / shift workers", ["desk", "nurses", "night-shift", "working adults"]),
        ("beginner trainees", ["beginners", "intro week"]),
        ("industrial SaaS operators", ["wms", "warehouse", "procurement", "abm", "founder"]),
        ("hiring market / talent", ["hiring", "copywriter", "remote"]),
    ]
    matched = [(name, keys) for name, keys in segments if any(k in corpus for k in keys)]

    if matched:
        names = [n for n, _ in matched]
        findings.append(
            Finding(
                id="aud-segments",
                agent=AGENT,
                title="Audience indicators",
                statement="Copy addresses: " + "; ".join(names) + ".",
                tags=names,
                confidence=min(0.88, 0.5 + 0.1 * len(matched)),
                evidence=[
                    EvidenceRef(kind="bio", locator="bio", excerpt=profile.bio[:160]),
                    *[
                        EvidenceRef(
                            kind="caption",
                            locator=f"caption:{p.id}",
                            excerpt=captions.get(p.id, p.caption)[:160],
                            post_id=p.id,
                        )
                        for p in profile.posts[:2]
                    ],
                ],
            )
        )

    ratio = profile.followers / max(profile.following, 1)
    if ratio > 20:
        gravity = "broadcast / brand gravity (followers >> following)"
        conf = 0.77
    elif ratio > 5:
        gravity = "asymmetric local brand"
        conf = 0.7
    else:
        gravity = "peer-network / still building audience"
        conf = 0.62
    findings.append(
        Finding(
            id="aud-gravity",
            agent=AGENT,
            title="Graph gravity",
            statement=f"{profile.followers:,} / {profile.following:,} following — {gravity}.",
            tags=["graph"],
            confidence=conf,
            evidence=[
                EvidenceRef(kind="metric", locator="followers", excerpt=str(profile.followers)),
                EvidenceRef(kind="metric", locator="following", excerpt=str(profile.following)),
            ],
        )
    )

    if "dm" in corpus or "intro" in corpus:
        findings.append(
            Finding(
                id="aud-intent",
                agent=AGENT,
                title="Intent capture",
                statement="Audience is funneled into DMs or a priced intro offer rather than a pure browse feed.",
                tags=["demand-capture"],
                confidence=0.73,
                evidence=[
                    EvidenceRef(
                        kind="caption",
                        locator="caption:cta-scan",
                        excerpt="DM / intro language present in corpus",
                    )
                ],
            )
        )
    return findings
