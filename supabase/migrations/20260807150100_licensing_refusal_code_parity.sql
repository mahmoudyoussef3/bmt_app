-- ═══════════════════════════════════════════════════════════════════════════════════
-- Licensing — one spelling for the dependency refusal
-- ═══════════════════════════════════════════════════════════════════════════════════
-- The two enforcement paths disagreed on what a dependency block is called:
--
--   assert_feature()            raises 'feature_dependency_blocked'   ← §7.2, and Dart
--   office_can_consume_for()    reported reason 'dependency_blocked'
--
-- The quota trigger re-raises the verdict's `reason` verbatim, so a write refused on
-- dependency grounds through a trigger produced an exception message that
-- `LicensingFailure.tryParse` could not classify. It matched none of the six codes,
-- returned null, and the caller fell through to its generic mapping — the operator
-- saw "تعذّر تنفيذ العملية" instead of being told which feature to enable. A refusal
-- the client cannot name is exactly the outcome the three-predicate split exists to
-- prevent.
--
-- §7.2, `assert_feature` and the Dart constant already agree on
-- `feature_dependency_blocked`, so the resolver is the side that moves. The two
-- non-limit / limit branches are corrected identically; nothing else in the body
-- changes.
--
-- `create or replace` preserves the existing ACL, and this function is revoked from
-- every API role (it takes an explicit office id and exists for triggers only) — the
-- revokes are restated at the end so that stays true if the function is ever dropped
-- and recreated rather than replaced.

create or replace function public.office_can_consume_for(
  p_office_id uuid,
  p_key       text,
  p_amount    bigint default 1
) returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_res       jsonb;
  v_type      text;
  v_value     jsonb;
  v_limit     bigint;
  v_used      bigint;
  v_unlimited boolean := false;
  v_allowed   boolean;
  v_reason    text := null;
begin
  v_res   := public.platform_resolve_feature(p_office_id, null, p_key);
  v_type  := v_res ->> 'value_type';
  v_value := v_res -> 'value';

  -- A non-limit feature has no quota; the verdict degenerates to "is it on".
  if v_type <> 'limit' then
    v_allowed := public.platform_value_is_truthy(v_value);
    if not v_allowed then
      v_reason := case
        when v_res ->> 'blocked_by' is not null then 'feature_dependency_blocked'
        when v_res ->> 'source' = 'license_hold' then 'license_suspended'
        else 'feature_not_licensed'
      end;
    end if;
    return jsonb_build_object(
      'allowed', v_allowed, 'limit', null, 'used', null, 'remaining', null,
      'unlimited', false, 'reason', v_reason, 'feature', p_key,
      'plan_key', v_res ->> 'plan_key', 'source', v_res ->> 'source',
      'blocked_by', v_res ->> 'blocked_by',
      'license_status', v_res ->> 'license_status');
  end if;

  v_used := public.office_usage_for(p_office_id, p_key);

  if (v_value #>> '{}') = 'unlimited' then
    v_unlimited := true;
    v_allowed   := true;
  else
    v_limit   := (v_value #>> '{}')::bigint;
    v_allowed := (v_used + greatest(p_amount, 0)) <= v_limit;
    if not v_allowed then
      v_reason := case
        when v_res ->> 'blocked_by' is not null then 'feature_dependency_blocked'
        when v_res ->> 'source' = 'license_hold' then 'license_suspended'
        else 'quota_exceeded'
      end;
    end if;
  end if;

  return jsonb_build_object(
    'allowed',   v_allowed,
    'limit',     case when v_unlimited then null else v_limit end,
    'used',      v_used,
    'remaining', case when v_unlimited then null else greatest(v_limit - v_used, 0) end,
    'unlimited', v_unlimited,
    'reason',    v_reason,
    'feature',   p_key,
    'plan_key',  v_res ->> 'plan_key',
    'source',    v_res ->> 'source',
    'blocked_by', v_res ->> 'blocked_by',
    'license_status', v_res ->> 'license_status');
end;
$$;

revoke all on function public.office_can_consume_for(uuid, text, bigint) from public, anon, authenticated;
