# Sleuth

Evidence-backed Instagram business intelligence. Paste a profile → four investigators pin findings → the chief scores confidence and strings contradictions → you approve before any export.

This is the hackathon MVP: **demo cases only**. There is no live scrape of arbitrary URLs. Verified-owner Instagram Graph API is documented as roadmap, not implemented.

## Run

Terminal 1:

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

Terminal 2:

```bash
cd frontend
npm install
npm run dev
```

Open `http://localhost:5173`.

## Demo dockets

- `https://www.instagram.com/marigold.bakery.pdx/` — bakery; luxury vs discount contradiction
- `https://www.instagram.com/ironclad.studio/` — gym; injection patterns in bio/caption
- `https://www.instagram.com/northline.agency/` — B2B agency; off-category visual/copy

## What is in scope

1. Normalized schema + cached fixtures
2. Sanitization + visible injection flags
3. Four investigators (profile, content, visual, audience) with source locators
4. Chief investigator: merge, contradictions, confidence
5. Corkboard pins/strings + `[WHY?]` evidence
6. Timestamped investigation log (SSE from real pipeline steps)
7. Approval gate → dossier + integration JSON

## Explicitly not built

OAuth verified-owner mode, CRM writeback, PDF export, saved history, similarity search.

## Security posture in the MVP

- Untrusted bio/captions are sanitized and wrapped in delimiters before any analysis text is stored
- Injection regexes flag and continue; they do not fail closed silently
- Per-agent tool allowlists in the orchestrator
- PII (email/phone) barred by default; reveal is an intake flag and is audited
- In-memory ephemeral cases; rate limit + circuit breaker on intake
- Export refused until approval
