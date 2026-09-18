"""
ARCShield: SHAP TreeExplainer Integration
Provides per-prediction feature attribution using Shapley values.

When a trained XGBoost model is available, uses SHAP's TreeExplainer
for exact Shapley values. Otherwise, falls back to the weight-based
approximation in registry.py.
"""

import os
import json
import numpy as np
from typing import Dict, Any, List, Tuple, Optional

# Must match the column order used in train.py
FEATURE_COLUMNS = [
    "amount_zscore",
    "device_novelty",
    "recipient_novelty",
    "new_device_before_transfer",
    "credential_change_before_transfer",
    "escalating_amounts",
    "urgent_request",
    "safe_account_claim",
    "threshold_avoidance_score",
    "direction_incoming",
    "sender_seen_before",
    "pass_through_ratio",
    "fan_in_ratio",
    "fan_out_ratio",
    "dormancy_break_score",
    "inflow_vs_normal_ratio",
    "complaint_proximity_hops",
    "shared_device_count",
    "connected_flagged_accounts",
    "component_size",
]

# Human-readable labels for reason code display
FEATURE_LABELS = {
    "amount_zscore": "Unusual Transaction Amount",
    "device_novelty": "New/Unknown Device",
    "recipient_novelty": "Unknown Recipient",
    "new_device_before_transfer": "New Device Before Transfer",
    "credential_change_before_transfer": "Credential Change Sequence",
    "escalating_amounts": "Escalating Transfer Amounts",
    "urgent_request": "Urgency Pressure Detected",
    "safe_account_claim": "Safe Account Claim (Coercion)",
    "threshold_avoidance_score": "Threshold Avoidance Pattern",
    "direction_incoming": "Incoming Direction",
    "sender_seen_before": "Unknown Sender",
    "pass_through_ratio": "Rapid Pass-Through Velocity",
    "fan_in_ratio": "High Fan-In (Multiple Sources)",
    "fan_out_ratio": "High Fan-Out (Multiple Destinations)",
    "dormancy_break_score": "Dormant Account Reactivation",
    "inflow_vs_normal_ratio": "Abnormal Inflow Volume",
    "complaint_proximity_hops": "Proximity to Complaint Entity",
    "shared_device_count": "Shared Device with Flagged Account",
    "connected_flagged_accounts": "Connected Flagged Accounts",
    "component_size": "Large Network Component",
}


