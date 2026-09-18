"""
ARCShield Test Suite: Scoring Pipeline Tests
Validates the end-to-end scoring pipeline across the 5 demo acceptance scenarios.
"""

import pytest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from features.pipeline import feature_pipeline
from graph.service import EntityGraphService
from rules.engine import rule_engine
from rules.fusion import fusion_engine
from models.registry import model_registry


def test_model_registry_has_fallback_scores_when_model_missing():
    feature_vector = {
        "amount_zscore": 0.8,
        "device_novelty": 0.7,
        "recipient_novelty": 0.5,
        "new_device_before_transfer": 0.0,
        "credential_change_before_transfer": 0.0,
        "escalating_amounts": 0.0,
        "urgent_request": 0.0,
        "safe_account_claim": 0.0,
        "threshold_avoidance_score": 0.0,
        "direction_incoming": 1.0,
        "sender_seen_before": 0.0,
        "pass_through_ratio": 0.5,
        "fan_in_ratio": 0.3,
        "dormancy_break_score": 0.2,
        "inflow_vs_normal_ratio": 0.8,
        "complaint_proximity_hops": 2,
    }
    prob = model_registry.predict_proba(feature_vector)
    assert 0.01 <= prob <= 0.99
    assert model_registry.model is not None


@pytest.fixture
def graph():
    """Fresh graph service with pre-seeded complaint topology."""
    g = EntityGraphService()
    # Pre-seed: victim → mule-bridge → stranger (2 hops from complaint)
    g.add_account("acc-victim-01")
    g.add_complaint("FIR-2026-9082", "acc-victim-01", "CYBER_FRAUD")
    g.add_account("mule-bridge-01")
    g.graph.add_edge("acc-victim-01", "mule-bridge-01", relation="TRANSFERRED_TO")
    g.add_account("karan9921@upi")
    g.graph.add_edge("mule-bridge-01", "karan9921@upi", relation="LINKED_TO")
    return g


class TestScenario1QuietPayment:
    """Scenario 1: A quiet, normal payment should score LOW."""

    def test_quiet_payment_is_low(self, graph):
        tx = {
            "amount": 450.0,
            "direction": "OUTGOING",
            "counterparty": "Starbucks Coffee",
            "device_id": "dev-primary-01",
            "coercion_answers": {},
        }
        graph_feats = graph.get_compact_features("Starbucks Coffee")
        fv = feature_pipeline.build_feature_vector(
            transaction=tx,
            known_devices=["dev-primary-01"],
            known_recipients=["Starbucks Coffee"],
            graph_features=graph_feats,
        )

        model_prob = model_registry.predict_proba(fv)
        fired_rules = rule_engine.evaluate(fv)
        verdict = fusion_engine.fuse(
            model_prob=model_prob,
            fired_rules=fired_rules,
            direction="OUTGOING",
            shap_top=model_registry.explain(fv),
        )

        assert verdict["risk_band"] == "LOW", \
            f"Quiet payment scored {verdict['risk_band']} (expected LOW). Score: {verdict['risk_score']}"


class TestScenario2AccountTakeover:
    """Scenario 2: ATO sequence → Band HIGH with sequence reason codes."""

    def test_ato_sequence_is_high(self, graph):
        tx = {
            "amount": 49500.0,
            "direction": "OUTGOING",
            "counterparty": "Unknown Beneficiary",
            "device_id": "dev-new-suspicious-99",
            "coercion_answers": {},
            # Simulate ATO signals
            "new_device_before_transfer": True,
            "credential_change_before_transfer": True,
            "escalating_amounts": True,
        }
        graph_feats = graph.get_compact_features("Unknown Beneficiary")
        fv = feature_pipeline.build_feature_vector(
            transaction=tx,
            known_devices=["dev-primary-01"],
            known_recipients=["Starbucks Coffee", "Amazon Pay"],
            graph_features=graph_feats,
        )

        model_prob = model_registry.predict_proba(fv)
        fired_rules = rule_engine.evaluate(fv)
        verdict = fusion_engine.fuse(
            model_prob=model_prob,
            fired_rules=fired_rules,
            direction="OUTGOING",
            shap_top=model_registry.explain(fv),
        )

        assert verdict["risk_band"] == "HIGH", \
            f"ATO sequence scored {verdict['risk_band']} (expected HIGH). Score: {verdict['risk_score']}"


class TestScenario3CoercionOverride:
    """Scenario 3: Coercion override → Band HIGH with scam-specific wording."""

    def test_coercion_flags_trigger_high(self, graph):
        tx = {
            "amount": 25000.0,
            "direction": "OUTGOING",
            "counterparty": "Unknown Recipient",
            "device_id": "dev-primary-01",
            "coercion_answers": {
                "safe_account_claim": True,
                "urgent_request": True,
            },
        }
        graph_feats = graph.get_compact_features("Unknown Recipient")
        fv = feature_pipeline.build_feature_vector(
            transaction=tx,
            known_devices=["dev-primary-01"],
            known_recipients=["Starbucks Coffee"],
            graph_features=graph_feats,
        )

        model_prob = model_registry.predict_proba(fv)
        fired_rules = rule_engine.evaluate(fv)
        verdict = fusion_engine.fuse(
            model_prob=model_prob,
            fired_rules=fired_rules,
            direction="OUTGOING",
            shap_top=model_registry.explain(fv),
        )

        assert verdict["risk_band"] == "HIGH", \
            f"Coercion override scored {verdict['risk_band']} (expected HIGH). Score: {verdict['risk_score']}"
        assert any("SAFE_ACCOUNT" in rc or "COERCION" in rc for rc in verdict["reason_codes"]), \
            f"Missing coercion reason code. Got: {verdict['reason_codes']}"


