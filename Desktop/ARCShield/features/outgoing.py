import math
from datetime import datetime
from typing import List, Dict, Any, Optional

def compute_outgoing_features(
    transaction: Dict[str, Any],
    recent_events: List[Dict[str, Any]],
    historical_transactions: List[Dict[str, Any]],
    known_devices: List[str],
    known_recipients: List[str]
) -> Dict[str, Any]:
    """
    Computes Outgoing Intelligence features (F-01 to F-05).
    Strictly point-in-time correct: historical_transactions and recent_events
    must only contain records prior to transaction timestamp.
    """
    amount = float(transaction.get("amount", 0.0))
    log_amount = math.log1p(amount) if amount > 0 else 0.0

    # 1. Behavioral Drift (Rolling baselines F-01)
    past_amounts = [float(t["amount"]) for t in historical_transactions if t.get("direction") == "OUTGOING"]
    if len(past_amounts) >= 5:
        mean_amt = sum(past_amounts) / len(past_amounts)
        variance = sum((x - mean_amt) ** 2 for x in past_amounts) / len(past_amounts)
        std_amt = math.sqrt(variance) if variance > 0 else 1.0
        amount_zscore = max(0.0, (amount - mean_amt) / std_amt)
    else:
        amount_zscore = 0.5  # Cold-start fallback prior

    device_id = transaction.get("device_id")
    device_novelty = 1.0 if device_id and device_id not in known_devices else 0.0

    counterparty = transaction.get("counterparty") or transaction.get("counterparty_identifier")
    recipient_novelty = 1.0 if counterparty and counterparty not in known_recipients else 0.0

    # 2. Event Sequence Detection (F-02)
    # Check if events in the last 15 minutes indicate takeover chain
    new_dev_event = any(e.get("event_type") == "LOGIN_NEW_DEVICE" for e in recent_events) or bool(transaction.get("new_device_before_transfer"))
    cred_change_event = any(e.get("event_type") == "PASSWORD_CHANGE" for e in recent_events) or bool(transaction.get("credential_change_before_transfer"))
    new_bene_event = any(e.get("event_type") == "BENEFICIARY_ADDED" for e in recent_events) or bool(transaction.get("new_beneficiary_before_transfer"))
    failed_auth_event = any(e.get("event_type") == "FAILED_AUTH" for e in recent_events) or bool(transaction.get("failed_auth_before_success"))

    # Escalating amounts sequence check
    recent_tx_amounts = [
        float(e["amount"]) for e in recent_events 
        if e.get("event_type") == "TRANSACTION" and "amount" in e
    ]
    is_escalating = bool(transaction.get("escalating_amounts"))
    if len(recent_tx_amounts) >= 2:
        is_escalating = is_escalating or all(
            recent_tx_amounts[i] < recent_tx_amounts[i+1] 
            for i in range(len(recent_tx_amounts)-1)
        )

    # 3. Coercion signals (F-04)
    coercion = transaction.get("coercion_answers") or {}
    urgent_request = 1.0 if coercion.get("urgent_request") or coercion.get("urgent") or transaction.get("urgent_request") else 0.0
    secrecy_request = 1.0 if coercion.get("secrecy_request") or coercion.get("secret") or transaction.get("secrecy_request") else 0.0
    safe_account_claim = 1.0 if coercion.get("safe_account_claim") or coercion.get("safe_account") or transaction.get("safe_account_claim") else 0.0
    code_sharing_request = 1.0 if coercion.get("code_sharing_request") or coercion.get("share_code") or transaction.get("code_sharing_request") else 0.0

    # 4. Structuring Detection (F-05)
    # Check if recent outgoing transactions cluster just under threshold limits (e.g. 10k, 25k, 50k)
    structuring_score = 0.0
    if 9500 <= amount <= 9999 or 24000 <= amount <= 24999:
        structuring_score += 0.6
        near_threshold_count = sum(
            1 for a in recent_tx_amounts if (9500 <= a <= 9999 or 24000 <= a <= 24999)
        )
        if near_threshold_count >= 2:
            structuring_score = 1.0

    return {
        "amount": amount,
        "log_amount": log_amount,
        "amount_zscore": round(amount_zscore, 3),
        "device_novelty": device_novelty,
        "recipient_novelty": recipient_novelty,
        "new_device_before_transfer": 1.0 if new_dev_event else 0.0,
        "credential_change_before_transfer": 1.0 if cred_change_event else 0.0,
        "new_beneficiary_before_transfer": 1.0 if new_bene_event else 0.0,
        "failed_auth_before_success": 1.0 if failed_auth_event else 0.0,
        "escalating_amounts": 1.0 if is_escalating else 0.0,
        "rapid_sequence": 1.0 if len(recent_events) >= 3 else 0.0,
        "urgent_request": urgent_request,
        "secrecy_request": secrecy_request,
        "safe_account_claim": safe_account_claim,
        "code_sharing_request": code_sharing_request,
        "threshold_avoidance_score": round(structuring_score, 2),
    }
