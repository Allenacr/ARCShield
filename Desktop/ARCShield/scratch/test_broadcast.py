import os
import requests
from dotenv import load_dotenv

load_dotenv()
supabase_url = os.getenv("SUPABASE_URL")
service_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
anon_key = os.getenv("SUPABASE_ANON_KEY")

url = f"{supabase_url}/realtime/v1/api/broadcast"
headers = {
    "apikey": anon_key,
    "Authorization": f"Bearer {service_key}",
    "Content-Type": "application/json",
}
payload = {
    "messages": [
        {
            "topic": "fraud_alerts",
            "event": "incoming_alert",
            "payload": {
                "transaction_id": "tx-backend-test",
                "counterparty": "stranger.mule@upi",
                "amount": "42000.0",
                "direction": "INCOMING",
                "risk_band": "HIGH",
                "reason_codes": "UNKNOWN_SENDER,COMPLAINT_PROXIMITY_2_HOPS,HIGH_PASS_THROUGH_RISK",
            },
        }
    ]
}

r = requests.post(url, headers=headers, json=payload)
print("Status:", r.status_code)
print("Response:", r.text)
