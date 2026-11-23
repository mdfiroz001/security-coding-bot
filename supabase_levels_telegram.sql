-- ============================================================================
-- ARROWFLOW TELEGRAM MINI APP & ADMIN PANEL - COMPLETE SUPABASE SQL SCHEMA
-- Run this entire script in your Supabase Dashboard -> SQL Editor -> New Query
-- ============================================================================

-- 1. APP CONFIGURATION TABLE (Stores Monetag settings, Economy, & Custom Payment Methods)
CREATE TABLE IF NOT EXISTS public.app_config (
  id integer PRIMARY KEY DEFAULT 1,
  maintenance_mode boolean DEFAULT false,
  maintenance_msg text DEFAULT 'We are upgrading ArrowFlow servers. Please check back soon!',
  monetag_enabled boolean DEFAULT true,
  monetag_daily_limit integer DEFAULT 15,
  monetag_ticket_reward integer DEFAULT 3,
  monetag_cooldown_sec integer DEFAULT 5,
  monetag_logo_url text DEFAULT '',
  refer_reward_coins integer DEFAULT 100,
  refer_bot_link text DEFAULT 'https://t.me/Arrowflow_bot/Arrowflowplay',
  farm_rate_per_hour integer DEFAULT 24,
  farm_duration_hours integer DEFAULT 2,
  coins_per_1000_usdt numeric(10, 4) DEFAULT 0.50,
  min_withdraw_usdt numeric(10, 4) DEFAULT 0.50,
  support_link text DEFAULT 'https://t.me/telegram',
  support_info_text text DEFAULT 'Payouts are processed within 24-48 hours. Rewarded ads are strictly optional and user-initiated.',
  default_avatar text DEFAULT '🧑‍🚀',
  daily_tiers jsonb DEFAULT '[{"levels":10,"reward":50},{"levels":25,"reward":100},{"levels":50,"reward":150},{"levels":100,"reward":200},{"levels":250,"reward":250}]'::jsonb,
  wheel_slices jsonb DEFAULT '[{"label":"+25 🪙","icon":"🪙","type":"coins","amount":25,"color":"#3B82F6"},{"label":"Try Again","icon":"😅","type":"none","amount":0,"color":"#64748B"},{"label":"+$0.05","icon":"💵","type":"usdt","amount":0.05,"color":"#16A34A"},{"label":"+3 🎟️","icon":"🎟️","type":"tickets","amount":3,"color":"#8B5CF6"},{"label":"+75 🪙","icon":"🪙","type":"coins","amount":75,"color":"#10B981"},{"label":"Extra Spin","icon":"🎡","type":"spin","amount":1,"color":"#F59E0B"},{"label":"+$0.10","icon":"💵","type":"usdt","amount":0.10,"color":"#EC4899"},{"label":"+2 🎟️","icon":"🎟️","type":"tickets","amount":2,"color":"#475569"}]'::jsonb,
  payment_methods jsonb DEFAULT '[{"id":"ton","name":"TON Wallet","icon":"💎","placeholder":"Enter TON Wallet Address (UQ... / EQ...)","minWithdraw":0.50,"note":"Fast TON network payout","enabled":true},{"id":"paypal","name":"PayPal","icon":"🅿️","placeholder":"Enter PayPal Email Address","minWithdraw":0.50,"note":"Global PayPal transfer","enabled":true}]'::jsonb,
  updated_at timestamptz DEFAULT now()
);

-- Safely add any missing columns if app_config already exists
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS maintenance_mode boolean DEFAULT false;
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS maintenance_msg text DEFAULT 'We are upgrading ArrowFlow servers. Please check back soon!';
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS monetag_enabled boolean DEFAULT true;
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS monetag_daily_limit integer DEFAULT 15;
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS monetag_ticket_reward integer DEFAULT 3;
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS monetag_cooldown_sec integer DEFAULT 5;
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS monetag_logo_url text DEFAULT '';
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS refer_reward_coins integer DEFAULT 100;
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS refer_bot_link text DEFAULT 'https://t.me/Arrowflow_bot/Arrowflowplay';
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS farm_rate_per_hour integer DEFAULT 24;
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS farm_duration_hours integer DEFAULT 2;
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS coins_per_1000_usdt numeric(10, 4) DEFAULT 0.50;
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS min_withdraw_usdt numeric(10, 4) DEFAULT 0.50;
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS support_link text DEFAULT 'https://t.me/telegram';
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS support_info_text text DEFAULT 'Payouts are processed within 24-48 hours.';
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS default_avatar text DEFAULT '🧑‍🚀';
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS daily_tiers jsonb;
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS wheel_slices jsonb;
ALTER TABLE public.app_config ADD COLUMN IF NOT EXISTS payment_methods jsonb DEFAULT '[{"id":"ton","name":"TON Wallet","icon":"💎","placeholder":"Enter TON Wallet Address (UQ... / EQ...)","minWithdraw":0.50,"note":"Fast TON network payout","enabled":true},{"id":"paypal","name":"PayPal","icon":"🅿️","placeholder":"Enter PayPal Email Address","minWithdraw":0.50,"note":"Global PayPal transfer","enabled":true}]'::jsonb;

-- Insert default row (id = 1) if not exists
INSERT INTO public.app_config (id)
VALUES (1)
ON CONFLICT (id) DO UPDATE SET
  payment_methods = COALESCE(public.app_config.payment_methods, EXCLUDED.payment_methods);


