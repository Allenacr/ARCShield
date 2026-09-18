import os
import json
import logging
import requests
from dotenv import load_dotenv
from typing import List, Dict, Any, Optional

load_dotenv()

logger = logging.getLogger("arcshield.notifications")


def broadcast_supabase_realtime(
    event_type: str,
    title: str,
    body: str,
    transaction_id: str,
    risk_band: str,
    direction: str,
    reason_codes: List[str],
    amount: Optional[float] = None,
) -> bool:
    """
    Broadcasts an event to Supabase Realtime channel 'fraud_alerts' so that
    both the React web console and Flutter mobile app receive it instantly.
    Uses the REST /realtime/v1/api/broadcast endpoint.
    """
    supabase_url = os.getenv("SUPABASE_URL", "")
    service_role_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")

    if not supabase_url or not service_role_key:
        logger.warning("Supabase credentials not set. Skipping Realtime broadcast.")
        return False

    broadcast_url = f"{supabase_url.rstrip('/')}/realtime/v1/api/broadcast/fraud_alerts/events/{event_type}"


    alert_payload = {
        "transaction_id": transaction_id,
        "title": title,
        "body": body,
        "risk_band": risk_band,
        "direction": direction,
        "reason_codes": ",".join(reason_codes),
        "amount": str(amount) if amount is not None else "0",
    }

    headers = {
        "Content-Type": "application/json",
        "apikey": service_role_key,
        "Authorization": f"Bearer {service_role_key}",
    }

    try:
        response = requests.post(
            broadcast_url, json=alert_payload, headers=headers, timeout=5
        )
        if response.status_code in (200, 201, 202):
            logger.info(
                "[SUPABASE REALTIME BROADCAST SENT] channel=fraud_alerts event=incoming_alert tx=%s",
                transaction_id,
            )
            return True
        else:
            logger.warning(
                "Supabase Realtime broadcast returned %s: %s",
                response.status_code,
                response.text,
            )
            return False
    except Exception as e:
        logger.error("Supabase Realtime broadcast failed: %s", e)
        return False


class PushNotificationService:
    """
    Push notification service handling:
      1. Supabase Realtime WebSocket broadcast (primary — works without FCM)
      2. Firebase Cloud Messaging (FCM) — secondary, requires google-services.json
    Includes automatic fallback/simulation mode when neither is configured.
    """

    def __init__(self, service_account_path: Optional[str] = None):
        self.service_account_path = service_account_path or os.getenv(
            "FIREBASE_SERVICE_ACCOUNT_PATH", "config/firebase-service-account.json"
        )
        self.firebase_app = None
        self._initialize_firebase()

    def _initialize_firebase(self):
        try:
            if os.path.exists(self.service_account_path):
                import firebase_admin
                from firebase_admin import credentials

                cred = credentials.Certificate(self.service_account_path)
                self.firebase_app = firebase_admin.initialize_app(cred)
                logger.info(
                    "Firebase Admin SDK successfully initialized from %s",
                    self.service_account_path,
                )
            else:
                logger.warning(
                    "Firebase service account file not found at '%s'. "
                    "Primary alert channel: Supabase Realtime WebSocket.",
                    self.service_account_path,
                )
        except Exception as e:
            logger.warning(
                "Could not initialize Firebase Admin SDK: %s. "
                "Primary alert channel: Supabase Realtime WebSocket.",
                e,
            )
            self.firebase_app = None

    def send_fraud_alert(
        self,
        fcm_token: Optional[str],
        title: str,
        body: str,
        transaction_id: str,
        risk_band: str,
        direction: str,
        reason_codes: List[str],
        amount: Optional[float] = None,
    ) -> Dict[str, Any]:
        """
        Dispatches high-priority alert via:
          1. Supabase Realtime broadcast (instant WebSocket delivery to phone)
          2. FCM push (if Firebase is configured)
        Target SLA: < 3 seconds end-to-end.
        """
        results: Dict[str, Any] = {}

        # ── Primary: Supabase Realtime broadcast (no FCM needed) ──────────────
        realtime_ok = broadcast_supabase_realtime(
            event_type="incoming_alert",
            title=title,
            body=body,
            transaction_id=transaction_id,
            risk_band=risk_band,
            direction=direction,
            reason_codes=reason_codes,
            amount=amount,
        )
        results["supabase_realtime"] = "SENT" if realtime_ok else "FAILED"

        # ── Secondary: Firebase FCM (if service-account.json present) ─────────
        fcm_payload = {
            "transaction_id": transaction_id,
            "risk_band": risk_band,
            "direction": direction,
            "reason_codes": ",".join(reason_codes),
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
        }

        if self.firebase_app and fcm_token:
            try:
                from firebase_admin import messaging

                message = messaging.Message(
                    notification=messaging.Notification(title=title, body=body),
                    data=fcm_payload,
                    android=messaging.AndroidConfig(
                        priority="high",
                        notification=messaging.AndroidNotification(
                            channel_id="arcshield_high_risk_alerts",
                            sound="default",
                            color="#DC2626",
                        ),
                    ),
                    token=fcm_token,
                )
                response = messaging.send(message)
                logger.info("Push alert delivered via FCM: %s", response)
                results["fcm"] = {"status": "DELIVERED", "fcm_message_id": response}
            except Exception as e:
                logger.error("Failed delivering FCM push: %s.", e)
                results["fcm"] = {"status": "FAILED", "error": str(e)}
        else:
            results["fcm"] = {"status": "SKIPPED", "reason": "No firebase app or token"}

        # ── Fallback log if both fail ──────────────────────────────────────────
        if not realtime_ok and results["fcm"].get("status") not in ("DELIVERED",):
            logger.info(
                "\n" + "=" * 70 + "\n"
                "🚨 [SIMULATED — BOTH CHANNELS UNAVAILABLE]\n"
                f"Title: {title}\n"
                f"Body:  {body}\n"
                f"Data:  {json.dumps(fcm_payload, indent=2)}\n"
                + "=" * 70
            )
            results["status"] = "SIMULATED"
        else:
            results["status"] = "DISPATCHED"

        return results


# Global singleton instance
notification_service = PushNotificationService()
