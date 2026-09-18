import uuid
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Any

def create_scenario_1_quiet(account_id: str, device_id: str) -> List[Dict[str, Any]]:
    """
    Scenario 1 — Quiet
    ₹1,200 to a regular merchant, known device, normal hour.
    Proves system is not a smoke alarm that fires at toast. Expected band: LOW.
    """
    tx_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    return [
        {
            "event_type": "TRANSACTION",
            "account_id": account_id,
            "device_id": device_id,
            "transaction_id": tx_id,
            "amount": 1200.0,
            "direction": "OUTGOING",
            "counterparty": "Starbucks Coffee Corp",
            "timestamp": now.isoformat(),
            "expected_band": "LOW",
            "scenario_name": "Quiet",
            "is_fraud": False,
        }
    ]

def create_scenario_2_account_takeover(account_id: str, new_device_id: str) -> List[Dict[str, Any]]:
    """
    Scenario 2 — Account Takeover (ATO)
    New device -> password change -> new beneficiary -> escalating transfers (₹5k, ₹25k, ₹75k) in 6 minutes.
    Flagged on the *sequence*, not just single amount. Expected band: HIGH.
    """
    events = []
    base_time = datetime.now(timezone.utc) - timedelta(minutes=6)
    
    # 1. Login from new device
    events.append({
        "event_type": "LOGIN_NEW_DEVICE",
        "account_id": account_id,
        "device_id": new_device_id,
        "timestamp": base_time.isoformat(),
        "metadata": {"ip": "103.21.244.12", "new_device": True},
        "is_fraud": True,
        "scenario_name": "Account Takeover",
    })
    
    # 2. Password change
    events.append({
        "event_type": "PASSWORD_CHANGE",
        "account_id": account_id,
        "device_id": new_device_id,
        "timestamp": (base_time + timedelta(minutes=1)).isoformat(),
        "metadata": {"action": "credential_reset"},
        "is_fraud": True,
        "scenario_name": "Account Takeover",
    })
    
    # 3. New payee added
    payee_id = "mule_payee_01@upi"
    events.append({
        "event_type": "BENEFICIARY_ADDED",
        "account_id": account_id,
        "device_id": new_device_id,
        "timestamp": (base_time + timedelta(minutes=2)).isoformat(),
        "metadata": {"beneficiary": payee_id},
        "is_fraud": True,
        "scenario_name": "Account Takeover",
    })
    
    # 4. Escalating transfers: ₹5,000 -> ₹25,000 -> ₹75,000
    amounts = [5000.0, 25000.0, 75000.0]
    for idx, amt in enumerate(amounts):
        events.append({
            "event_type": "TRANSACTION",
            "account_id": account_id,
            "device_id": new_device_id,
            "transaction_id": str(uuid.uuid4()),
            "amount": amt,
            "direction": "OUTGOING",
            "counterparty": payee_id,
            "timestamp": (base_time + timedelta(minutes=3 + idx)).isoformat(),
            "expected_band": "HIGH",
            "scenario_name": "Account Takeover",
            "is_fraud": True,
            "reason_codes": [
                "NEW_DEVICE_BEFORE_TRANSFER",
                "CREDENTIAL_CHANGE_BEFORE_TRANSFER",
                "NEW_BENEFICIARY_BEFORE_TRANSFER",
                "ESCALATING_AMOUNTS_SEQUENCE"
            ]
        })
    return events

def create_scenario_3_manipulated_payment(account_id: str, device_id: str) -> List[Dict[str, Any]]:
    """
    Scenario 3 — Manipulated Payment (APP Scam)
    Correct user, correct device, correct PIN. Large transfer to new payee.
    Technical signals clean. User answers coercion questions ("urgent", "safe account").
    Escalated to HIGH by rule override with scam-specific wording.
    """
    now = datetime.now(timezone.utc)
    return [
        {
            "event_type": "TRANSACTION",
            "account_id": account_id,
            "device_id": device_id,
            "transaction_id": str(uuid.uuid4()),
            "amount": 95000.0,
            "direction": "OUTGOING",
            "counterparty": "cbi_verification_cell@govt.fake.upi",
            "timestamp": now.isoformat(),
            "coercion_answers": {
                "urgent_request": True,
                "secrecy_request": True,
                "safe_account_claim": True,
                "code_sharing_request": False,
            },
            "expected_band": "HIGH",
            "scenario_name": "Manipulated Payment (Coercion)",
            "is_fraud": True,
            "reason_codes": [
                "COERCION_SAFE_ACCOUNT_CLAIM",
                "COERCION_URGENT_REQUEST",
                "COERCION_SECRECY_REQUEST"
            ]
        }
    ]

