import random
import uuid
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Any, Tuple
from .archetypes import ARCHETYPES, AccountArchetype
from .scenarios import (
    create_scenario_1_quiet,
    create_scenario_2_account_takeover,
    create_scenario_3_manipulated_payment,
    create_scenario_4_structuring,
    create_scenario_5_unexpected_money_closer,
)

try:
    from faker import Faker
    HAS_FAKER = True
except ImportError:
    HAS_FAKER = False

class FallbackFaker:
    FIRST_NAMES = ["Rahul", "Priya", "Amit", "Sneha", "Vikram", "Ananya", "Rohan", "Pooja", "Arjun", "Kavita"]
    LAST_NAMES = ["Sharma", "Verma", "Patel", "Singh", "Gupta", "Mehta", "Iyer", "Nair", "Reddy", "Chopra"]

    def name(self):
        return f"{random.choice(self.FIRST_NAMES)} {random.choice(self.LAST_NAMES)}"

    def bban(self):
        return "".join(str(random.randint(0, 9)) for _ in range(12))

    @staticmethod
    def seed(val):
        random.seed(val)

class SyntheticWorldGenerator:
    """
    Generates a deterministic simulated economy with:
    - User population across 5 financial archetypes
    - Accounts, devices, sessions, and merchants
    - Normal background transactions spanning 30+ days for baseline profiling
    - Explicitly seeded, event-level labeled fraud scenarios
    """
    def __init__(self, seed: int = 42):
        self.seed = seed
        if HAS_FAKER:
            self.fake = Faker("en_IN")
            Faker.seed(seed)
        else:
            self.fake = FallbackFaker()
        random.seed(seed)

    def generate_world(
        self,
        population_size: int = 50,
        days_of_history: int = 30
    ) -> Dict[str, Any]:
        users = []
        accounts = []
        devices = []
        sessions = []
        beneficiaries = []
        transactions = []
        events = []

        archetype_keys = list(ARCHETYPES.keys())

        # 1. Generate Population
        for i in range(population_size):
            u_id = str(uuid.uuid4())
            archetype_name = archetype_keys[i % len(archetype_keys)]
            archetype = ARCHETYPES[archetype_name]
            
            full_name = self.fake.name()
            email = f"{full_name.lower().replace(' ', '.')}_{i}@demo.arcshield.local"
            phone = f"+9198{random.randint(10000000, 99999999)}"

            users.append({
                "id": u_id,
                "email": email,
                "full_name": full_name,
                "phone_number": phone,
                "role": "ACCOUNT_HOLDER",
                "archetype": archetype_name,
            })

            # Account
            acc_id = str(uuid.uuid4())
            initial_balance = round(random.uniform(*archetype.monthly_inflow_range), 2)
            accounts.append({
                "id": acc_id,
                "user_id": u_id,
                "account_number": f"AC{self.fake.bban()[:12]}",
                "upi_id": f"{full_name.lower().replace(' ', '')}@okaxis",
                "bank_code": f"BANK_{chr(65 + (i % 3))}", # Virtual Bank A, B, or C
                "total_balance": initial_balance,
                "held_balance": 0.0,
                "available_balance": initial_balance,
                "is_active": True,
            })

            # Primary Device
            dev_id = str(uuid.uuid4())
            devices.append({
                "id": dev_id,
                "account_id": acc_id,
                "device_fingerprint": f"fp_{uuid.uuid4().hex[:16]}",
                "os": random.choice(["Android 14", "Android 13", "iOS 17.5"]),
                "app_version": "1.4.0",
                "device_model": random.choice(["Samsung Galaxy S23", "Redmi Note 12", "OnePlus 11", "iPhone 15"]),
                "is_flagged": False,
            })

            # Normal Baseline Traffic
            start_time = datetime.now(timezone.utc) - timedelta(days=days_of_history)
            for d in range(days_of_history):
                # 1 to 3 transactions per day
                for _ in range(random.randint(1, 3)):
                    tx_time = start_time + timedelta(days=d, hours=random.choice(archetype.active_hours), minutes=random.randint(0, 59))
                    amt = round(random.uniform(*archetype.typical_transaction_range), 2)
                    category = random.choice(archetype.top_merchant_categories)

                    transactions.append({
                        "id": str(uuid.uuid4()),
                        "sender_account_id": acc_id,
                        "receiver_account_id": None,
                        "amount": amt,
                        "direction": "OUTGOING",
                        "status": "COMPLETED",
                        "channel": "UPI",
                        "counterparty_identifier": f"{category.lower()}_merchant@upi",
                        "created_at": tx_time.isoformat(),
                        "is_fraud": False,
                        "risk_band": "LOW",
                    })

        # 2. Seed Explicit Test Scenarios
        # Scenario 1: Quiet normal payment
        s1_events = create_scenario_1_quiet(accounts[0]["id"], devices[0]["id"])
        events.extend(s1_events)

        # Scenario 2: Account Takeover
        s2_new_dev_id = str(uuid.uuid4())
        s2_events = create_scenario_2_account_takeover(accounts[1]["id"], s2_new_dev_id)
        events.extend(s2_events)

        # Scenario 3: Manipulated payment (Coercion)
        s3_events = create_scenario_3_manipulated_payment(accounts[2]["id"], devices[2]["id"])
        events.extend(s3_events)

        # Scenario 4: Structuring
        s4_events = create_scenario_4_structuring(accounts[3]["id"], devices[3]["id"])
        events.extend(s4_events)

        # Scenario 5: Closer - Unexpected money arrives
        s5_event = create_scenario_5_unexpected_money_closer(accounts[4]["id"])
        events.append(s5_event)

        return {
            "users": users,
            "accounts": accounts,
            "devices": devices,
            "transactions": transactions,
            "events": events,
            "summary": {
                "user_count": len(users),
                "account_count": len(accounts),
                "normal_transaction_count": len(transactions),
                "scenario_event_count": len(events),
            }
        }

    def generate(self, n_users: int = 50, days_of_history: int = 30) -> Dict[str, Any]:
        return self.generate_world(population_size=n_users, days_of_history=days_of_history)

WorldGenerator = SyntheticWorldGenerator

if __name__ == "__main__":
    gen = SyntheticWorldGenerator(seed=42)
    world = gen.generate_world(population_size=10, days_of_history=15)
    print(f"Generated world successfully: {world['summary']}")
