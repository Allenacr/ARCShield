import pytest
from fastapi.testclient import TestClient
from api.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "HEALTHY"
    assert "model_version" in data

def test_scenario_1_quiet():
    payload = {
        "account_id": "acc-demo-01",
        "counterparty": "Starbucks Coffee",
        "amount": 1200.0,
        "direction": "OUTGOING",
    }
    response = client.post("/transactions/score", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["risk_band"] == "LOW"
    assert data["recommended_action"] == "ALLOW"
    assert data["latency_ms"] < 200.0 # Warm SLA assertion

def test_scenario_2_takeover_coercion_override():
    # Scenario 3: Coercion prompts
    payload = {
        "account_id": "acc-demo-02",
        "counterparty": "cbi_verification_cell@upi",
        "amount": 95000.0,
        "direction": "OUTGOING",
        "coercion_answers": {
            "urgent_request": True,
            "secrecy_request": True,
            "safe_account_claim": True,
        }
    }
    response = client.post("/transactions/score", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["risk_band"] == "HIGH"
    assert "COERCION_SAFE_ACCOUNT_CLAIM" in data["reason_codes"]

def test_scenario_5_unexpected_money_and_quarantine():
    # Scenario 5 Closer: ₹42,000 arrives from stranger
    payload = {
        "transaction_id": "tx-closer-test-01",
        "account_id": "acc-user-target",
        "counterparty": "karan9921@upi (Stranger)",
        "amount": 42000.0,
        "direction": "INCOMING",
    }
    score_resp = client.post("/transactions/score", json=payload)
    assert score_resp.status_code == 200
    score_data = score_resp.json()
    assert score_data["risk_band"] == "HIGH"
    assert score_data["recommended_action"] == "QUARANTINE"
    assert any("COMPLAINT_PROXIMITY" in r for r in score_data["reason_codes"])

    # Execute Quarantine Action (F-15)
    quarantine_payload = {
        "transaction_id": "tx-closer-test-01",
        "account_id": "acc-user-target",
        "amount": 42000.0,
        "reason": "User tapped Hold for 24h on unexpected money"
    }
    quar_resp = client.post("/quarantine", json=quarantine_payload)
    assert quar_resp.status_code == 200
    quar_data = quar_resp.json()
    assert quar_data["success"] is True
    assert quar_data["hold"]["held_amount"] == 42000.0
    assert quar_data["case"]["status"] == "OPEN"

def test_counterfactual_slider():
    payload = {
        "transaction": {
            "amount": 5000.0,
            "direction": "OUTGOING",
            "counterparty": "merchant@upi",
        },
        "overrides": {
            "amount": 95000.0,
            "coercion_answers": {"safe_account_claim": True}
        }
    }
    response = client.post("/counterfactual", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["simulated_risk_band"] == "HIGH"

def test_federated_aggregation_round_advances():
    before = client.get("/federated/status")
    assert before.status_code == 200
    previous_round = before.json()["current_round"]

    response = client.post("/federated/aggregate")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["current_round"] == previous_round + 1
    assert data["raw_identifiers_shared"] == 0

def test_ledger_balance_and_spend_check():
    # Account acc-user-target was credited and quarantined in test_scenario_5
    resp = client.get("/accounts/acc-user-target/balance")
    assert resp.status_code == 200
    bal = resp.json()
    assert bal["held_balance"] == 42000.0

    # Checking spend when available balance is 0 should return can_spend: False
    spend_resp = client.get("/accounts/acc-user-target/can-spend?amount=5000")
    assert spend_resp.status_code == 200
    spend_data = spend_resp.json()
    assert spend_data["can_spend"] is False
