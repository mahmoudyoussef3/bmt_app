# Captain — User Flows

> **Scope.** The journeys a captain actually walks, with the failure branches drawn rather
> than implied. Verified against the code and the live database on **2026-07-28**.
>
> **Companions.** [`CAPTAIN_LIFECYCLE.md`](CAPTAIN_LIFECYCLE.md) ·
> [`CAPTAIN_USER_STORIES.md`](CAPTAIN_USER_STORIES.md) ·
> [`CAPTAIN_OPERATIONAL_STATUS.md`](CAPTAIN_OPERATIONAL_STATUS.md)

---

## 1. Launch and routing gate

```mermaid
flowchart TD
  S["Splash"] --> R{"Supabase session?"}
  R -->|no| L["Sign in"]
  R -->|yes| D{"current_driver_id() resolves?"}
  D -->|"no driver row"| REQ["Request access (join code)"]
  D -->|"driver inactive / office paused"| L
  D -->|"active"| SH["Captain shell — اليوم · السجل · حسابي"]
  L -->|success| D
  REQ -->|"approved (20s poll)"| SH
  REQ -->|"pending"| REQ
  REQ -->|"rejected"| L
```

Four roots, no bypass. Identity is re-resolved server-side on every launch, so a captain
deactivated overnight lands back on sign-in rather than in a stale shell.

---

## 2. Onboarding — self-service access request

```mermaid
flowchart TD
  A["Sign up / sign in"] --> B["Enter office join code"]
  B --> C{"Code matches an office?"}
  C -->|no| B
  C -->|yes| D["Submit request → captain_requests"]
  D --> E["Dashboard: approve / reject"]
  E -->|approve| F["drivers row created, status active"]
  E -->|reject| G["Rejected — captain told, returns to sign-in"]
  F --> H["Activation poll (20s) flips the app into the shell"]
```

The join code is authoritative — the office is not chosen from a list the captain can get
wrong.

---

## 3. Trip execution — the main journey

```mermaid
flowchart TD
  H["Home — focus card"] --> T["Open trip"]
  T --> ST{"Stage"}

  ST -->|awaitingRelease| W1["Disabled panel:<br/>waiting on operations"]
  ST -->|awaitingWindow| W2["Disabled panel:<br/>waiting on the clock"]
  W1 -.->|"ops publishes (live watch)"| ST
  W2 -.->|"30 min before departure"| ST

  ST -->|readyToBoard| B["بدء صعود الركاب"]
  B --> BR["captain_update_trip_status(boarding)"]
  BR --> BS["status = boarding<br/>actual_start_time stamped<br/>passengers + captain notified"]

  BS --> M["Work the manifest:<br/>board / absent / call / chat"]
  M --> DEP["انطلاق الرحلة"]
  DEP --> DR["captain_update_trip_status(in_progress)"]
  DR --> UW["status = in_progress"]

  UW --> TRK["Position reporting starts<br/>immediate fix, then every 30s"]
  UW --> MAP["Live map · next pickup · navigate"]
  UW --> ARR["Mark station arrived → trip_events"]

  UW --> C["إنهاء الرحلة"]
  C --> CONF{"Confirm dialog"}
  CONF -->|cancel| UW
  CONF -->|confirm| CR["captain_update_trip_status(completed)"]
  CR --> FIN["bookings → completed<br/>boarded riders → completed<br/>unboarded riders → no_show<br/>actual_end_time stamped"]
  FIN --> STOP["Reporting stops · terminal label"]

  UW -.->|"ops cancels"| CAN["Terminal 'cancelled' label<br/>reporting stops<br/>captain notified"]
  BS -.->|"ops cancels"| CAN
```

**Every button corresponds to a real backend transition.** There are no controls that only
write a log, and none that offer a transition the state machine would reject.

### Failure branches on a transition

| Backend error | What the captain sees |
| --- | --- |
| `invalid_transition` | حالة الرحلة لا تسمح بهذا الانتقال |
| `trip_not_found` | الرحلة غير موجودة |
| `not_your_trip` / `not_a_captain` / `status_not_allowed_for_captain` | غير مصرح لك بتعديل هذه الرحلة |

The screen's live watch is the source of truth, so a failed optimistic action reconciles
back to the real status rather than leaving the UI ahead of the database.

---

## 4. Live tracking

```mermaid
flowchart TD
  A["Trip enters in_progress"] --> B["startAutoSharing"]
  B --> C["Immediate fix"]
  C --> D["Timer every 30s"]
  D --> E{"Send in flight?"}
  E -->|yes| D2["Skip this tick — never queue"]
  E -->|no| F{"Location available?"}
  F -->|"service off"| G1["فعّل خدمة الموقع"]
  F -->|"denied"| G2["يلزم السماح بالوصول للموقع"]
  F -->|"denied forever"| G3["فعّلها من إعدادات التطبيق"]
  F -->|ok| H["Acquire fix (20s limit)"]
  H --> I{"Trip is mine?"}
  I -->|no| J["live_location_not_your_trip"]
  I -->|yes| K["INSERT — driver_id overwritten server-side"]
  K --> L["Client map · Live Ops · captain GPS card"]
  G1 --> D
  G2 --> D
  G3 --> D
  J --> D

  A2["Leaves in_progress<br/>(completed OR cancelled)"] --> M["stopAutoSharing"]
  A3["Screen closed"] --> M
```

