from __future__ import annotations

import asyncio
import json
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse

from app.models import ApproveRequest, OpenCaseRequest
from app.pipeline import CASES, HISTORY, QUEUES, available_demos, close_dossier, open_case, run_pipeline
from app.rate_limit import limit_request


@asynccontextmanager
async def lifespan(_app: FastAPI):
    yield


app = FastAPI(title="Sleuth", version="0.1.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/api/health")
def health():
    return {"ok": True, "mode": "demo"}


@app.get("/api/demos")
def demos():
    return {
        "handles": available_demos(),
        "note": "Live arbitrary-URL scrape is disabled. Verified-owner Graph API is roadmap.",
        "retention": "Cases are ephemeral in-memory. Nothing is persisted.",
    }


@app.post("/api/cases", dependencies=[Depends(limit_request)])
async def create_case(body: OpenCaseRequest):
    case, profile, parse_error = open_case(body.url, body.reveal_pii)
    if parse_error or case is None:
        raise HTTPException(status_code=400, detail=parse_error or "Intake failed")
    if case.status == "rejected":
        return {"case": case.model_dump(), "demos": available_demos()}
    assert profile is not None
    asyncio.create_task(_safe_pipeline(case, profile, body.reveal_pii))
    return {"case": case.model_dump()}


async def _safe_pipeline(case, profile, reveal_pii: bool) -> None:
    try:
        await run_pipeline(case, profile, reveal_pii)
    except Exception as exc:  # noqa: BLE001 — surface pipeline faults on the case
        case.status = "rejected"
        await _emit_error(case.id, str(exc))


async def _emit_error(case_id: str, detail: str) -> None:
    from app.pipeline import _emit

    await _emit(case_id, {"type": "error", "line": f"Pipeline halted: {detail}", "status": "rejected"})
    await _emit(case_id, {"type": "done"})


@app.get("/api/cases/{case_id}")
def get_case(case_id: str):
    case = CASES.get(case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Unknown case")
    return case.model_dump()


@app.get("/api/cases/{case_id}/stream")
async def stream_case(case_id: str):
    if case_id not in CASES:
        raise HTTPException(status_code=404, detail="Unknown case")
    queue: asyncio.Queue = asyncio.Queue()
    QUEUES.setdefault(case_id, []).append(queue)

    async def gen():
        yield "retry: 15000\n\n"
        try:
            for event in list(HISTORY.get(case_id, [])):
                yield f"data: {json.dumps(event)}\n\n"
                if event.get("type") == "done":
                    return
            while True:
                event = await queue.get()
                yield f"data: {json.dumps(event)}\n\n"
                if event.get("type") == "done":
                    break
        finally:
            if queue in QUEUES.get(case_id, []):
                QUEUES[case_id].remove(queue)

    return StreamingResponse(
        gen(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


@app.post("/api/cases/{case_id}/approve")
def approve_case(case_id: str, body: ApproveRequest):
    case = CASES.get(case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Unknown case")
    if case.status not in {"awaiting_approval", "closed"}:
        raise HTTPException(status_code=409, detail="Case is not at the approval gate")
    if not body.approved:
        case.status = "rejected"
        return {"case": case.model_dump()}
    dossier = close_dossier(case)
    return {"case": case.model_dump(), "dossier": dossier}


@app.get("/api/cases/{case_id}/export.json")
def export_json(case_id: str):
    case = CASES.get(case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Unknown case")
    if not case.approved or not case.dossier:
        raise HTTPException(status_code=403, detail="Approval required before export")
    return case.dossier
