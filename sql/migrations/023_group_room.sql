-- ============================================================================
-- Migration 023 — groups.room (Operational Schedule grid: room x time)
-- Har guruhga xona biriktiriladi. Dashboard'dagi Xona x Vaqt grid shundan foydalanadi.
-- SAFE / ADDITIVE. Universal (har markaz, har fan).
-- ============================================================================

alter table public.groups add column if not exists room text;