class ShapExplainer:
    """
    Wrapper around SHAP's TreeExplainer for per-prediction feature attribution.
    Gracefully degrades to a weight-based approximation if SHAP or the trained
    model are unavailable.
    """

    def __init__(self, model_path: str = "models/artifacts/bgt_risk_model.json"):
        self.model = None
        self.shap_explainer = None
        self._load(model_path)

    def _load(self, model_path: str):
        """Attempts to load a trained XGBoost model and init SHAP."""
        if not os.path.exists(model_path):
            print(f"[INFO] No trained model at {model_path}. Using weight-based explanation.")
            return

        try:
            import xgboost as xgb
            self.model = xgb.Booster()
            self.model.load_model(model_path)
            print(f"[INFO] Loaded XGBoost model from {model_path}")

            try:
                import shap
                self.shap_explainer = shap.TreeExplainer(self.model)
                print("[INFO] SHAP TreeExplainer initialized.")
            except ImportError:
                print("[WARN] shap not installed. Using model feature importance fallback.")
        except ImportError:
            print("[WARN] xgboost not installed. Using weight-based explanation.")
        except Exception as e:
            print(f"[WARN] Failed to load model: {e}. Using weight-based explanation.")

    def explain(
        self,
        feature_vector: Dict[str, Any],
        top_k: int = 5,
    ) -> List[Dict[str, Any]]:
        """
        Computes feature contributions for a single prediction.
        
        Returns:
            List of dicts with keys: feature, label, contribution, direction
            Sorted by absolute contribution descending.
        """
        if self.shap_explainer is not None:
            return self._explain_shap(feature_vector, top_k)
        else:
            return self._explain_weights(feature_vector, top_k)

    def _explain_shap(self, feature_vector: Dict[str, Any], top_k: int) -> List[Dict[str, Any]]:
        """Uses SHAP TreeExplainer for exact Shapley values."""
        import xgboost as xgb

        # Convert feature_vector dict to numpy array in column order
        row = np.array([[feature_vector.get(col, 0.0) for col in FEATURE_COLUMNS]])
        dmatrix = xgb.DMatrix(row, feature_names=FEATURE_COLUMNS)

        shap_values = self.shap_explainer.shap_values(dmatrix)

        contributions = []
        for i, feat in enumerate(FEATURE_COLUMNS):
            sv = float(shap_values[0][i])
            if abs(sv) > 0.01:
                contributions.append({
                    "feature": feat,
                    "label": FEATURE_LABELS.get(feat, feat),
                    "contribution": round(sv, 4),
                    "direction": "INCREASES_RISK" if sv > 0 else "DECREASES_RISK",
                    "feature_value": feature_vector.get(feat, 0.0),
                })

        contributions.sort(key=lambda x: abs(x["contribution"]), reverse=True)
        return contributions[:top_k]

    def _explain_weights(self, feature_vector: Dict[str, Any], top_k: int) -> List[Dict[str, Any]]:
        """
        Fallback weight-based approximation when SHAP is unavailable.
        Estimates feature contributions from known model weight magnitudes.
        """
        # Approximate weight mapping (mirrors registry.py logic)
        weight_map = {
            "complaint_proximity_hops": lambda v: 0.35 if v <= 2 else (0.18 if v <= 3 else 0.0),
            "sender_seen_before": lambda v: 0.24 if v == 0.0 and feature_vector.get("direction_incoming") == 1.0 else 0.0,
            "safe_account_claim": lambda v: v * 0.42,
            "pass_through_ratio": lambda v: v * 0.28,
            "new_device_before_transfer": lambda v: v * 0.26,
            "escalating_amounts": lambda v: v * 0.27,
            "threshold_avoidance_score": lambda v: v * 0.31,
            "amount_zscore": lambda v: min(0.30, max(0, v) * 0.14),
            "inflow_vs_normal_ratio": lambda v: min(0.25, v * 0.12),
            "urgent_request": lambda v: v * 0.30,
            "device_novelty": lambda v: v * 0.18,
            "recipient_novelty": lambda v: v * 0.12,
            "dormancy_break_score": lambda v: v * 0.22,
            "fan_in_ratio": lambda v: v * 0.20,
            "connected_flagged_accounts": lambda v: min(0.30, v * 0.10),
            "shared_device_count": lambda v: min(0.25, v * 0.12),
        }

        contributions = []
        for feat, calc in weight_map.items():
            val = feature_vector.get(feat, 0.0)
            try:
                impact = calc(val)
            except (TypeError, ValueError):
                impact = 0.0

            if abs(impact) > 0.03:
                contributions.append({
                    "feature": feat,
                    "label": FEATURE_LABELS.get(feat, feat),
                    "contribution": round(impact, 4),
                    "direction": "INCREASES_RISK" if impact > 0 else "DECREASES_RISK",
                    "feature_value": val,
                })

        contributions.sort(key=lambda x: abs(x["contribution"]), reverse=True)
        return contributions[:top_k]

    def get_feature_importance(self) -> Optional[Dict[str, float]]:
        """Returns global feature importance from the trained model."""
        if self.model is None:
            return None
        try:
            importance = self.model.get_score(importance_type="gain")
            return {k: round(v, 4) for k, v in sorted(importance.items(), key=lambda x: -x[1])}
        except Exception:
            return None


# Singleton instance
shap_explainer = ShapExplainer()
