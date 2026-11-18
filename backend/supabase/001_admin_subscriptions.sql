-- ==============================================================================
-- Migration: 001_admin_subscriptions.sql
-- Description: Schema and Row-Level Security (RLS) for Admin-Provisioned Access,
--              Single-Device Enforcement, Subscription Expiry & Cross-Device Excel Sync
-- Target: Supabase Postgres (run in Supabase SQL Editor)
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- TABLE 1: access_requests
-- Stores onboarding access requests submitted by shop owners from mobile app / web.
-- Status transitions: 'pending' -> 'approved' | 'rejected'
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.access_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT NOT NULL,
    business_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    notes TEXT DEFAULT '',
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Index for admin filtering by request status & email
CREATE INDEX IF NOT EXISTS idx_access_requests_status ON public.access_requests (status);
CREATE INDEX IF NOT EXISTS idx_access_requests_email ON public.access_requests (email);

-- Enable RLS on access_requests
ALTER TABLE public.access_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policy: No direct public read/write access.
-- All access is mediated through backend FastAPI endpoints using the service_role key.
-- Any direct requests by anon or authenticated roles are blocked by default RLS deny.

-- ==============================================================================
-- TABLE 2: user_subscriptions
-- 1-to-1 subscription and single-device session tracking tied to auth.users.
-- Cascades on user deletion (in-app deletion or admin deletion).
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL DEFAULT '',
    business_name TEXT NOT NULL DEFAULT '',
    phone TEXT NOT NULL DEFAULT '',
    amount_paid_inr NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    payment_notes TEXT DEFAULT '',
    subscription_start DATE NOT NULL DEFAULT CURRENT_DATE,
    subscription_end DATE NOT NULL DEFAULT (CURRENT_DATE + INTERVAL '30 days'),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'blocked', 'cancelled')),
    active_session_id UUID NULL,
    active_device_label TEXT NULL,
    session_updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Indexes for status lookups, date validity, and active session verification
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON public.user_subscriptions (status);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_dates ON public.user_subscriptions (subscription_start, subscription_end);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_session ON public.user_subscriptions (active_session_id);

-- Enable RLS on user_subscriptions
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Authenticated users can only read their own subscription status
CREATE POLICY "Users can view own subscription"
    ON public.user_subscriptions
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Note: All writes (INSERT, UPDATE, DELETE) go strictly through FastAPI service_role,
-- which bypasses RLS automatically. Direct user mutations are prevented.

-- ==============================================================================
-- TABLE 3: user_draft_sheets
-- Syncs user draft Excel workbooks across devices.
-- Keyed uniquely per (user_id, sheet_id).
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.user_draft_sheets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    sheet_id TEXT NOT NULL,
    sheet_name TEXT NOT NULL,
    rows_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_user_draft_sheets_user_sheet UNIQUE (user_id, sheet_id)
);

-- Index for fast user sheet retrieval
CREATE INDEX IF NOT EXISTS idx_user_draft_sheets_user_id ON public.user_draft_sheets (user_id);

-- Enable RLS on user_draft_sheets
ALTER TABLE public.user_draft_sheets ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Authenticated users can SELECT / INSERT / UPDATE / DELETE their own draft sheets
CREATE POLICY "Users can select own draft sheets"
    ON public.user_draft_sheets
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own draft sheets"
    ON public.user_draft_sheets
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own draft sheets"
    ON public.user_draft_sheets
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own draft sheets"
    ON public.user_draft_sheets
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- ==============================================================================
-- TABLE 4: deletion_requests
-- Persists external web account deletion requests for Play Store Data Safety compliance.
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.deletion_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    phone TEXT DEFAULT '',
    reason TEXT DEFAULT '',
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'rejected')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_deletion_requests_email ON public.deletion_requests (email);
ALTER TABLE public.deletion_requests ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- UPDATED_AT TRIGGER FUNCTION
-- Automatically sets updated_at = now() on row updates.
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
DROP TRIGGER IF EXISTS tr_user_subscriptions_updated_at ON public.user_subscriptions;
CREATE TRIGGER tr_user_subscriptions_updated_at
    BEFORE UPDATE ON public.user_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS tr_user_draft_sheets_updated_at ON public.user_draft_sheets;
CREATE TRIGGER tr_user_draft_sheets_updated_at
    BEFORE UPDATE ON public.user_draft_sheets
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
