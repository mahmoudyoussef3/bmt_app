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
    ├── landing_assets.mjs    # raw → assets/showcase/*.webp (the landing page)
    └── vehicle_photos.mjs    # draws the demo bus → web/showcase/vehicles/*.webp
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
node landing_assets.mjs        # → assets/showcase/*.webp (landing page)
```

`vehicle_photos.mjs` is not part of that run — the pictures it draws only change
when the drawing does, and they have to exist **before** step 1, since the web
build is what serves them.

To eyeball one screen while iterating, skip the capture and open the URL:
`http://localhost:8750/?screen=dashboard-executive-overview` (add `&theme=dark`).

## Demo data rules

* Every rider, captain, office, plate and figure is invented. No production row
  is read, and no capture writes anything.
* **The one thing here that is drawn rather than photographed** is the demo
  bus. `vehicle_photos.mjs` renders three views of it — side, front, cabin —
  into `web/showcase/vehicles/`, and the demo data points the rider app's
  vehicle gallery at them by URL (they are served by the harness's own web
  build, so they never ship inside the mobile app bundle). The gallery's slot
  holds pictures an *operator* uploads, and a stock photograph would put a real
  vehicle and a real plate into marketing material. Only the bus plated
  `ن ص ٤٢٧` carries them; the other two vehicles have no photos on file, which
  is a real state and the one the empty frame is for.
* Phone numbers use an obviously-synthetic `0100000NNNN` pattern so a
  screenshot never looks like it leaked a real customer.
* Numbers stay internally consistent with the screen around them — a route's
  stated distance matches the polyline the same screen draws, a wallet's entry
  signs match its running balance.

## What the landing page gets

`landing_assets.mjs` writes **unframed** WebP copies into `assets/showcase/`.
The browser window and the phone body around them are drawn in Flutter by
`lib/landing/presentation/widgets/landing_device.dart`, so the same capture can
appear at any size without its chrome resampling, and a palette change to the
site does not mean re-photographing the product. `LandingShots` in
`landing_shots.dart` is the list of names it produces — keep the two in step.

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
* **`dashboard-live-ops` on the landing page.** It still captures (the raw PNG
  is kept), but its board photographs as a flat grey rectangle under the
  harness, so `landing_assets.mjs` does not ship it. The tell is the file size:
  a 738KB PNG that compresses to a 27KB WebP is a picture of nothing.