-- 2. PLAYERS TABLE (Stores Telegram user profiles, balances, levels & referrals)
CREATE TABLE IF NOT EXISTS public.app_users (
  telegram_id text PRIMARY KEY,
  username text DEFAULT 'ArrowPlayer',
  photo_url text,
  coins bigint DEFAULT 0,
  usdt_bonus numeric(12, 4) DEFAULT 0,
  tickets integer DEFAULT 5,
  level_unlocked integer DEFAULT 1,
  total_stars integer DEFAULT 0,
  daily_completed integer DEFAULT 0,
  referrals_count integer DEFAULT 0,
  referral_code text UNIQUE,
  referred_by text,
  is_blocked boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.app_users ADD COLUMN IF NOT EXISTS is_blocked boolean DEFAULT false;
ALTER TABLE public.app_users ADD COLUMN IF NOT EXISTS photo_url text;
ALTER TABLE public.app_users ADD COLUMN IF NOT EXISTS usdt_bonus numeric(12, 4) DEFAULT 0;
ALTER TABLE public.app_users ADD COLUMN IF NOT EXISTS referral_code text;
ALTER TABLE public.app_users ADD COLUMN IF NOT EXISTS referred_by text;


-- 3. WITHDRAWALS TABLE (Stores payout requests submitted by players)
CREATE TABLE IF NOT EXISTS public.withdrawals (
  id text PRIMARY KEY,
  telegram_id text NOT NULL,
  username text,
  method text NOT NULL,
  address text NOT NULL,
  coins bigint DEFAULT 0,
  usdt numeric(12, 4) NOT NULL,
  status text DEFAULT 'Pending',
  created_at timestamptz DEFAULT now()
);


-- 4. TASKS TABLE (Stores custom tasks created from Admin Panel)
CREATE TABLE IF NOT EXISTS public.tasks (
  id text PRIMARY KEY,
  title text NOT NULL,
  description text DEFAULT '',
  reward_type text DEFAULT 'tickets',
  reward_amount integer DEFAULT 5,
  wait_seconds integer DEFAULT 0,
  icon text DEFAULT '🎟️',
  logo_url text,
  link text DEFAULT 'https://t.me/telegram',
  sponsored boolean DEFAULT false,
  active boolean DEFAULT true,
  display_order integer DEFAULT 1,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS reward_type text DEFAULT 'tickets';
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS reward_amount integer DEFAULT 5;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS wait_seconds integer DEFAULT 0;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS active boolean DEFAULT true;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS display_order integer DEFAULT 1;


-- 5. ROW LEVEL SECURITY (RLS) & POLICIES
-- Allows Mini App users to read config/tasks & sync their progress,
-- while restricting Admin edits to authenticated Gmail/Password admins.
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.withdrawals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- app_config policies
DROP POLICY IF EXISTS "Public read app_config" ON public.app_config;
CREATE POLICY "Public read app_config" ON public.app_config FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admin write app_config" ON public.app_config;
CREATE POLICY "Admin write app_config" ON public.app_config FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- app_users policies
DROP POLICY IF EXISTS "Public read app_users" ON public.app_users;
CREATE POLICY "Public read app_users" ON public.app_users FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public upsert app_users" ON public.app_users;
CREATE POLICY "Public upsert app_users" ON public.app_users FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Public update app_users" ON public.app_users;
CREATE POLICY "Public update app_users" ON public.app_users FOR UPDATE USING (true) WITH CHECK (true);

-- withdrawals policies
DROP POLICY IF EXISTS "Public read withdrawals" ON public.withdrawals;
CREATE POLICY "Public read withdrawals" ON public.withdrawals FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public insert withdrawals" ON public.withdrawals;
CREATE POLICY "Public insert withdrawals" ON public.withdrawals FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Admin update withdrawals" ON public.withdrawals;
CREATE POLICY "Admin update withdrawals" ON public.withdrawals FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- tasks policies
DROP POLICY IF EXISTS "Public read tasks" ON public.tasks;
CREATE POLICY "Public read tasks" ON public.tasks FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admin manage tasks" ON public.tasks;
CREATE POLICY "Admin manage tasks" ON public.tasks FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ============================================================================
-- ARROWFLOW: ADMIN-MANAGED LEVELS
-- Run this migration after the original schema.
-- Replace YOUR_ADMIN_EMAIL with the Gmail used by the admin panel.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.game_levels (
  level_number integer PRIMARY KEY CHECK (level_number > 0),
  board_size integer NOT NULL DEFAULT 5 CHECK (board_size BETWEEN 5 AND 12),
  arrow_count integer NOT NULL DEFAULT 8 CHECK (arrow_count BETWEEN 3 AND 60),
  time_limit integer NOT NULL DEFAULT 90 CHECK (time_limit BETWEEN 25 AND 300),
  is_active boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.game_levels ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can read active game levels" ON public.game_levels;
CREATE POLICY "Public can read active game levels" ON public.game_levels
  FOR SELECT TO anon, authenticated USING (is_active = true);
DROP POLICY IF EXISTS "Admin can manage game levels" ON public.game_levels;
CREATE POLICY "Admin can manage game levels" ON public.game_levels
  FOR ALL TO authenticated
  USING ((auth.jwt()->>'email') = 'YOUR_ADMIN_EMAIL')
  WITH CHECK ((auth.jwt()->>'email') = 'YOUR_ADMIN_EMAIL');
