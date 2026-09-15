# Dashboard · Settings (الإعدادات)

**Local only — no backend calls.** The settings screen
(`lib/apps/dashboard/features/settings/presentation/screens/settings_screen.dart`,
`DashboardRoutes.settings` = `/settings`) offers the theme mode (فاتح / داكن / النظام) through
`DashboardThemeCubit` → `DashboardThemeRepository` (`lib/apps/dashboard/core/theme/`), persisted in
`shared_preferences` on the device.

Everything an operator would call "settings" that touches the server lives elsewhere:

| Setting | Module |
|---|---|
| Office name, logo, contact, service areas | `office_profile/` |
| Captain join code | `office_profile/` O2/O5 |
| Staff accounts and roles | `users/` |
| Plan, limits, invoices | `office_billing/` |
| Wallet policy caps (`office_wallet_policies`) | no UI today (`wallet_policy_edit` capability unused) |
| Referral reward config | `referrals/` G2 (platform-admin only server-side) |
| Platform enforcement settings | `platform_licensing/` X25 |

Nothing to port for this module. `DashboardPermission.settings` (admin only) gates the sidebar entry.
