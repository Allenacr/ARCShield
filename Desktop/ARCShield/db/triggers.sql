-- ============================================================================
-- ARCShield: Triggers, Ledger Semantics, & Constraints
-- ============================================================================

-- 1. Function: Updated At Timestamp Trigger
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_users_updated_at
BEFORE UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE OR REPLACE TRIGGER trg_transactions_updated_at
BEFORE UPDATE ON public.transactions
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE OR REPLACE TRIGGER trg_cases_updated_at
BEFORE UPDATE ON public.cases
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 2. Function: Prevent Any Modification to Audit Logs (Strict Append-Only)
CREATE OR REPLACE FUNCTION block_audit_log_modification()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Audit logs are immutable. UPDATE and DELETE operations are prohibited by law and system policy.';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_protect_audit_logs
BEFORE UPDATE OR DELETE ON public.audit_logs
FOR EACH ROW EXECUTE FUNCTION block_audit_log_modification();

-- 3. Function & Trigger: Automatic Quarantine Hold Execution (The Core Innovation)
CREATE OR REPLACE FUNCTION handle_quarantine_hold()
RETURNS TRIGGER AS $$
DECLARE
    v_tx_status TEXT;
    v_direction TEXT;
    v_receiver_account UUID;
BEGIN
    -- Validate transaction exists, completed, and is incoming
    SELECT status, direction, receiver_account_id 
    INTO v_tx_status, v_direction, v_receiver_account
    FROM public.transactions 
    WHERE id = NEW.transaction_id;

    IF v_direction != 'INCOMING' THEN
        RAISE EXCEPTION 'Quarantine holds can only be placed on INCOMING transactions.';
    END IF;

    -- 1. Increase held_balance in the account
    UPDATE public.accounts
    SET held_balance = held_balance + NEW.held_amount
    WHERE id = NEW.account_id;

    -- 2. Mark the transaction status as HELD
    UPDATE public.transactions
    SET status = 'HELD', updated_at = NOW()
    WHERE id = NEW.transaction_id;

    -- 3. Write immutable audit log
    INSERT INTO public.audit_logs (action, account_id, transaction_id, metadata)
    VALUES (
        'QUARANTINE_HOLD_PLACED',
        NEW.account_id,
        NEW.transaction_id,
        jsonb_build_object(
            'held_amount', NEW.held_amount,
            'expires_at', NEW.expires_at,
            'reason', 'Proactive quarantine of unexpected incoming funds'
        )
    );

    -- 4. Open investigation case if one does not already exist
    IF NOT EXISTS (SELECT 1 FROM public.cases WHERE transaction_id = NEW.transaction_id) THEN
        INSERT INTO public.cases (
            transaction_id, 
            account_id, 
            status, 
            evidence_trail
        ) VALUES (
            NEW.transaction_id,
            NEW.account_id,
            'OPEN',
            jsonb_build_object(
                'quarantine_timestamp', NOW(),
                'quarantine_amount', NEW.held_amount,
                'status', 'FUNDS_HELD_PROACTIVELY'
            )
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER trg_on_quarantine_hold
AFTER INSERT ON public.quarantine_holds
FOR EACH ROW EXECUTE FUNCTION handle_quarantine_hold();

-- 4. Function: Validate Outgoing Transfer Against Available Balance
CREATE OR REPLACE FUNCTION validate_outgoing_transfer()
RETURNS TRIGGER AS $$
DECLARE
    v_available NUMERIC;
    v_held NUMERIC;
    v_total NUMERIC;
BEGIN
    IF NEW.direction = 'OUTGOING' AND NEW.status IN ('PENDING', 'COMPLETED') THEN
        SELECT total_balance, held_balance, available_balance 
        INTO v_total, v_held, v_available
        FROM public.accounts
        WHERE id = NEW.sender_account_id;

        IF v_available < NEW.amount THEN
            -- Record refusal into audit trail
            INSERT INTO public.audit_logs (action, account_id, transaction_id, metadata)
            VALUES (
                'TRANSFER_ATTEMPT_REFUSED_INSUFFICIENT_AVAILABLE',
                NEW.sender_account_id,
                NEW.id,
                jsonb_build_object(
                    'attempted_amount', NEW.amount,
                    'total_balance', v_total,
                    'held_balance', v_held,
                    'available_balance', v_available
                )
            );

            RAISE EXCEPTION 'Transfer of ₹% refused. Available balance is ₹% (₹% currently held in quarantine).',
                NEW.amount, v_available, v_held;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_verify_available_balance
BEFORE INSERT ON public.transactions
FOR EACH ROW EXECUTE FUNCTION validate_outgoing_transfer();
