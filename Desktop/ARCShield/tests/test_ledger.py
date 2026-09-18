"""
ARCShield Test Suite: Ledger Invariant Verification
Tests the core quarantine ledger guarantee:
    total_balance == available_balance + held_balance

These tests verify the critical F-15 headline feature semantics.
"""

import pytest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from api.services.ledger_service import (
    LedgerService,
    InsufficientBalanceError,
    HoldNotFoundError,
    HoldAlreadyResolvedError,
    LedgerInvariantViolation,
)


@pytest.fixture
def ledger():
    """Fresh ledger instance for each test."""
    return LedgerService()


class TestLedgerBasicOperations:
    """Tests basic credit/debit operations."""

    def test_create_account_with_balance(self, ledger):
        acct = ledger.create_account("acc-001", initial_balance=80000.0)
        assert acct["total_balance"] == 80000.0
        assert acct["available_balance"] == 80000.0
        assert acct["held_balance"] == 0.0

    def test_credit_increases_balances(self, ledger):
        ledger.create_account("acc-001", initial_balance=50000.0)
        ledger.credit("acc-001", 10000.0, description="Salary credit")
        bal = ledger.get_balance("acc-001")
        assert bal["total_balance"] == 60000.0
        assert bal["available_balance"] == 60000.0

    def test_debit_decreases_balances(self, ledger):
        ledger.create_account("acc-001", initial_balance=50000.0)
        ledger.debit("acc-001", 15000.0, description="Bill payment")
        bal = ledger.get_balance("acc-001")
        assert bal["total_balance"] == 35000.0
        assert bal["available_balance"] == 35000.0

    def test_debit_exceeds_available_raises_error(self, ledger):
        ledger.create_account("acc-001", initial_balance=10000.0)
        with pytest.raises(InsufficientBalanceError):
            ledger.debit("acc-001", 15000.0)


class TestQuarantineHoldSemantics:
    """Tests the core quarantine hold feature (F-15)."""

    def test_quarantine_splits_balance(self, ledger):
        """Core PRD Scenario: Quarantine ₹42,000 in an ₹80,000 account."""
        ledger.create_account("acc-001", initial_balance=80000.0)
        hold = ledger.place_quarantine_hold(
            account_id="acc-001",
            transaction_id="tx-suspicious-01",
            amount=42000.0,
            reason="Unsolicited credit from unknown sender",
        )

        bal = ledger.get_balance("acc-001")
        assert bal["total_balance"] == 80000.0
        assert bal["available_balance"] == 38000.0  # 80000 - 42000
        assert bal["held_balance"] == 42000.0
        assert hold["status"] == "ACTIVE"

    def test_invariant_holds_after_quarantine(self, ledger):
        """Assert total == available + held after quarantine."""
        ledger.create_account("acc-001", initial_balance=80000.0)
        ledger.place_quarantine_hold("acc-001", "tx-01", 42000.0)

        bal = ledger.get_balance("acc-001")
        assert bal["total_balance"] == bal["available_balance"] + bal["held_balance"]

    def test_spend_blocked_by_quarantine(self, ledger):
        """
        Critical test: After quarantining ₹42,000 in ₹80,000 account,
        attempting to transfer ₹50,000 MUST fail.
        """
        ledger.create_account("acc-001", initial_balance=80000.0)
        ledger.place_quarantine_hold("acc-001", "tx-01", 42000.0)

        # ₹50,000 > ₹38,000 available → must fail
        with pytest.raises(InsufficientBalanceError, match="Insufficient available balance"):
            ledger.debit("acc-001", 50000.0, description="Outgoing transfer attempt")

    def test_can_spend_within_available(self, ledger):
        """After quarantine, spending within available_balance works."""
        ledger.create_account("acc-001", initial_balance=80000.0)
        ledger.place_quarantine_hold("acc-001", "tx-01", 42000.0)

        # ₹30,000 < ₹38,000 available → should succeed
        ledger.debit("acc-001", 30000.0, description="Legitimate transfer")
        bal = ledger.get_balance("acc-001")
        assert bal["available_balance"] == 8000.0
        assert bal["held_balance"] == 42000.0
        assert bal["total_balance"] == 50000.0

    def test_can_spend_check(self, ledger):
        """Tests the spend guard function."""
        ledger.create_account("acc-001", initial_balance=80000.0)
        ledger.place_quarantine_hold("acc-001", "tx-01", 42000.0)

        assert ledger.can_spend("acc-001", 38000.0) is True
        assert ledger.can_spend("acc-001", 38001.0) is False
        assert ledger.can_spend("acc-001", 50000.0) is False


