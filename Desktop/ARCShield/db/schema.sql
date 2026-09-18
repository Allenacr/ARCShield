-- ============================================================================
-- ARCShield: Bidirectional Transaction Guard
-- Complete Database Schema (PostgreSQL / Supabase)
-- ============================================================================

-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Custom Enumerations
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('ACCOUNT_HOLDER', 'ANALYST', 'ADMIN');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE transaction_direction AS ENUM ('INCOMING', 'OUTGOING');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE transaction_status AS ENUM ('PENDING', 'COMPLETED', 'HELD', 'REJECTED', 'CANCELLED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE risk_band_enum AS ENUM ('LOW', 'MEDIUM', 'HIGH');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE case_status_enum AS ENUM ('OPEN', 'IN_INVESTIGATION', 'RESOLVED_FRAUD', 'RESOLVED_LEGITIMATE', 'CLOSED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE hold_status_enum AS ENUM ('ACTIVE', 'RELEASED_USER', 'RELEASED_EXPIRED', 'CONFIRMED_FRAUD');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. Users Profile Table (links with Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone_number TEXT,
    role user_role DEFAULT 'ACCOUNT_HOLDER',
    archetype TEXT DEFAULT 'salaried', -- 'salaried', 'student', 'merchant', 'retiree', 'gig_worker'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Accounts Table with Ledger Invariant:
--    available_balance = total_balance - held_balance
CREATE TABLE IF NOT EXISTS public.accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    account_number TEXT UNIQUE NOT NULL,
    upi_id TEXT UNIQUE,
    bank_code TEXT DEFAULT 'BANK_A',
    total_balance NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    held_balance NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    available_balance NUMERIC(15, 2) GENERATED ALWAYS AS (total_balance - held_balance) STORED,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Devices & Sessions
CREATE TABLE IF NOT EXISTS public.devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_fingerprint TEXT UNIQUE NOT NULL,
    os TEXT,
    app_version TEXT,
    device_model TEXT,
    network_id TEXT,
    is_flagged BOOLEAN DEFAULT FALSE,
    first_seen TIMESTAMPTZ DEFAULT NOW(),
    last_seen TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID NOT NULL REFERENCES public.accounts(id),
    device_id UUID REFERENCES public.devices(id),
    typing_speed_wpm NUMERIC(5, 2),
    tap_interval_variance NUMERIC(6, 4),
    session_anomaly_score NUMERIC(5, 4) DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Beneficiaries & Trust Ladder
CREATE TABLE IF NOT EXISTS public.beneficiaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID NOT NULL REFERENCES public.accounts(id),
    counterparty_identifier TEXT NOT NULL,
    counterparty_name TEXT NOT NULL,
    trust_level INT DEFAULT 1, -- 1: Untrusted/New, 2: Test Passed (₹1), 3: Verified
    relationship_age_days INT DEFAULT 0,
    total_successful_transfers INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Account Events (First-class sequence records for F-02)
CREATE TABLE IF NOT EXISTS public.account_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID NOT NULL REFERENCES public.accounts(id),
    event_type TEXT NOT NULL, -- 'LOGIN', 'LOGIN_NEW_DEVICE', 'PASSWORD_CHANGE', 'PROFILE_CHANGE', 'BENEFICIARY_ADDED', 'FAILED_AUTH', 'TRANSACTION'
    device_id UUID REFERENCES public.devices(id),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Transactions
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_account_id UUID REFERENCES public.accounts(id),
    receiver_account_id UUID REFERENCES public.accounts(id),
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    direction transaction_direction NOT NULL,
    status transaction_status DEFAULT 'PENDING',
    channel TEXT DEFAULT 'UPI',
    counterparty_identifier TEXT,
    reference_note TEXT,
    device_id UUID REFERENCES public.devices(id),
    session_id UUID REFERENCES public.sessions(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Double-Entry Ledger
CREATE TABLE IF NOT EXISTS public.ledger_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID NOT NULL REFERENCES public.accounts(id),
    transaction_id UUID NOT NULL REFERENCES public.transactions(id),
    entry_type TEXT NOT NULL CHECK (entry_type IN ('CREDIT', 'DEBIT')),
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    balance_after NUMERIC(15, 2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Quarantine Holds (The Core Product Innovation)
CREATE TABLE IF NOT EXISTS public.quarantine_holds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID NOT NULL REFERENCES public.accounts(id),
    transaction_id UUID NOT NULL REFERENCES public.transactions(id),
    held_amount NUMERIC(15, 2) NOT NULL CHECK (held_amount > 0),
    status hold_status_enum DEFAULT 'ACTIVE',
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours'),
    released_at TIMESTAMPTZ,
    release_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. Risk Scores & Explainable Reasons
CREATE TABLE IF NOT EXISTS public.risk_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID UNIQUE NOT NULL REFERENCES public.transactions(id),
    risk_score INT NOT NULL CHECK (risk_score BETWEEN 0 AND 100),
    risk_band risk_band_enum NOT NULL,
    recommended_action TEXT NOT NULL, -- 'ALLOW', 'CHALLENGE', 'QUARANTINE'
    model_version TEXT NOT NULL,
    shap_top JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.risk_reasons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    risk_score_id UUID NOT NULL REFERENCES public.risk_scores(id) ON DELETE CASCADE,
    ordinal INT NOT NULL,
    reason_code TEXT NOT NULL,
    severity TEXT NOT NULL -- 'CRITICAL', 'HIGH', 'MEDIUM', 'INFO'
);

-- 12. Realtime Alerts
CREATE TABLE IF NOT EXISTS public.alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID NOT NULL REFERENCES public.accounts(id),
    transaction_id UUID NOT NULL REFERENCES public.transactions(id),
    risk_band risk_band_enum NOT NULL,
    status TEXT DEFAULT 'UNREAD',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. Complaints & Flagged Entities (for Complaint Proximity F-11)
CREATE TABLE IF NOT EXISTS public.complaints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    complaint_number TEXT UNIQUE NOT NULL,
    victim_name TEXT,
    reported_identifier TEXT NOT NULL,
    reported_entity_type TEXT NOT NULL, -- 'UPI_ID', 'ACCOUNT', 'DEVICE', 'PHONE'
    loss_amount NUMERIC(15, 2),
    crime_category TEXT,
    reported_at TIMESTAMPTZ DEFAULT NOW()
);

-- 14. Cases & Evidence Snapshots
CREATE TABLE IF NOT EXISTS public.cases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_number TEXT UNIQUE NOT NULL DEFAULT ('CASE-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || SUBSTRING(uuid_generate_v4()::text, 1, 6)),
    transaction_id UUID REFERENCES public.transactions(id),
    account_id UUID NOT NULL REFERENCES public.accounts(id),
    assigned_analyst_id UUID REFERENCES public.users(id),
    status case_status_enum DEFAULT 'OPEN',
    evidence_trail JSONB NOT NULL DEFAULT '{}'::jsonb,
    subgraph_snapshot JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 15. Append-Only Audit Logs
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    action TEXT NOT NULL,
    actor_id UUID REFERENCES public.users(id),
    account_id UUID REFERENCES public.accounts(id),
    transaction_id UUID REFERENCES public.transactions(id),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 16. Cross-Bank Salted Intelligence (FC-01 Bridge)
CREATE TABLE IF NOT EXISTS public.bank_intelligence (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bank_code TEXT NOT NULL,
    hashed_identifier TEXT NOT NULL, -- SHA-256(salt || identifier)
    risk_indicator TEXT NOT NULL, -- 'HIGH_RISK_MULE', 'SUSPECT_DEVICE', 'BURST_RECEIVER'
    observed_at TIMESTAMPTZ DEFAULT NOW()
);
