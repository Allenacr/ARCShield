from __future__ import annotations

from collections import Counter

from app.models import EvidenceRef, Finding, NormalizedProfile

AGENT = "profile_investigator"


def investigate(profile: NormalizedProfile, bio: str) -> list[Finding]:
    findings: list[Finding] = []
    findings.append(
        Finding(
            id="prf-identity",
            agent=AGENT,
            title="Identity surface",
            statement=(
                f"{profile.display_name} (@{profile.handle}) presents as a "
                f"{'business' if profile.is_business else 'personal'} account"
                f"{f' in {profile.category_hint}' if profile.category_hint else ''} "
                f"with {profile.followers:,} followers."
            ),
            tags=["identity", profile.category_hint or "unclassified"],
            confidence=0.92 if profile.is_business else 0.7,
            evidence=[
                EvidenceRef(
                    kind="bio",
                    locator="bio",
                    excerpt=bio[:180],
                ),
                EvidenceRef(
                    kind="metric",
                    locator="followers",
                    excerpt=str(profile.followers),
                ),
            ],
        )
    )

    services = list(profile.highlights)
    bio_l = bio.lower()
    keyword_map = {
        "custom cakes": ["cake", "wedding cake", "custom cake"],
        "wholesale": ["wholesale"],
        "workshops": ["workshop", "class"],
        "coaching": ["coach", "coaching", "programming"],
        "intro offer": ["intro week", "$49"],
        "demand gen": ["cac", "abm", "case study", "demand"],
        "hiring": ["hiring"],
    }
    for tag, keys in keyword_map.items():
        if any(k in bio_l for k in keys):
            services.append(tag)
    services = list(dict.fromkeys(services))

    findings.append(
        Finding(
            id="prf-services",
            agent=AGENT,
            title="Stated services",
            statement=(
                "Profile text and highlights advertise: " + ", ".join(services)
                if services
                else "No explicit service menu in bio or highlights."
            ),
            tags=services or ["unspecified"],
            confidence=0.78 if services else 0.4,
            evidence=[
                EvidenceRef(kind="bio", locator="bio", excerpt=bio[:220]),
                *[
                    EvidenceRef(kind="highlight", locator=f"highlight:{h}", excerpt=h)
                    for h in profile.highlights
                ],
            ],
        )
    )

    loc = profile.contact.address_hint
    if loc:
        findings.append(
            Finding(
                id="prf-geo",
                agent=AGENT,
                title="Operating geography",
                statement=f"Public copy places operations in {loc}.",
                tags=["geo", loc],
                confidence=0.86,
                evidence=[EvidenceRef(kind="bio", locator="bio", excerpt=loc)],
            )
        )

    website = profile.website
    if website:
        findings.append(
            Finding(
                id="prf-web",
                agent=AGENT,
                title="Off-platform funnel",
                statement=f"Profile points traffic to {website}.",
                tags=["website"],
                confidence=0.9,
                evidence=[EvidenceRef(kind="bio", locator="website", excerpt=website)],
            )
        )

    words = Counter(w for w in bio_l.replace("·", " ").split() if len(w) > 3)
    tone = "utilitarian / operator-facing" if any(w in words for w in ("case", "b2b", "saas")) else (
        "neighborhood / hospitality" if any(w in words for w in ("portland", "bakery", "neighborhood")) else "direct / offer-led"
    )
    findings.append(
        Finding(
            id="prf-voice",
            agent=AGENT,
            title="Bio voice",
            statement=f"Bio voice reads as {tone}.",
            tags=["voice"],
            confidence=0.64,
            evidence=[EvidenceRef(kind="bio", locator="bio", excerpt=bio[:160])],
        )
    )
    return findings
