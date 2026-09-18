from typing import Dict, Any, List, Optional
from .outgoing import compute_outgoing_features
from .incoming import compute_incoming_features

class FeaturePipeline:
    """
    Unified Feature Pipeline imported identically by training, evaluation, and online serving.
    Guarantees zero training-serving skew.
    """
    FEATURE_COLUMNS = [
        "amount",
        "direction_incoming",
        "amount_zscore",
        "device_novelty",
        "recipient_novelty",
        "new_device_before_transfer",
        "credential_change_before_transfer",
        "new_beneficiary_before_transfer",
        "escalating_amounts",
        "rapid_sequence",
        "urgent_request",
        "secrecy_request",
        "safe_account_claim",
        "threshold_avoidance_score",
        "sender_seen_before",
        "pass_through_ratio",
        "fan_in_ratio",
        "dormancy_break_score",
        "inflow_vs_normal_ratio",
        "complaint_proximity_hops",
        "connected_flagged_accounts",
    ]

    def build_feature_vector(
        self,
        transaction: Dict[str, Any],
        recent_events: Optional[List[Dict[str, Any]]] = None,
        historical_transactions: Optional[List[Dict[str, Any]]] = None,
        known_devices: Optional[List[str]] = None,
        known_recipients: Optional[List[str]] = None,
        graph_features: Optional[Dict[str, Any]] = None,
        typical_monthly_inflow: float = 50000.0,
    ) -> Dict[str, Any]:
        direction = transaction.get("direction", "OUTGOING")
        recent_events = recent_events or []
        historical_transactions = historical_transactions or []
        known_devices = known_devices or []
        known_recipients = known_recipients or []
        graph_features = graph_features or {}

        if direction == "OUTGOING":
            raw = compute_outgoing_features(
                transaction=transaction,
                recent_events=recent_events,
                historical_transactions=historical_transactions,
                known_devices=known_devices,
                known_recipients=known_recipients,
            )
            # Fill incoming specific fields with safe defaults
            raw.update({
                "direction_incoming": 0.0,
                "sender_seen_before": 1.0,
                "pass_through_ratio": 0.0,
                "fan_in_ratio": 0.0,
                "dormancy_break_score": 0.0,
                "inflow_vs_normal_ratio": 0.0,
                "complaint_proximity_hops": graph_features.get("hops_to_flagged_account", 99),
                "connected_flagged_accounts": graph_features.get("connected_flagged_accounts", 0),
            })
        else: # INCOMING
            credits = [t for t in historical_transactions if t.get("direction") == "INCOMING"]
            debits = [t for t in historical_transactions if t.get("direction") == "OUTGOING"]
            raw = compute_incoming_features(
                transaction=transaction,
                historical_credits=credits,
                historical_debits=debits,
                sender_history=[],
                graph_features=graph_features,
                typical_monthly_inflow=typical_monthly_inflow,
            )
            # Fill outgoing specific fields with safe defaults
            raw.update({
                "direction_incoming": 1.0,
                "amount_zscore": 0.0,
                "device_novelty": 0.0,
                "recipient_novelty": 0.0,
                "new_device_before_transfer": 0.0,
                "credential_change_before_transfer": 0.0,
                "new_beneficiary_before_transfer": 0.0,
                "escalating_amounts": 0.0,
                "rapid_sequence": 0.0,
                "urgent_request": 0.0,
                "secrecy_request": 0.0,
                "safe_account_claim": 0.0,
                "threshold_avoidance_score": 0.0,
            })

        # Return ordered dict matching FEATURE_COLUMNS
        return {col: raw.get(col, 0.0) for col in self.FEATURE_COLUMNS}

feature_pipeline = FeaturePipeline()
