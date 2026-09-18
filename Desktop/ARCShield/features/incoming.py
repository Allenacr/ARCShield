import math
from datetime import datetime
from typing import List, Dict, Any, Optional

def compute_incoming_features(
    transaction: Dict[str, Any],
    historical_credits: List[Dict[str, Any]],
    historical_debits: List[Dict[str, Any]],
    sender_history: List[Dict[str, Any]],
    graph_features: Dict[str, Any],
    typical_monthly_inflow: float = 50000.0
) -> Dict[str, Any]:
    """
    Computes Incoming Intelligence features (F-06 to F-12).
    Addresses unsolicited credits, pass-through money mules, fan-in spikes, and complaint proximity.
    """
    amount = float(transaction.get("amount", 0.0))
    sender_id = transaction.get("counterparty") or transaction.get("counterparty_identifier")

    # 1. Unknown Sender & Relationship Age (F-06)
    sender_seen_before = 1.0 if any(
        c.get("counterparty") == sender_id or c.get("counterparty_identifier") == sender_id
        for c in historical_credits
    ) else 0.0

    relationship_age_days = len(sender_history) * 5 if sender_seen_before else 0

    # 2. Pass-Through Speed & Ratio (F-07)
    # Check if there is a rapid subsequent debit or historical rapid forward pattern
    pass_through_ratio = 0.0
    incoming_to_outgoing_seconds = 999999.0

    if historical_debits and historical_credits:
        latest_debit = historical_debits[-1]
        debit_amt = float(latest_debit.get("amount", 0.0))
        if amount > 0:
            pass_through_ratio = min(1.0, round(debit_amt / amount, 2))

    # 3. Fan-in / Fan-out Concentration (F-08)
    recent_distinct_senders = len(set(
        c.get("counterparty") for c in historical_credits[-10:] if c.get("counterparty")
    ))
    fan_in_ratio = min(1.0, recent_distinct_senders / 10.0) if historical_credits else 0.0

    # 4. Dormancy Break (F-09)
    dormancy_break_score = 0.0
    if len(historical_credits) == 0:
        dormancy_break_score = 0.8
    elif len(historical_credits) < 3 and amount > 30000:
        dormancy_break_score = 0.9

    # 5. Income Mismatch (F-10)
    # Never presented as proof of fraud, always as unusual inflow relative to history
    inflow_vs_normal_ratio = round(amount / typical_monthly_inflow, 2) if typical_monthly_inflow > 0 else 1.0

    # 6. Complaint Proximity (F-11)
    complaint_proximity_hops = graph_features.get("hops_to_flagged_account", 99)

    return {
        "amount": amount,
        "sender_seen_before": sender_seen_before,
        "relationship_age_days": relationship_age_days,
        "incoming_to_outgoing_seconds": incoming_to_outgoing_seconds,
        "pass_through_ratio": pass_through_ratio,
        "fan_in_ratio": round(fan_in_ratio, 2),
        "dormancy_break_score": round(dormancy_break_score, 2),
        "inflow_vs_normal_ratio": inflow_vs_normal_ratio,
        "complaint_proximity_hops": complaint_proximity_hops,
        "connected_flagged_accounts": graph_features.get("connected_flagged_accounts", 0),
    }
