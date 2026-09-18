"""
ARCShield: Double-Entry Ledger Service
Handles atomic balance adjustments, quarantine hold placement/release,
and spend-guard enforcement (available_balance check before outgoing).
"""

from datetime import datetime, timedelta, timezone
from typing import Dict, Any, List, Optional
import uuid


class LedgerService:
    """
    Double-entry ledger implementation for ARCShield.
    
    Core invariant:
        total_balance == available_balance + held_balance
    
    In production, this would execute atomic Supabase/Postgres transactions.
    For the demo, it operates on an in-memory ledger that faithfully 
    implements the same semantics.
    """

    def __init__(self):
        # In-memory account balances: account_id -> {total, available, held}
        self.accounts: Dict[str, Dict[str, float]] = {}
        # Ledger entry log (append-only)
        self.entries: List[Dict[str, Any]] = []
        # Active quarantine holds
        self.holds: List[Dict[str, Any]] = []

    # ─── Account Management ──────────────────────────────────────────────

    def create_account(self, account_id: str, initial_balance: float = 0.0) -> Dict[str, Any]:
        """Creates a new account with the given initial balance."""
        if account_id in self.accounts:
            return self.accounts[account_id]

        self.accounts[account_id] = {
            "account_id": account_id,
            "total_balance": initial_balance,
            "available_balance": initial_balance,
            "held_balance": 0.0,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        # Record opening ledger entry
        self._append_entry(
            account_id=account_id,
            entry_type="CREDIT",
            amount=initial_balance,
            description="Account opening balance",
            reference_id=f"opening-{account_id}",
        )

        return self.accounts[account_id]

    def get_balance(self, account_id: str) -> Optional[Dict[str, float]]:
        """Returns current balance breakdown for an account."""
        return self.accounts.get(account_id)

    # ─── Ledger Operations ───────────────────────────────────────────────

    def credit(self, account_id: str, amount: float, description: str = "",
               reference_id: str = "") -> Dict[str, Any]:
        """Credits (adds) funds to an account's available balance."""
        self._ensure_account(account_id)
        acct = self.accounts[account_id]

        acct["total_balance"] += amount
        acct["available_balance"] += amount

        entry = self._append_entry(
            account_id=account_id,
            entry_type="CREDIT",
            amount=amount,
            description=description,
            reference_id=reference_id,
        )
        self._assert_invariant(account_id)
        return entry

    def debit(self, account_id: str, amount: float, description: str = "",
              reference_id: str = "") -> Dict[str, Any]:
        """
        Debits (removes) funds from an account's available balance.
        Raises InsufficientBalanceError if available_balance < amount.
        """
        self._ensure_account(account_id)
        acct = self.accounts[account_id]

        if acct["available_balance"] < amount:
            raise InsufficientBalanceError(
                f"Insufficient available balance. "
                f"Requested: ₹{amount:,.2f}, "
                f"Available: ₹{acct['available_balance']:,.2f}, "
                f"Held: ₹{acct['held_balance']:,.2f}"
            )

        acct["total_balance"] -= amount
        acct["available_balance"] -= amount

        entry = self._append_entry(
            account_id=account_id,
            entry_type="DEBIT",
            amount=amount,
            description=description,
            reference_id=reference_id,
        )
        self._assert_invariant(account_id)
        return entry

    # ─── Quarantine Hold Operations ──────────────────────────────────────

    def place_quarantine_hold(
        self,
        account_id: str,
        transaction_id: str,
        amount: float,
        reason: str = "Suspicious incoming credit",
        duration_hours: int = 24,
    ) -> Dict[str, Any]:
        """
        F-15 Headline Feature: Places a quarantine hold on incoming funds.
        
        Atomically:
        1. Reduces available_balance by hold amount
        2. Increases held_balance by hold amount
        3. total_balance remains unchanged
        4. Creates hold record with expiry timestamp
        5. Appends immutable ledger entry
        """
        self._ensure_account(account_id)
        acct = self.accounts[account_id]

        if acct["available_balance"] < amount:
            raise InsufficientBalanceError(
                f"Cannot quarantine ₹{amount:,.2f}: only ₹{acct['available_balance']:,.2f} available."
            )

        # Atomic balance adjustment
        acct["available_balance"] -= amount
        acct["held_balance"] += amount

        hold_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc)

        hold = {
            "hold_id": hold_id,
            "transaction_id": transaction_id,
            "account_id": account_id,
            "held_amount": amount,
            "status": "ACTIVE",
            "reason": reason,
            "created_at": now.isoformat(),
            "expires_at": (now + timedelta(hours=duration_hours)).isoformat(),
        }
        self.holds.append(hold)

        self._append_entry(
            account_id=account_id,
            entry_type="HOLD_PLACED",
            amount=amount,
            description=f"Quarantine hold: {reason}",
            reference_id=hold_id,
        )

        self._assert_invariant(account_id)
        return hold

    def release_quarantine_hold(self, hold_id: str, release_reason: str = "Hold expired") -> Dict[str, Any]:
        """
        Releases a quarantine hold, restoring funds to available_balance.
        """
        hold = self._find_hold(hold_id)
        if hold is None:
            raise HoldNotFoundError(f"Hold {hold_id} not found.")
        if hold["status"] != "ACTIVE":
            raise HoldAlreadyResolvedError(f"Hold {hold_id} is already {hold['status']}.")

        acct = self.accounts[hold["account_id"]]
        amount = hold["held_amount"]

        # Reverse the hold
        acct["available_balance"] += amount
        acct["held_balance"] -= amount
        hold["status"] = "RELEASED"

        self._append_entry(
            account_id=hold["account_id"],
            entry_type="HOLD_RELEASED",
            amount=amount,
            description=f"Hold released: {release_reason}",
            reference_id=hold_id,
        )

        self._assert_invariant(hold["account_id"])
        return hold

    def confiscate_quarantine_hold(self, hold_id: str, confiscation_reason: str = "Confirmed fraud") -> Dict[str, Any]:
        """
        Confiscates held funds (e.g., confirmed fraud proceeds).
        Removes from both held_balance and total_balance.
        """
        hold = self._find_hold(hold_id)
        if hold is None:
            raise HoldNotFoundError(f"Hold {hold_id} not found.")
        if hold["status"] != "ACTIVE":
            raise HoldAlreadyResolvedError(f"Hold {hold_id} is already {hold['status']}.")

        acct = self.accounts[hold["account_id"]]
        amount = hold["held_amount"]

        # Remove from both held and total
        acct["held_balance"] -= amount
        acct["total_balance"] -= amount
        hold["status"] = "CONFISCATED"

        self._append_entry(
            account_id=hold["account_id"],
            entry_type="CONFISCATION",
            amount=amount,
            description=f"Funds confiscated: {confiscation_reason}",
            reference_id=hold_id,
        )

        self._assert_invariant(hold["account_id"])
        return hold

    def get_active_holds(self, account_id: str) -> List[Dict[str, Any]]:
        """Returns all active quarantine holds for an account."""
        return [h for h in self.holds if h["account_id"] == account_id and h["status"] == "ACTIVE"]

    # ─── Spend Guard ─────────────────────────────────────────────────────

    def can_spend(self, account_id: str, amount: float) -> bool:
        """
        Checks if account has sufficient available_balance for a transfer.
        Held funds are NOT spendable — this is the core quarantine guarantee.
        """
        acct = self.accounts.get(account_id)
        if acct is None:
            return False
        return acct["available_balance"] >= amount

    # ─── Internal Helpers ────────────────────────────────────────────────

    def _ensure_account(self, account_id: str):
        if account_id not in self.accounts:
            self.create_account(account_id, initial_balance=0.0)

    def _find_hold(self, hold_id: str) -> Optional[Dict[str, Any]]:
        for h in self.holds:
            if h["hold_id"] == hold_id:
                return h
        return None

    def _append_entry(self, account_id: str, entry_type: str, amount: float,
                      description: str, reference_id: str) -> Dict[str, Any]:
        entry = {
            "entry_id": str(uuid.uuid4()),
            "account_id": account_id,
            "entry_type": entry_type,
            "amount": amount,
            "description": description,
            "reference_id": reference_id,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
        self.entries.append(entry)
        return entry

    def _assert_invariant(self, account_id: str):
        """
        Core Invariant: total_balance == available_balance + held_balance
        This MUST hold after every single operation.
        """
        acct = self.accounts[account_id]
        expected = acct["available_balance"] + acct["held_balance"]
        if abs(acct["total_balance"] - expected) > 0.001:
            raise LedgerInvariantViolation(
                f"LEDGER INVARIANT VIOLATION for {account_id}: "
                f"total={acct['total_balance']}, "
                f"available={acct['available_balance']}, "
                f"held={acct['held_balance']}, "
                f"expected_total={expected}"
            )


# ─── Custom Exceptions ───────────────────────────────────────────────────────

class InsufficientBalanceError(Exception):
    """Raised when available_balance is less than the requested amount."""
    pass


class HoldNotFoundError(Exception):
    """Raised when a quarantine hold ID does not exist."""
    pass


class HoldAlreadyResolvedError(Exception):
    """Raised when attempting to modify a hold that is not ACTIVE."""
    pass


class LedgerInvariantViolation(Exception):
    """
    CRITICAL: Raised when total_balance != available_balance + held_balance.
    This should NEVER happen in a correct implementation.
    """
    pass


# Singleton instance
ledger_service = LedgerService()
