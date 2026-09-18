from typing import Dict, Any, List, Tuple

class RuleResult:
    def __init__(self, rule_id: str, reason_code: str, severity: str, message: str):
        self.rule_id = rule_id
        self.reason_code = reason_code
        self.severity = severity # 'CRITICAL', 'HIGH', 'MEDIUM'
        self.message = message

    def to_dict(self) -> Dict[str, Any]:
        return {
            "rule_id": self.rule_id,
            "reason_code": self.reason_code,
            "severity": self.severity,
            "message": self.message,
        }

class DeterministicRuleEngine:
    """
    ARCShield Deterministic Rule Engine.
    Executes rules that encode policy, statutory compliance, or hard safety overrides.
    Cannot be degraded by training data drift.
    """
    def evaluate(self, features: Dict[str, Any]) -> List[RuleResult]:
        fired_rules = []

        # 1. Hard Coercion Override (F-04)
        if features.get("safe_account_claim", 0.0) == 1.0:
            fired_rules.append(RuleResult(
                rule_id="RULE-COERCION-01",
                reason_code="COERCION_SAFE_ACCOUNT_CLAIM",
                severity="CRITICAL",
                message="User indicated transfer is to a purported 'safe account' (Classic impersonation scam)."
            ))

        if features.get("urgent_request", 0.0) == 1.0 and features.get("secrecy_request", 0.0) == 1.0:
            fired_rules.append(RuleResult(
                rule_id="RULE-COERCION-02",
                reason_code="COERCION_HIGH_PRESSURE",
                severity="HIGH",
                message="User prompted under urgency and secrecy demand."
            ))

        # 2. Structuring Threshold Avoidance (F-05)
        if features.get("threshold_avoidance_score", 0.0) >= 0.8:
            fired_rules.append(RuleResult(
                rule_id="RULE-STRUCT-01",
                reason_code="STRUCTURING_THRESHOLD_AVOIDANCE",
                severity="HIGH",
                message="Multiple consecutive transfers clustering just below regulatory reporting limit."
            ))

        # 3. Account Takeover Event Sequence (F-02)
        if (features.get("new_device_before_transfer", 0.0) == 1.0 and 
            features.get("credential_change_before_transfer", 0.0) == 1.0):
            fired_rules.append(RuleResult(
                rule_id="RULE-ATO-01",
                reason_code="TAKEOVER_EVENT_SEQUENCE",
                severity="CRITICAL",
                message="High-risk sequence: Password changed on new device immediately prior to transfer."
            ))

        # 4. Money Mule Pass-Through Trap (F-07)
        if (features.get("direction_incoming", 0.0) == 1.0 and 
            features.get("pass_through_ratio", 0.0) >= 0.85):
            fired_rules.append(RuleResult(
                rule_id="RULE-MULE-01",
                reason_code="HIGH_PASS_THROUGH_RISK",
                severity="HIGH",
                message="Funds match rapid pass-through forwarding pattern typical of money-mule layering."
            ))

        # 5. Direct Complaint Proximity (F-11)
        hops = features.get("complaint_proximity_hops", 99)
        if hops <= 2:
            fired_rules.append(RuleResult(
                rule_id="RULE-GRAPH-01",
                reason_code=f"COMPLAINT_PROXIMITY_{hops}_HOPS",
                severity="HIGH",
                message=f"Counterparty is {hops} hops away from a verified cybercrime complaint."
            ))

        # 6. Unknown Inflow Mismatch (F-06, F-10)
        if (features.get("direction_incoming", 0.0) == 1.0 and 
            features.get("sender_seen_before", 1.0) == 0.0 and 
            features.get("inflow_vs_normal_ratio", 0.0) >= 0.7):
            fired_rules.append(RuleResult(
                rule_id="RULE-INFLOW-01",
                reason_code="UNKNOWN_SENDER_UNUSUAL_INFLOW",
                severity="HIGH",
                message="Substantial unexpected credit from an unrecognised sender."
            ))

        return fired_rules

rule_engine = DeterministicRuleEngine()
