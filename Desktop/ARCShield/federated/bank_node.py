import hashlib
from typing import Dict, Any, List, Optional
from datetime import datetime, timezone

SHARED_PEPPER_SALT = "arcshield_interbank_salt_2026"

class VirtualBankNode:
    """
    Virtual Bank Node (F-28, FC-01 bridge).
    Holds private customer accounts, transactions, and devices.
    Never exposes raw PII (names, phone numbers, raw account numbers).
    Exchanges only SHA-256(salt || identifier) alongside coarse risk indicators.
    """
    def __init__(self, bank_code: str, salt: str = SHARED_PEPPER_SALT):
        self.bank_code = bank_code
        self.salt = salt
        self.private_records: List[Dict[str, Any]] = []

    def hash_identifier(self, raw_identifier: str) -> str:
        salted_val = f"{self.salt}:{raw_identifier.strip().lower()}".encode("utf-8")
        return hashlib.sha256(salted_val).hexdigest()

    def record_suspicious_entity(self, raw_identifier: str, indicator: str, loss_amount: float):
        self.private_records.append({
            "raw_identifier": raw_identifier,
            "indicator": indicator,
            "loss_amount": loss_amount,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        })

    def export_hashed_indicators(self) -> List[Dict[str, Any]]:
        """
        Exports privacy-preserving indicators for the inter-bank coordinator.
        Zero customer PII is transmitted.
        """
        exported = []
        for rec in self.private_records:
            exported.append({
                "bank_code": self.bank_code,
                "hashed_identifier": self.hash_identifier(rec["raw_identifier"]),
                "risk_indicator": rec["indicator"],
                "observed_at": rec["timestamp"],
            })
        return exported
