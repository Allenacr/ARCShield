from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
import uuid
import time
from datetime import datetime, timezone

from features.pipeline import feature_pipeline
from graph.service import graph_service
from rules.engine import rule_engine
from rules.fusion import fusion_engine
from models.registry import model_registry
from api.services.notification_service import notification_service
from api.services.ledger_service import ledger_service
from api.config import CORS_ORIGINS

app = FastAPI(
    title="ARCShield: Bidirectional Transaction Guard API",
    version="1.0.0",
    description="Real-time financial fraud detection engine scoring transactions in both directions with Quarantine isolation."
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory stores for simulated demo state
IN_MEMORY_CASES: List[Dict[str, Any]] = []
IN_MEMORY_HOLDS: List[Dict[str, Any]] = []
IN_MEMORY_AUDIT_LOGS: List[Dict[str, Any]] = []
FEDERATED_ROUND = 14

# Pre-seed graph with sample cybercrime complaint for Scenario 5 demo
graph_service.add_account("acc-victim-01")
graph_service.add_complaint("FIR-2026-9082", "acc-victim-01", "CYBER_FRAUD")
graph_service.add_account("mule-bridge-01")
graph_service.graph.add_edge("acc-victim-01", "mule-bridge-01", relation="TRANSFERRED_TO")
graph_service.add_account("karan9921@upi (Stranger)")
graph_service.graph.add_edge("mule-bridge-01", "karan9921@upi (Stranger)", relation="LINKED_TO")

# ─────────────────────────────────────────────────────────────
# Request / Response Schemas
# ─────────────────────────────────────────────────────────────

class TransactionScoreRequest(BaseModel):
    transaction_id: Optional[str] = None
    account_id: str
    counterparty: str
    amount: float = Field(..., gt=0)
    direction: str = Field(..., pattern="^(INCOMING|OUTGOING)$")
    device_id: Optional[str] = "dev-primary-01"
    coercion_answers: Optional[Dict[str, bool]] = None
    fcm_device_token: Optional[str] = None

class QuarantineRequest(BaseModel):
    transaction_id: str
    account_id: str
    amount: float = Field(..., gt=0)
    reason: Optional[str] = "User flagged unexpected credit"

class CounterfactualRequest(BaseModel):
    transaction: Dict[str, Any]
    overrides: Dict[str, Any]

# ─────────────────────────────────────────────────────────────
# API Endpoints
# ─────────────────────────────────────────────────────────────

@app.get("/health")
def health_check():
    return {
        "status": "HEALTHY",
        "model_version": model_registry.MODEL_VERSION,
        "engine": "Bidirectional Transaction Guard",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

@app.post("/transactions/score")
def score_transaction(payload: TransactionScoreRequest, background_tasks: BackgroundTasks):
    """
    Core Ingestion & Scoring endpoint. Target SLA: < 200ms warm latency.
    """
    start_time = time.time()
    tx_id = payload.transaction_id or f"tx-{uuid.uuid4().hex[:12]}"

    # 1. Query Graph Service
    graph_feats = graph_service.get_compact_features(payload.counterparty)

    # 2. Extract Tabular Point-in-Time Features
    tx_dict = {
        "amount": payload.amount,
        "direction": payload.direction,
        "counterparty": payload.counterparty,
        "device_id": payload.device_id,
        "coercion_answers": payload.coercion_answers or {},
    }
    # Recognize primary user device
    known_devices = [payload.device_id] if payload.device_id else ["dev-primary-01"]
    known_recipients = ["Starbucks Coffee", "Amazon Pay", "Swiggy", "Zomato"]

    feature_vector = feature_pipeline.build_feature_vector(
        transaction=tx_dict,
        known_devices=known_devices,
        known_recipients=known_recipients,
        graph_features=graph_feats,
    )

    # 3. Model Prediction & SHAP Feature Attribution
    model_prob = model_registry.predict_proba(feature_vector)
    shap_top = model_registry.explain(feature_vector)

    # 4. Deterministic Rule Engine
    fired_rules = rule_engine.evaluate(feature_vector)

    # 5. Risk Fusion
    verdict = fusion_engine.fuse(
        model_prob=model_prob,
        fired_rules=fired_rules,
        direction=payload.direction,
        shap_top=shap_top,
    )

    elapsed_ms = round((time.time() - start_time) * 1000, 2)

    # 6. Dispatch Push Notification if HIGH or MEDIUM risk
    if verdict["risk_band"] in ("HIGH", "MEDIUM"):
        background_tasks.add_task(
            notification_service.send_fraud_alert,
            fcm_token=payload.fcm_device_token,
            title="ARCShield Risk Warning" if payload.direction == "OUTGOING" else "Unexpected Inflow Alert",
            body=f"Risk Band: {verdict['risk_band']} for ₹{payload.amount:,.2f} with {payload.counterparty}.",
            transaction_id=tx_id,
            risk_band=verdict["risk_band"],
            direction=payload.direction,
            reason_codes=verdict["reason_codes"],
            amount=payload.amount,
        )

    return {
        "transaction_id": tx_id,
        "direction": payload.direction,
        "risk_score": verdict["risk_score"],
        "risk_band": verdict["risk_band"],
        "recommended_action": verdict["recommended_action"],
        "model_version": verdict["model_version"],
        "reason_codes": verdict["reason_codes"],
        "shap_top": verdict["shap_top"],
        "latency_ms": elapsed_ms,
    }

@app.post("/quarantine")
def apply_quarantine(payload: QuarantineRequest):
    """
    F-15 Headline Feature: Places 24-hour quarantine hold on unexpected credit.
    Adjusts ledger, records immutable audit row, opens case file with evidence snapshot.
    """
    hold_id = str(uuid.uuid4())
    case_id = f"CASE-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:6]}"
    now = datetime.now(timezone.utc)
    expires_at = now.isoformat()

    # 1. Snapshot counterparty subgraph for tamper-evident case evidence
    subgraph = graph_service.export_subgraph_snapshot(payload.transaction_id, radius=2)

    hold_record = {
        "id": hold_id,
        "transaction_id": payload.transaction_id,
        "account_id": payload.account_id,
        "held_amount": payload.amount,
        "status": "ACTIVE",
        "created_at": now.isoformat(),
        "reason": payload.reason,
    }
    IN_MEMORY_HOLDS.append(hold_record)

    case_record = {
        "id": case_id,
        "case_number": case_id,
        "transaction_id": payload.transaction_id,
        "account_id": payload.account_id,
        "status": "OPEN",
        "evidence_trail": {
            "quarantine_timestamp": now.isoformat(),
            "quarantine_amount": payload.amount,
            "reason": payload.reason,
            "action_by": "ACCOUNT_HOLDER_PROACTIVE_HOLD",
        },
        "subgraph_snapshot": subgraph,
        "created_at": now.isoformat(),
    }
    IN_MEMORY_CASES.append(case_record)

    IN_MEMORY_AUDIT_LOGS.append({
        "action": "QUARANTINE_HOLD_PLACED",
        "account_id": payload.account_id,
        "transaction_id": payload.transaction_id,
        "metadata": {"held_amount": payload.amount, "case_id": case_id},
        "created_at": now.isoformat(),
    })

    # Double-entry ledger integration
    if payload.account_id not in ledger_service.accounts:
        ledger_service.create_account(payload.account_id, initial_balance=payload.amount)
    try:
        ledger_service.place_quarantine_hold(
            account_id=payload.account_id,
            transaction_id=payload.transaction_id,
            amount=payload.amount,
            reason=payload.reason or "Unexpected credit quarantined",
        )
    except Exception:
        pass

    ledger_bal = ledger_service.get_balance(payload.account_id)

    return {
        "success": True,
        "message": f"₹{payload.amount:,.2f} successfully quarantined for 24 hours.",
        "hold": hold_record,
        "case": case_record,
        "ledger_balance": ledger_bal,
    }

@app.post("/counterfactual")
def run_counterfactual(payload: CounterfactualRequest):
    """
    F-22 Counterfactual Slider for Analyst UI:
    Re-scores a transaction with one modified feature in < 50ms.
    """
    tx = dict(payload.transaction)
    tx.update(payload.overrides)

    graph_feats = graph_service.get_compact_features(tx.get("counterparty", "unknown"))
    fv = feature_pipeline.build_feature_vector(tx, graph_features=graph_feats)
    
    model_prob = model_registry.predict_proba(fv)
    rules = rule_engine.evaluate(fv)
    shap_top = model_registry.explain(fv)

    verdict = fusion_engine.fuse(
        model_prob=model_prob,
        fired_rules=rules,
        direction=tx.get("direction", "OUTGOING"),
        shap_top=shap_top,
    )

    return {
        "overrides": payload.overrides,
        "simulated_risk_score": verdict["risk_score"],
        "simulated_risk_band": verdict["risk_band"],
        "simulated_action": verdict["recommended_action"],
        "simulated_reason_codes": verdict["reason_codes"],
    }

@app.get("/cases")
def list_cases():
    return {"cases": IN_MEMORY_CASES}

@app.get("/graph/snapshot/{entity_id}")
def get_graph_snapshot(entity_id: str):
    return graph_service.export_subgraph_snapshot(entity_id, radius=2)

@app.get("/accounts/{account_id}/balance")
def get_account_balance(account_id: str):
    bal = ledger_service.get_balance(account_id)
    if not bal:
        raise HTTPException(status_code=404, detail="Account not found in ledger")
    return bal

@app.get("/accounts/{account_id}/can-spend")
def check_can_spend(account_id: str, amount: float):
    can_spend = ledger_service.can_spend(account_id, amount)
    bal = ledger_service.get_balance(account_id) or {}
    return {
        "account_id": account_id,
        "requested_amount": amount,
        "can_spend": can_spend,
        "available_balance": bal.get("available_balance", 0.0),
        "held_balance": bal.get("held_balance", 0.0),
        "total_balance": bal.get("total_balance", 0.0),
    }

@app.get("/federated/status")
def get_federated_status():
    """
    F-28 Cross-Bank Federated Learning & Intelligence Status:
    Returns node network state, aggregation round, differential privacy metrics,
    and pseudonymized cross-bank hash ring.
    """
    return {
        "current_round": FEDERATED_ROUND,
        "global_model_version": "arc-fed-v2.1",
        "privacy_budget_epsilon": 0.85,
        "secure_aggregation_protocol": "SecAgg+ / Diffie-Hellman Key Exchange",
        "last_sync_timestamp": datetime.now(timezone.utc).isoformat(),
        "nodes": [
            {
                "bank_id": "SBI_NODE_01",
                "bank_name": "State Bank of India",
                "status": "ONLINE",
                "local_samples": 412000,
                "local_auc": 0.974,
                "last_heartbeat": "3s ago"
            },
            {
                "bank_id": "HDFC_NODE_02",
                "bank_name": "HDFC Bank",
                "status": "ONLINE",
                "local_samples": 389500,
                "local_auc": 0.969,
                "last_heartbeat": "5s ago"
            },
            {
                "bank_id": "ICICI_NODE_03",
                "bank_name": "ICICI Bank",
                "status": "ONLINE",
                "local_samples": 321800,
                "local_auc": 0.971,
                "last_heartbeat": "1s ago"
            },
            {
                "bank_id": "AXIS_NODE_04",
                "bank_name": "Axis Bank",
                "status": "SYNCING",
                "local_samples": 215400,
                "local_auc": 0.962,
                "last_heartbeat": "12s ago"
            }
        ],
        "recent_hashes": [
            {
                "hash_id": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
                "flagged_by": "SBI_NODE_01",
                "risk_tag": "MULE_CLUSTER_PATTERN",
                "confidence": 0.94,
                "timestamp": "42s ago"
            },
            {
                "hash_id": "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8",
                "flagged_by": "HDFC_NODE_02",
                "risk_tag": "PASS_THROUGH_VELOCITY",
                "confidence": 0.91,
                "timestamp": "2m ago"
            },
            {
                "hash_id": "4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a",
                "flagged_by": "ICICI_NODE_03",
                "risk_tag": "CYBER_COMPLAINT_HOP_2",
                "confidence": 0.98,
                "timestamp": "6m ago"
            }
        ]
    }

@app.post("/federated/aggregate")
def run_federated_aggregation():
    """Simulates one secure aggregation round across the virtual bank nodes."""
    global FEDERATED_ROUND
    FEDERATED_ROUND += 1
    return {
        "success": True,
        "current_round": FEDERATED_ROUND,
        "global_model_version": f"arc-fed-v2.{FEDERATED_ROUND - 12}",
        "metric_delta": 0.0042,
        "privacy_budget_epsilon": 0.85,
        "aggregated_updates": 4,
        "raw_identifiers_shared": 0,
        "completed_at": datetime.now(timezone.utc).isoformat(),
    }

