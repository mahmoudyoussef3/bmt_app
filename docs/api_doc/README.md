# EWT API Documentation (per app, per feature)

This folder is the **backend hand-off reference** for the team converting EWT from Supabase to a
.NET / ASP.NET Core backend. It is organised by **app** and then by **feature**, so an engineer
assigned one feature can read one folder and have everything: the screens, the exact Supabase
calls made today (URL, query string, body), the response fields the app actually reads, the
server-side business rules that must be re-implemented, the error codes the app expects, and the
place in the Flutter code where the call is made.

```
docs/api_doc/
├── README.md                    ← this file
├── client_api_doc/              ← Client (passenger) app — COMPLETE
│   ├── README.md                ← conventions, base URL, auth, feature index, master inventory
│   ├── auth/README.md
│   ├── onboarding/README.md
│   ├── home/README.md
│   ├── booking/README.md
│   ├── seat_selection/README.md
│   ├── payments/README.md
│   ├── packages/README.md
│   ├── trips/README.md
│   ├── tracking/README.md
│   ├── seat_release/README.md
│   ├── support/README.md
│   ├── communication/README.md
│   ├── notifications/README.md
│   ├── profile/README.md
│   ├── routes/README.md
│   ├── offices/README.md
│   ├── referrals/README.md
│   ├── loyalty/README.md
│   └── wallet/README.md
├── dashboard_api_doc/           ← Ops Dashboard — NOT STARTED (placeholder)
└── captain_api_doc/             ← Captain (driver) app — NOT STARTED (placeholder)
```

Every statement in these files was derived by reading the Flutter source under
`lib/apps/<app>/features/<feature>/data/` and the SQL under `supabase/migrations/`
(latest definition of each function/view wins). Nothing is aspirational unless tagged.

## Tags

| Tag | Meaning |
|---|---|
| `SUPABASE-SPECIFIC` | Behaviour that exists only because Supabase provides it (PostgREST embeds, RLS, Realtime CDC). The .NET team must decide the replacement. |
| `NEEDS BACKEND DECISION` | A real design decision the .NET team must take. |
| `NOT IMPLEMENTED` | The Flutter code has a seam for it but no live implementation. |
| `RETIRED` | Code still exists in the repo but is unreachable or its server function was dropped. Do **not** port it. |
| `BUSINESS RULE` | A rule currently enforced in SQL (`SECURITY DEFINER` function or trigger) that the backend must own. |
| `RLS` | An authorization boundary currently enforced by Postgres Row Level Security that must become explicit backend authorization. |

## Companion document

`docs/API_DOCUMENTATION.md` is the earlier monolithic version covering all three apps. The
proposed `/api/v1/...` endpoint names used in the per-feature files below are kept consistent
with its endpoint index (§11) so the two documents can be read together.