def create_scenario_4_structuring(account_id: str, device_id: str) -> List[Dict[str, Any]]:
    """
    Scenario 4 — Structuring
    User attempts 4 transfers just under reporting limit (₹9,900, ₹9,800, ₹9,950, ₹9,700) within 10m.
    Caught by deterministic threshold-avoidance rule.
    """
    events = []
    base_time = datetime.now(timezone.utc) - timedelta(minutes=8)
    amounts = [9900.0, 9800.0, 9950.0, 9700.0]
    
    for i, amt in enumerate(amounts):
        events.append({
            "event_type": "TRANSACTION",
            "account_id": account_id,
            "device_id": device_id,
            "transaction_id": str(uuid.uuid4()),
            "amount": amt,
            "direction": "OUTGOING",
            "counterparty": "offshore_remit@upi",
            "timestamp": (base_time + timedelta(minutes=i*2)).isoformat(),
            "expected_band": "HIGH",
            "scenario_name": "Structuring",
            "is_fraud": True,
            "reason_codes": ["STRUCTURING_THRESHOLD_AVOIDANCE"]
        })
    return events

def create_scenario_5_unexpected_money_closer(receiver_account_id: str) -> Dict[str, Any]:
    """
    Scenario 5 — Unexpected Money Arrives (The Closer)
    ₹42,000 arrives from a stranger.
    First-time sender, 2 hops from reported complaint, rapid fan-in receiver, income mismatch.
    User taps Hold for 24 hours -> balance splits -> spend of ₹50k refused -> case opened.
    """
    now = datetime.now(timezone.utc)
    return {
        "event_type": "TRANSACTION",
        "account_id": receiver_account_id,
        "transaction_id": "tx-scenario-5-closer",
        "amount": 42000.0,
        "direction": "INCOMING",
        "counterparty": "karan9921@upi (Stranger)",
        "timestamp": now.isoformat(),
        "expected_band": "HIGH",
        "scenario_name": "Unexpected Money Inflow",
        "is_fraud": True,
        "reason_codes": [
            "UNKNOWN_SENDER",
            "COMPLAINT_PROXIMITY_2_HOPS",
            "HIGH_PASS_THROUGH_RISK",
            "FAN_IN_PATTERN",
            "UNUSUAL_INFLOW"
        ],
        "shap_top": [
            ["complaint_proximity_hops", 0.31],
            ["sender_seen_before", 0.22],
            ["inflow_vs_normal_ratio", 0.19],
            ["pass_through_ratio", 0.15]
        ]
    }

class ScenarioGenerator:
    """Convenience generator class wrapping scenario creation functions."""
    def __init__(self, seed: int = 42):
        self.seed = seed

    def generate_ato_scenario(self, account_id: str = "acc-ato-01", device_id: str = "dev-new-01") -> List[Dict[str, Any]]:
        return create_scenario_2_account_takeover(account_id, device_id)

    def generate_mule_scenario(self, account_id: str = "acc-mule-01", device_id: str = "dev-mule-01") -> List[Dict[str, Any]]:
        res = create_scenario_5_unexpected_money_closer(account_id)
        return [res] if isinstance(res, dict) else res

    def generate_all_scenarios(self, account_id: str = "acc-demo-01", device_id: str = "dev-demo-01") -> List[Dict[str, Any]]:
        s1 = create_scenario_1_quiet(account_id, device_id)
        s2 = create_scenario_2_account_takeover(account_id, "dev-new-99")
        s3 = create_scenario_3_manipulated_payment(account_id, device_id)
        s4 = create_scenario_4_structuring(account_id, device_id)
        s5 = create_scenario_5_unexpected_money_closer(account_id)
        s5_list = [s5] if isinstance(s5, dict) else s5
        return s1 + s2 + s3 + s4 + s5_list
