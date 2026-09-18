from dataclasses import dataclass, field
from typing import List, Dict, Tuple

@dataclass
class AccountArchetype:
    name: str
    monthly_inflow_range: Tuple[float, float]
    typical_transaction_range: Tuple[float, float]
    active_hours: List[int]
    top_merchant_categories: List[str]
    inflow_frequency_days: int # e.g. 30 for salaried, 1 for merchant
    expected_counterparty_count_per_month: int

    @property
    def avg_monthly_income(self) -> float:
        return (self.monthly_inflow_range[0] + self.monthly_inflow_range[1]) / 2.0

    def __getitem__(self, key: str):
        if key == "avg_monthly_income":
            return self.avg_monthly_income
        return getattr(self, key)

    def __contains__(self, key: str):
        return hasattr(self, key) or key == "avg_monthly_income"

ARCHETYPES: Dict[str, AccountArchetype] = {
    "salaried": AccountArchetype(
        name="salaried",
        monthly_inflow_range=(45000.0, 150000.0),
        typical_transaction_range=(200.0, 4500.0),
        active_hours=list(range(8, 23)),
        top_merchant_categories=["GROCERY", "FOOD_DINING", "UTILITIES", "TRANSPORT"],
        inflow_frequency_days=30,
        expected_counterparty_count_per_month=15,
    ),
    "student": AccountArchetype(
        name="student",
        monthly_inflow_range=(5000.0, 20000.0),
        typical_transaction_range=(50.0, 800.0),
        active_hours=list(range(10, 24)) + [0, 1],
        top_merchant_categories=["CANTEEN", "ENTERTAINMENT", "BOOKSTORE", "FOOD_DELIVERY"],
        inflow_frequency_days=15,
        expected_counterparty_count_per_month=8,
    ),
    "merchant": AccountArchetype(
        name="merchant",
        monthly_inflow_range=(150000.0, 800000.0),
        typical_transaction_range=(500.0, 25000.0),
        active_hours=list(range(7, 22)),
        top_merchant_categories=["WHOLESALE", "LOGISTICS", "COMMERCIAL_UTILITIES"],
        inflow_frequency_days=1,
        expected_counterparty_count_per_month=120,
    ),
    "retiree": AccountArchetype(
        name="retiree",
        monthly_inflow_range=(25000.0, 60000.0),
        typical_transaction_range=(100.0, 2000.0),
        active_hours=list(range(9, 19)),
        top_merchant_categories=["PHARMACY", "GROCERY", "HEALTHCARE"],
        inflow_frequency_days=30,
        expected_counterparty_count_per_month=6,
    ),
    "gig_worker": AccountArchetype(
        name="gig_worker",
        monthly_inflow_range=(20000.0, 45000.0),
        typical_transaction_range=(100.0, 1500.0),
        active_hours=list(range(6, 24)),
        top_merchant_categories=["FUEL", "AUTO_REPAIR", "FAST_FOOD", "MOBILE_RECHARGE"],
        inflow_frequency_days=7,
        expected_counterparty_count_per_month=25,
    ),
}
