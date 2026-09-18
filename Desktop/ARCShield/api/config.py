"""
ARCShield API Configuration
Centralizes environment variable loading, Supabase client initialization,
and Firebase Admin SDK setup.
"""

import os
from dotenv import load_dotenv

load_dotenv()

# ─── Supabase Configuration ─────────────────────────────────────────────────
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
SUPABASE_JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET", "")
DATABASE_URL = os.getenv("DATABASE_URL", "")

# Frontend-exposed vars (for Vite dashboard)
VITE_SUPABASE_URL = os.getenv("VITE_SUPABASE_URL", SUPABASE_URL)
VITE_SUPABASE_ANON_KEY = os.getenv("VITE_SUPABASE_ANON_KEY", SUPABASE_ANON_KEY)

# ─── Firebase Configuration ──────────────────────────────────────────────────
FIREBASE_SERVICE_ACCOUNT_PATH = os.getenv(
    "FIREBASE_SERVICE_ACCOUNT_PATH",
    os.path.join(os.path.dirname(os.path.dirname(__file__)), "config", "firebase-service-account.json")
)

# ─── API Configuration ───────────────────────────────────────────────────────
API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", "8000"))
API_DEBUG = os.getenv("API_DEBUG", "false").lower() == "true"
CORS_ORIGINS = [
    origin.strip()
    for origin in os.getenv(
        "CORS_ORIGINS",
        "http://localhost:3000,http://localhost:5173",
    ).split(",")
    if origin.strip()
]

# ─── Quarantine Defaults ─────────────────────────────────────────────────────
QUARANTINE_HOLD_DURATION_HOURS = int(os.getenv("QUARANTINE_HOLD_HOURS", "24"))
QUARANTINE_AUTO_RELEASE = os.getenv("QUARANTINE_AUTO_RELEASE", "true").lower() == "true"

# ─── Risk Thresholds ─────────────────────────────────────────────────────────
RISK_THRESHOLD_MEDIUM = float(os.getenv("RISK_THRESHOLD_MEDIUM", "0.35"))
RISK_THRESHOLD_HIGH = float(os.getenv("RISK_THRESHOLD_HIGH", "0.70"))

# ─── Supabase Client Initialization ──────────────────────────────────────────
_supabase_client = None


def get_supabase_client():
    """
    Lazy-initialized Supabase client using the service role key
    for backend operations (bypasses RLS).
    """
    global _supabase_client
    if _supabase_client is None:
        try:
            from supabase import create_client
            _supabase_client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
        except ImportError:
            print("[WARN] supabase-py not installed. Using in-memory fallback.")
            _supabase_client = None
        except Exception as e:
            print(f"[WARN] Supabase client init failed: {e}. Using in-memory fallback.")
            _supabase_client = None
    return _supabase_client


# ─── Firebase Admin SDK Initialization ────────────────────────────────────────
_firebase_app = None


def get_firebase_app():
    """
    Lazy-initialized Firebase Admin SDK app using the service account JSON.
    """
    global _firebase_app
    if _firebase_app is None:
        try:
            import firebase_admin
            from firebase_admin import credentials
            if os.path.exists(FIREBASE_SERVICE_ACCOUNT_PATH):
                cred = credentials.Certificate(FIREBASE_SERVICE_ACCOUNT_PATH)
                _firebase_app = firebase_admin.initialize_app(cred)
            else:
                print(f"[WARN] Firebase service account not found at: {FIREBASE_SERVICE_ACCOUNT_PATH}")
        except ImportError:
            print("[WARN] firebase-admin not installed. Push notifications disabled.")
        except ValueError:
            # App already initialized
            _firebase_app = firebase_admin.get_app()
        except Exception as e:
            print(f"[WARN] Firebase init failed: {e}")
    return _firebase_app


def print_config_status():
    """Diagnostic helper to verify configuration on startup."""
    checks = {
        "Supabase URL": bool(SUPABASE_URL),
        "Supabase Anon Key": bool(SUPABASE_ANON_KEY),
        "Supabase Service Role Key": bool(SUPABASE_SERVICE_ROLE_KEY),
        "Database URL": bool(DATABASE_URL) and "your-project-id" not in DATABASE_URL,
        "Firebase Service Account": os.path.exists(FIREBASE_SERVICE_ACCOUNT_PATH),
    }
    print("\n╔══════════════════════════════════════════════════════╗")
    print("║         ARCShield Configuration Status              ║")
    print("╠══════════════════════════════════════════════════════╣")
    for name, ok in checks.items():
        status = "✅" if ok else "⚠️  MISSING"
        print(f"║  {name:<35} {status:<15} ║")
    print("╚══════════════════════════════════════════════════════╝\n")
