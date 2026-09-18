-- ============================================================================
-- ARCShield: Row-Level Security (RLS) Policies
-- ============================================================================

-- Enable RLS across sensitive tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quarantine_holds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- 1. Users table policies
DROP POLICY IF EXISTS "Users can read own profile" ON public.users;
CREATE POLICY "Users can read own profile"
ON public.users FOR SELECT
USING (auth.uid() = id);

-- 2. Accounts table policies
DROP POLICY IF EXISTS "Account holders can read own accounts" ON public.accounts;
CREATE POLICY "Account holders can read own accounts"
ON public.accounts FOR SELECT
USING (auth.uid() = user_id);

-- 3. Transactions table policies
DROP POLICY IF EXISTS "Account holders see transactions on their accounts" ON public.transactions;
CREATE POLICY "Account holders see transactions on their accounts"
ON public.transactions FOR SELECT
USING (
    sender_account_id IN (SELECT id FROM public.accounts WHERE user_id = auth.uid()) OR
    receiver_account_id IN (SELECT id FROM public.accounts WHERE user_id = auth.uid())
);

-- 4. Alerts table policies
DROP POLICY IF EXISTS "Account holders see own alerts" ON public.alerts;
CREATE POLICY "Account holders see own alerts"
ON public.alerts FOR SELECT
USING (
    account_id IN (SELECT id FROM public.accounts WHERE user_id = auth.uid())
);

DROP POLICY IF EXISTS "Staff see all alerts" ON public.alerts;
CREATE POLICY "Staff see all alerts"
ON public.alerts FOR SELECT
TO authenticated
USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('ANALYST', 'ADMIN'))
);

-- 5. Cases table policies
DROP POLICY IF EXISTS "Staff can view and manage cases" ON public.cases;
CREATE POLICY "Staff can view and manage cases"
ON public.cases FOR ALL
TO authenticated
USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('ANALYST', 'ADMIN'))
);

-- 6. Audit Logs: Append-only insert, read-only for analysts/admins
DROP POLICY IF EXISTS "Allow append to audit logs" ON public.audit_logs;
CREATE POLICY "Allow append to audit logs"
ON public.audit_logs FOR INSERT
WITH CHECK (true);

DROP POLICY IF EXISTS "Staff view audit logs" ON public.audit_logs;
CREATE POLICY "Staff view audit logs"
ON public.audit_logs FOR SELECT
TO authenticated
USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('ANALYST', 'ADMIN'))
);