An automatic failure keeps the last good fix on screen and retries on the next tick — the
captain is driving, and a dropped tick is not worth interrupting them over. The **card's
headline** reflects the age of the last landed fix, so a run of failures reads as
"تعذّر إرسال موقعك" rather than as a healthy cadence.

---

## 5. Navigation to the next stop

```mermaid
flowchart TD
  A["Next stop resolved<br/>(first station not yet reported arrived)"] --> B{"Has coordinates?"}
  B -->|no| C["Button not rendered at all"]
  B -->|yes| D{"Platform"}
  D -->|iOS| E["maps.apple.com/?daddr=lat,lng"]
  D -->|Android| F["google.com/maps/search/?api=1&query=lat,lng"]
  E --> G["launchUrl(externalApplication)"]
  F --> G
  G --> H{"Launched?"}
  H -->|yes| I["Device maps app takes over"]
  H -->|"false or throws"| J["تعذر فتح تطبيق الخرائط على هذا الجهاز"]
```

A stop without coordinates renders no button rather than one that fails. `launchUrl` both
returns `false` and throws on a device with no handler, and both are handled — the failure
is spoken aloud, never swallowed to the console.

---

## 6. Incident and SOS

```mermaid
flowchart TD
  subgraph Captain
    A["SOS: 3-second armed hold"] --> B["Report screen, type = emergency"]
    A2["Tools → report incident"] --> B2["Report screen, type chosen"]
    B --> C["Submit"]
    B2 --> C
    C --> D["INSERT driver_trip_reports<br/>status forced to 'pending'"]
    D --> E["Confirmation shown"]
    C -->|failure| F["Error — never reports submitted"]
  end
  subgraph Operations
    E --> G["Incident queue (Live Ops)"]
    G --> H["acknowledged — a human owns it"]
    H --> I["resolved + note"]
    G --> J["dismissed + note"]
  end
```

A plain tap on the SOS control explains the gesture instead of firing it. The captain
**cannot** move a report out of `pending` — no update or delete path exists for them, so a
filed incident cannot be withdrawn by the person who filed it.

---

## 7. Communication

```mermaid
flowchart TD
  A["Trip → تواصل الرحلة"] --> B["Broadcast thread (all passengers)"]
  C["Manifest → passenger card"] --> D["Per-passenger thread"]
  B --> E["Send → sender_type 'driver', sender_id = auth.uid()"]
  D --> E
  F["Operations sends"] --> G["Realtime: newest ops message"]
  G --> H{"First emission after subscribe?"}
  H -->|yes| I["Baseline — not announced"]
  H -->|no| J{"New message id?"}
  J -->|yes| K["Banner"]
  J -->|"same row re-emitted"| L["Ignored"]
```

De-duplication is on message **identity**. Operations repeating the same sentence is two
banners, because a repeated instruction usually means the first was not acted on.

---

## 8. Notifications

```mermaid
flowchart TD
  A["DB trigger on_operation_trip_change"] --> B["notifications row (target_app = captain)"]
  B --> C["FCM push"]
  C --> D{"App state"}
  D -->|foreground| E["In-app snackbar with عرض"]
  D -->|background| F["System notification"]
  E --> G["_onTap → pushNamed(action_url)"]
  F --> G
  G --> H{"Route resolves?"}
  H -->|"'/trips' → aliased"| I["Captain shell"]
  H -->|"null action_url"| J["No navigation"]
  K["Bell in shell"] --> L["Notification list → mark read"]
```

Deep-linking into a **specific trip** is not implemented: `action_url` and `data.trip_id`
are carried into the domain entity and then dropped, and tapping an in-app notification only
marks it read. Recorded as a gap, not described as working.

---

## 9. Offline and failure

```mermaid
flowchart TD
  A["Connectivity lost"] --> B["Banner on trip screens"]
  B --> C{"What was in flight?"}
  C -->|"status transition"| D["Error surfaced; live watch reconciles on reconnect"]
  C -->|"automatic position fix"| E["Last good fix kept; next tick retries"]
  C -->|"manual position fix"| F["Error state; captain may retry"]
  C -->|"manifest write"| G["Optimistic update rolled back + message"]
  C -->|"realtime refresh"| H["Current data kept on screen"]
  C -->|"mark notification read"| I["Swallowed — the stream re-emits the truth"]
```

There is **no offline queue**. Nothing is lost, but a transition or fix attempted with no
signal is delayed until the captain retries or the next tick fires.
