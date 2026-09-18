import json
from generator.world import SyntheticWorldGenerator

def generate_seed_sql(output_path: str = "db/seed_data.sql"):
    """
    Generates SQL INSERT statements from the Synthetic World Generator
    for seeding Supabase database directly via SQL Editor or psql.
    """
    gen = SyntheticWorldGenerator(seed=42)
    world = gen.generate_world(population_size=10, days_of_history=15)

    sql_statements = [
        "-- ============================================================================",
        "-- ARCShield Deterministic Seed Data (Generated from Synthetic World)",
        "-- ============================================================================\n",
        "BEGIN;\n",
    ]

    # 1. Users & Accounts
    for u in world["users"]:
        sql_statements.append(
            f"INSERT INTO public.users (id, email, full_name, phone_number, role, archetype) "
            f"VALUES ('{u['id']}', '{u['email']}', '{u['full_name']}', '{u['phone_number']}', '{u['role']}', '{u['archetype']}') "
            f"ON CONFLICT (id) DO NOTHING;"
        )

    for a in world["accounts"]:
        sql_statements.append(
            f"INSERT INTO public.accounts (id, user_id, account_number, upi_id, bank_code, total_balance, held_balance) "
            f"VALUES ('{a['id']}', '{a['user_id']}', '{a['account_number']}', '{a['upi_id']}', '{a['bank_code']}', {a['total_balance']}, {a['held_balance']}) "
            f"ON CONFLICT (id) DO NOTHING;"
        )

    # 2. Devices
    for d in world["devices"]:
        sql_statements.append(
            f"INSERT INTO public.devices (id, device_fingerprint, os, app_version, device_model) "
            f"VALUES ('{d['id']}', '{d['device_fingerprint']}', '{d['os']}', '{d['app_version']}', '{d['device_model']}') "
            f"ON CONFLICT (id) DO NOTHING;"
        )

    # 3. Complaints for Scenario 5
    sql_statements.append(
        "INSERT INTO public.complaints (complaint_number, victim_name, reported_identifier, reported_entity_type, loss_amount, crime_category) "
        "VALUES ('FIR-2026-9082', 'Sunita Rao', 'mule-bridge-01@axis', 'UPI_ID', 150000.00, 'CYBER_IMPERSONATION_FRAUD') "
        "ON CONFLICT (complaint_number) DO NOTHING;"
    )

    sql_statements.append("\nCOMMIT;")

    full_sql = "\n".join(sql_statements)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(full_sql)

    print(f"Seed SQL script written to '{output_path}' with {len(world['users'])} users, {len(world['accounts'])} accounts.")
    return output_path

if __name__ == "__main__":
    generate_seed_sql()