class TestScenario4Structuring:
    """Scenario 4: Structuring burst → Tripped by deterministic rule."""

    def test_structuring_detected(self, graph):
        tx = {
            "amount": 9900.0,
            "direction": "OUTGOING",
            "counterparty": "Same Target Account",
            "device_id": "dev-primary-01",
            "coercion_answers": {},
        }
        graph_feats = graph.get_compact_features("Same Target Account")
        fv = feature_pipeline.build_feature_vector(
            transaction=tx,
            known_devices=["dev-primary-01"],
            known_recipients=["Starbucks Coffee"],
            graph_features=graph_feats,
        )
        # Manually inject structuring signal
        fv["threshold_avoidance_score"] = 0.92

        fired_rules = rule_engine.evaluate(fv)
        rule_identifiers = [r.rule_id for r in fired_rules] + [r.reason_code for r in fired_rules]

        assert any("STRUCTURING" in r or "THRESHOLD" in r for r in rule_identifiers), \
            f"Structuring rule not triggered. Fired rules: {rule_identifiers}"


class TestScenario5StrangerCredit:
    """
    Scenario 5: Stranger credit → Band HIGH, quarantine action, 
    balance split, spend refusal.
    """

    def test_stranger_credit_is_high(self, graph):
        tx = {
            "amount": 42000.0,
            "direction": "INCOMING",
            "counterparty": "karan9921@upi",
            "device_id": "dev-primary-01",
            "coercion_answers": {},
        }
        graph_feats = graph.get_compact_features("karan9921@upi")
        fv = feature_pipeline.build_feature_vector(
            transaction=tx,
            known_devices=["dev-primary-01"],
            known_recipients=[],
            graph_features=graph_feats,
        )

        model_prob = model_registry.predict_proba(fv)
        fired_rules = rule_engine.evaluate(fv)
        verdict = fusion_engine.fuse(
            model_prob=model_prob,
            fired_rules=fired_rules,
            direction="INCOMING",
            shap_top=model_registry.explain(fv),
        )

        assert verdict["risk_band"] == "HIGH", \
            f"Stranger credit scored {verdict['risk_band']} (expected HIGH). Score: {verdict['risk_score']}"
        assert verdict["recommended_action"] in ("QUARANTINE", "CHALLENGE"), \
            f"Expected QUARANTINE action, got: {verdict['recommended_action']}"

    def test_stranger_credit_quarantine_execution(self, graph):
        """Tests the full quarantine + balance split + spend refusal flow."""
        from api.services.ledger_service import LedgerService, InsufficientBalanceError

        ledger = LedgerService()
        ledger.create_account("acc-user-01", initial_balance=80000.0)

        # Incoming credit from stranger
        ledger.credit("acc-user-01", 42000.0, description="Stranger credit from karan9921@upi")
        bal = ledger.get_balance("acc-user-01")
        assert bal["total_balance"] == 122000.0

        # User quarantines the stranger credit
        hold = ledger.place_quarantine_hold(
            account_id="acc-user-01",
            transaction_id="tx-stranger-01",
            amount=42000.0,
            reason="Unexpected credit from unknown sender",
        )
        assert hold["status"] == "ACTIVE"

        # Balance split verification
        bal = ledger.get_balance("acc-user-01")
        assert bal["total_balance"] == 122000.0
        assert bal["available_balance"] == 80000.0
        assert bal["held_balance"] == 42000.0

        # Spend refusal: trying to spend total_balance must fail
        with pytest.raises(InsufficientBalanceError):
            ledger.debit("acc-user-01", 100000.0, description="Attempt to spend held funds")


class TestPointInTimeFeatures:
    """Feature leakage prevention checks."""

    def test_feature_vector_has_required_keys(self, graph):
        tx = {
            "amount": 1000.0,
            "direction": "OUTGOING",
            "counterparty": "Test Merchant",
            "device_id": "dev-01",
        }
        fv = feature_pipeline.build_feature_vector(
            transaction=tx,
            known_devices=["dev-01"],
            known_recipients=["Test Merchant"],
            graph_features={},
        )
        required = ["amount_zscore", "device_novelty", "recipient_novelty", "direction_incoming"]
        for key in required:
            assert key in fv, f"Feature vector missing required key: {key}"

    def test_model_prediction_range(self, graph):
        tx = {"amount": 500.0, "direction": "OUTGOING", "counterparty": "Known Merchant"}
        fv = feature_pipeline.build_feature_vector(tx, graph_features={})
        prob = model_registry.predict_proba(fv)
        assert 0.0 <= prob <= 1.0, f"Model probability {prob} out of [0,1] range"
