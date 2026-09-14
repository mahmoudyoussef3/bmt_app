# Client · Wallet (محفظة العميل)

The rider's per-office wallets (refunds, cashback, manual credits) with each wallet's recent ledger.
Read-only for the client; every ledger write happens on the dashboard side (refunds, manual
credit/debit) through idempotent RPCs documented in `docs/API_DOCUMENTATION.md` §10.5.

## Overview

| Layer | Files (relative to `lib/apps/client/features/wallet/`) |
|---|---|
| Screen | `presentation/screens/client_wallet_screen.dart` (`WalletRoutes.wallet`) |
| Cubit | `ClientWalletCubit` (`load()`, `refresh()`) |
| Use case | `domain/usecases/` (`GetClientWalletSummaryUseCase`) |
| Repo | `data/repositories/client_wallet_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_client_wallet_datasource.dart` (`getSummary()`, line 17) |
| Entity | `domain/entities/client_wallet.dart` (`ClientWalletSummary`, `ClientWallet`, `ClientWalletEntry`, `ClientWalletEntryKind`) |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| W1 | Wallet summary | `POST rpc/client_wallet_summary` | session | `GET /api/v1/me/wallets` |

---

## W1 — `getSummary()`

```
POST /rest/v1/rpc/client_wallet_summary
{}
→ 200 {
  "total_balance": 350.00,
  "wallets": [{
    "wallet_id":"<uuid>", "office_id":"<uuid>", "office_name":"…", "office_logo_url":"…|null",
    "balance": 350.00, "available_balance": 350.00, "status":"active", "entry_count": 4, "updated_at":"<ts>",
    "entries": [{ "id","seq":4,"kind":"refund","category":"…","amount":150.00,"balance_after":350.00,"status":"posted","reason":"…","created_at":"<ts>" }]
  }],
  "generated_at": "<ts>"
}
```

SQL (`20260806090600_client_wallet_read.sql:33-84`): `SECURITY DEFINER`, `stable`; `not_authenticated`
when no `auth.uid()`; sums `wallets.balance` for the caller; per wallet joins `offices` for the name/logo
(**bypassing** the listed-offices restriction on purpose — a delisted office's balance must still show a
name); entries = last **30** `wallet_transactions` by `seq desc`; wallets ordered by balance desc then
office name. Granted to `authenticated` only.

Mapping (`SupabaseClientWalletDatasource`): numerics are parsed from `num` **or** `String` (`_money`) — Postgres
`numeric` can arrive as a string; `office_name` blank ⇒ `'مكتب'`; `available_balance` falls back to `balance`;
`kind` → `ClientWalletEntryKind.fromDb`: `refund | cashback | manual_credit | manual_debit | wallet_spend | wallet_topup | reversal`;
entry `status` default `posted`; wallet `status` default `active`.

`RLS`: none needed — the RPC takes no parameters and resolves the caller itself.

**Proposed .NET:** `GET /api/v1/me/wallets` → the same JSON (camelCase), entries capped at 30 per wallet
(or `GET /api/v1/me/wallets/{walletId}/transactions?page=` for full history).

## Notes for the .NET team

1. The wallet ledger's laws (append-only `seq`, `balance_after`, idempotent `p_request_key`) are described in `docs/API_DOCUMENTATION.md` §10.5 / §22 — the client only reads the result.
2. `wallet_spend` exists as an entry kind but **no client path spends a wallet** (the booking RPC has no wallet leg; `wallet_balance` is filtered out of the payment methods).
3. Money must be serialised so that large `numeric` values do not silently become 0 — the app guards for string-encoded numbers.
