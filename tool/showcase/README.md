# EWT product screenshots

A harness that photographs the **real** EWT screens over invented demo data, and
frames the results into marketing and portfolio assets.

Nothing here draws product UI. Every screen mounted is the widget the app ships;
only the cubits behind it are replaced, with fakes already holding a loaded
state. `registerClientDependencies()` / `registerCaptainDependencies()` /
`registerDashboardDependencies()` are never called, so no capture can reach
Supabase, Firebase or the device GPS.

## Layout

```
tool/showcase/
├── showcase_main.dart        # one web entry; ?screen=<id> picks the screen
├── client_showcase.dart      # fakes + screen table for the Client app
├── client_demo_data.dart
├── captain_showcase.dart     # fakes + screen table for the Captain app
├── captain_demo_data.dart
├── dashboard_showcase.dart   # fakes + route table for the Dashboard
├── dashboard_demo_data.dart
└── capture/                  # Node + headless Chrome, drives the build
    ├── manifest.mjs          # screen list → capture manifest
    ├── capture.mjs           # manifest → showcase_assets/raw/**.png
    ├── compose.mjs           # raw → showcase_assets/{marketing,portfolio}
    └── landing_assets.mjs    # raw → assets/showcase/ (used by the landing page)
```

## Regenerating

```bash
# 1. Build the harness for web
flutter build web -t tool/showcase/showcase_main.dart --release --no-tree-shake-icons

# 2. Serve it
(cd build/web && python3 -m http.server 8750)

# 3. Capture + compose (needs Google Chrome and `npm i playwright-core`)
cd tool/showcase/capture
node manifest.mjs > all.json
node capture.mjs all.json      # → showcase_assets/raw/
node compose.mjs               # → showcase_assets/marketing, /portfolio
node landing_assets.mjs        # → assets/showcase/ (landing page)
```

To eyeball one screen while iterating, skip the capture and open the URL:
`http://localhost:8750/?screen=dashboard-executive-overview` (add `&theme=dark`).

## Demo data rules

* Every rider, captain, office, plate and figure is invented. No production row
  is read, and no capture writes anything.
* Phone numbers use an obviously-synthetic `0100000NNNN` pattern so a
  screenshot never looks like it leaked a real customer.
* Numbers stay internally consistent with the screen around them — a route's
  stated distance matches the polyline the same screen draws, a wallet's entry
  signs match its running balance.

## Screens deliberately not captured

* **The old seat-selection → checkout pair.** `ClientRouter` does not register
  it (see its comment): it fronted a second booking funnel that no longer
  works. The booking wizard is the funnel a rider can actually reach, so the
  wizard's six steps are what the client showcase photographs.
* **`DashboardRoutes.reports` on its own.** Its sidebar entry is commented out
  in `dashboard_shell.dart`, so the shell falls back to the first nav item and
  titles the page "الرئيسية" — a screenshot that misreports the console. The
  same reporting surface is captured through the money module's own tabs
  (`dashboard-finance-analytics`, `dashboard-finance-reports`), which carry the
  correct chrome.