class TestHoldRelease:
    """Tests quarantine hold release and confiscation."""

    def test_release_restores_available(self, ledger):
        ledger.create_account("acc-001", initial_balance=80000.0)
        hold = ledger.place_quarantine_hold("acc-001", "tx-01", 42000.0)

        ledger.release_quarantine_hold(hold["hold_id"], "Investigation cleared")
        bal = ledger.get_balance("acc-001")
        assert bal["available_balance"] == 80000.0
        assert bal["held_balance"] == 0.0
        assert bal["total_balance"] == 80000.0

    def test_confiscation_removes_from_total(self, ledger):
        ledger.create_account("acc-001", initial_balance=80000.0)
        hold = ledger.place_quarantine_hold("acc-001", "tx-01", 42000.0)

        ledger.confiscate_quarantine_hold(hold["hold_id"], "Confirmed fraud proceeds")
        bal = ledger.get_balance("acc-001")
        assert bal["available_balance"] == 38000.0
        assert bal["held_balance"] == 0.0
        assert bal["total_balance"] == 38000.0

    def test_double_release_raises_error(self, ledger):
        ledger.create_account("acc-001", initial_balance=80000.0)
        hold = ledger.place_quarantine_hold("acc-001", "tx-01", 42000.0)
        ledger.release_quarantine_hold(hold["hold_id"])

        with pytest.raises(HoldAlreadyResolvedError):
            ledger.release_quarantine_hold(hold["hold_id"])

    def test_invalid_hold_id_raises_error(self, ledger):
        with pytest.raises(HoldNotFoundError):
            ledger.release_quarantine_hold("nonexistent-hold-id")


class TestMultipleHolds:
    """Tests multiple concurrent quarantine holds on the same account."""

    def test_multiple_holds_accumulate(self, ledger):
        ledger.create_account("acc-001", initial_balance=100000.0)
        ledger.place_quarantine_hold("acc-001", "tx-01", 20000.0)
        ledger.place_quarantine_hold("acc-001", "tx-02", 30000.0)

        bal = ledger.get_balance("acc-001")
        assert bal["total_balance"] == 100000.0
        assert bal["available_balance"] == 50000.0
        assert bal["held_balance"] == 50000.0

        active = ledger.get_active_holds("acc-001")
        assert len(active) == 2

    def test_invariant_preserved_across_multiple_operations(self, ledger):
        """Comprehensive invariant test across a sequence of operations."""
        ledger.create_account("acc-001", initial_balance=100000.0)

        # Credit
        ledger.credit("acc-001", 20000.0)  # total = 120000

        # Hold 1
        h1 = ledger.place_quarantine_hold("acc-001", "tx-01", 30000.0)

        # Debit (from available)
        ledger.debit("acc-001", 10000.0)

        # Hold 2
        h2 = ledger.place_quarantine_hold("acc-001", "tx-02", 25000.0)

        # Release hold 1
        ledger.release_quarantine_hold(h1["hold_id"])

        bal = ledger.get_balance("acc-001")
        assert bal["total_balance"] == bal["available_balance"] + bal["held_balance"]
        assert bal["held_balance"] == 25000.0  # only h2 remains


class TestAuditTrail:
    """Tests the append-only audit trail."""

    def test_entries_are_recorded(self, ledger):
        ledger.create_account("acc-001", initial_balance=50000.0)
        ledger.credit("acc-001", 10000.0)
        ledger.place_quarantine_hold("acc-001", "tx-01", 20000.0)

        # opening + credit + hold = 3 entries
        assert len(ledger.entries) >= 3
        entry_types = [e["entry_type"] for e in ledger.entries]
        assert "CREDIT" in entry_types
        assert "HOLD_PLACED" in entry_types

    def test_entries_have_timestamps(self, ledger):
        ledger.create_account("acc-001", initial_balance=50000.0)
        for entry in ledger.entries:
            assert "timestamp" in entry
            assert "entry_id" in entry
