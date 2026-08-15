-- Every office already manages its own transport_packages catalog (name,
-- duration, ride count, price) through the Dashboard's "إدارة الباقات"
-- screen, but a package has never been able to say anything about itself
-- beyond its name — SubscriptionPlan.description exists in the Dart entity
-- but is dead-stubbed, because transport_packages has no description column
-- to read it from or write it to. This adds one, bilingual to match the
-- existing name_ar/name_en split.

alter table public.transport_packages
  add column if not exists description_ar text not null default '',
  add column if not exists description_en text not null default '';
