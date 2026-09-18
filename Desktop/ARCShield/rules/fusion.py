from typing import Dict, Any, List
from .engine import RuleResult

class RiskFusionEngine:
    """
    Blends machine learning predictions, SHAP contributions, and deterministic rule fires.
    Applies hard overrides and synthesizes final risk bands and human-readable reason codes.
    """
    def fuse(
        self,
        model_prob: float,
        fired_rules: List[RuleResult],
        direction: str,
        shap_top: List[List[Any]]
    ) -> Dict[str, Any]:
        has_critical_rule = any(r.severity == "CRITICAL" for r in fired_rules)
        has_high_rule = any(r.severity == "HIGH" for r in fired_rules)

        # Baseline score from model (0 to 100)
        risk_score = int(round(model_prob * 100))

        # Elevate score if hard rules tripped
        if has_critical_rule:
            risk_score = max(risk_score, 92)
        elif has_high_rule:
            risk_score = max(risk_score, 78)

        # Determine Risk Band
        if risk_score >= 70 or has_critical_rule or has_high_rule:
            risk_band = "HIGH"
        elif risk_score >= 40:
            risk_band = "MEDIUM"
        else:
            risk_band = "LOW"

        # Determine Recommended Action
        if risk_band == "HIGH":
            recommended_action = "QUARANTINE" if direction == "INCOMING" else "HOLD_VERIFY"
        elif risk_band == "MEDIUM":
            recommended_action = "CHALLENGE"
        else:
            recommended_action = "ALLOW"

        # Assemble ordered reason codes
        reason_codes = []
        for r in fired_rules:
            if r.reason_code not in reason_codes:
                reason_codes.append(r.reason_code)

        # Append top SHAP features as supplemental reasons if not already present
        for feat_name, impact in shap_top[:3]:
            code_label = feat_name.upper()
            if code_label not in reason_codes and impact > 0.1:
                reason_codes.append(code_label)

        if not reason_codes:
            reason_codes = ["ROUTINE_TRANSACTION"] if risk_band == "LOW" else ["STATISTICAL_BEHAVIORAL_ANOMALY"]

        return {
            "risk_score": risk_score,
            "risk_band": risk_band,
            "recommended_action": recommended_action,
            "model_version": "bgt-risk-1.4.0",
            "reason_codes": reason_codes,
            "shap_top": shap_top,
        }

fusion_engine = RiskFusionEngine()
