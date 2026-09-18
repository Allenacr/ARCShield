"""
ARCShield — Real-Time Backend Alert Trigger
============================================
Run this script to push a live fraud alert from the backend directly
to your phone via Supabase Realtime WebSocket.

The Flutter app must be running and connected to Supabase Realtime for
the alert to appear on-screen. No Firebase required.

Usage:
    python scratch/trigger_alert.py

You can edit the payload below to test different scenarios.
"""

import os
import sys
import json
import requests
from dotenv import load_dotenv

# Load credentials from project .env
env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
load_dotenv(dotenv_path=env_path)

SUPABASE_URL = os.getenv("SUPABASE_URL", "").rstrip("/")
SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")

if not SUPABASE_URL or not SERVICE_ROLE_KEY:
    print("❌  SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set in .env")
    sys.exit(1)

# ─── Edit this payload to test different scenarios ─────────────────────────────
ALERT_PAYLOAD = {
    "transaction_id": "tx-backend-test-001",
    "title": "Unexpected Inflow Alert",
    "body": "Risk Band: HIGH for ₹25,000.00 from unknown-sender@upi",
    "risk_band": "HIGH",
    "direction": "INCOMING",
    "reason_codes": "UNEXPECTED_CREDIT,HIGH_AMOUNT,NEW_COUNTERPARTY",
    "amount": "25000.00",
    "counterparty": "unknown-sender@upi",
}
# ───────────────────────────────────────────────────────────────────────────────

BROADCAST_URL = f"{SUPABASE_URL}/realtime/v1/api/broadcast/fraud_alerts/events/incoming_alert"

headers = {
    "Content-Type": "application/json",
    "apikey": SERVICE_ROLE_KEY,
    "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
}

print("[*] Sending real-time backend alert to phone...")
print(f"   Supabase URL : {SUPABASE_URL}")
print(f"   Channel      : fraud_alerts")
print(f"   Event        : incoming_alert")
print(f"   Payload      :\n{json.dumps(ALERT_PAYLOAD, indent=4)}\n")

try:
    resp = requests.post(BROADCAST_URL, json=ALERT_PAYLOAD, headers=headers, timeout=10)
    if resp.status_code in (200, 201, 202):
        print(f"[OK] Broadcast sent successfully! HTTP {resp.status_code}")
        print("   -> Your phone should display the fraud alert overlay NOW.")
        print("   -> Check Flutter debug console for: [BACKEND REALTIME PUSH RECEIVED ON PHONE]")
    else:
        print(f"[FAIL] Broadcast failed. HTTP {resp.status_code}: {resp.text}")
except requests.exceptions.RequestException as e:
    print(f"[ERROR] Network error: {e}")
