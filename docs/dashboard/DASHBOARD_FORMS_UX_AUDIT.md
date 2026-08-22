# Dashboard — Forms & Dialog UX Audit (Phase 2)

**Date** 2026-08-21 · **Scope** UI/UX only — no schema, RLS, RPC, auth, entitlement or
accounting change. **Branch** `enhance-theme`.

This is the form/dialog-focused follow-up to `DASHBOARD_UX_AUDIT.md` (2026-08-15, whole-console)
and the Phase 1 Light Mode pass (Customers, Home, Fleet, Finance). Phase 1 verified the shared
card/KPI treatment; this phase asks a narrower question: **when an operator has to type
something in — create a trip, reject a payment, add a driver, cancel a trip — is the form
clear, safe, and honest about what happens next?**

Audit-first, as instructed: every finding below was read from the actual widget/cubit code
(not inferred), and severities were recalibrated against the *caller*, not just the dialog
file, before anything was changed — two agent-reported "P0"s turned out to be non-issues once
the caller's own loading/error handling was checked (§6).

---

## 1. Method

1. Four parallel read-only research passes (general-purpose agents, no edits) covering:
   booking/payment dialogs & office billing; user/office management forms; filters, date
   pickers & file upload; confirmation dialogs & multi-step/long forms.
2. Direct reading of the highest-stakes, highest-frequency forms myself: the trip creation
   wizard + its cubit, the route builder + stop editor, the driver and vehicle forms, the trip
   pricing dialog, the trip cancellation dialog, and the shared `TripFareFields`/
   `TripFareControllers` fare editor used by two of those.
3. Cross-checked every "the dialog has no loading/error handling" style finding against its
   **caller** before accepting it — several dialogs deliberately hand result-handling to the
   screen (the documented dashboard convention: *a failed action keeps the loaded state and
   surfaces a transient `actionError`*), which is correct, not a defect.
4. Implemented the highest-confidence, most narrowly-scoped fixes; captured before/after
   visual evidence in Light Mode (Dark Mode spot-checked, not damaged); ran `flutter analyze`
   and the dashboard test suite.

## 2. Forms & dialogs audited

**Read in full, by me:** trip creation wizard (`trip_creation_wizard.dart` +
`trip_creation_cubit.dart`), route builder (`route_builder_view.dart`), the stop/waypoint
editor (`route_stop_editor.dart`), the driver form (`fleet_driver_form_view.dart`), the
vehicle form (`fleet_vehicle_form_view.dart`), the trip pricing dialog
(`trip_pricing_editor_dialog.dart`), the trip cancellation dialog
(`trip_cancellation_dialog.dart`), the shared fare editor (`trip_fare_fields.dart` +
`trip_fare_controllers.dart`), the wallet action dialogs (`wallet_action_dialogs.dart`), and
`platform_office_filters.dart`.

**Read by the four research passes:** booking action dialogs (approve/reject/reupload +
reassign), the wallet amount and refund dialogs, office billing (confirmed read-only, no
form exists), staff account creation + password reset, office identity + office onboarding
(dialog and form), platform office filters, plan assignment and plan editor dialogs, filter
bars for bookings/trips/platform offices/reviews/reports, every `showDatePicker`/
`showTimePicker` call site, the fleet document add form and document manager, captain-request
rejection, the live-ops incident-resolution dialog, the ticket-details dialog, licensing
refusal dialogs, the platform-licensing plan editor, the per-office plan sheet, and the
create-subscription sheet.

That is the large majority of the console's write surfaces. Two lower-traffic corners were
touched only lightly and are called out under Remaining Issues: `reviews_filter_bar.dart`,
and the fleet document forms' upload UX.

## 3. Findings and what was done about each

Severity: **P0** blocking/dangerous · **P1** significant friction or risk · **P2** polish.
✅ = fixed this pass · 📝 = documented only (see §7 for reasoning on scope).

### P0 — data loss / wrong navigation on the console's single highest-stakes form

**1. ✅ Trip creation wizard wiped the entire form on a rejected submit.**
`trip_creation_wizard.dart` — `TripCreationWizardDialog`.
**What was wrong:** the dialog's `BlocConsumer` rendered a *completely different widget* for
`TripCreationLoading` (a bare spinner) and `TripCreationError` (a bare retry screen) than for
`TripCreationWizardDataLoaded` (the actual `TripCreationWizard`). `submitTrip()` — correctly,
for the snackbar/pop it also does — emits `TripCreationLoading()` then, on failure,
`TripCreationError()` before re-emitting the loaded state. Every one of those three transitions
tore down `TripCreationWizard`'s `State` and rebuilt a fresh one.
**Why it hurt:** the cubit itself anticipates ordinary, recoverable refusals here — a
duplicate trip-code collision, a driver that became busy between page-load and submit — and
even writes a friendly Arabic sentence for each ("حاول إنشاء الرحلة مرة أخرى"). An operator who
had picked a route, a driver, a date/time and built a 2–3 row package menu would see that
sentence for a heartbeat and then land back on a **completely blank wizard**, having to
redo the whole plan from scratch — for a failure that was never their fault.
**Fix:** `TripCreationWizardDialog` now caches the last `TripCreationWizardDataLoaded` state
and, once it has ever loaded, keeps rendering the same `TripCreationWizard` for every
subsequent state — passing a `submitting` flag instead of unmounting it. The small
spinner/retry screens now only ever appear before the wizard has loaded for the first time.
Covered by a new regression test (`trip_creation_wizard_dialog_test.dart`) that fills in a
route/driver/price, forces a rejected submit through a fake cubit, and asserts all three
survive.

**2. ✅ A successful trip creation could pop two screens instead of one.**
Same file. `_onSubmitTrip` called `Navigator.of(context).pop()` on success **in addition to**
the dialog wrapper's own `listener`, which already pops on `TripCreationSuccess`. Both calls
target the same Navigator (a `Dialog` does not open a nested one), so a successful submit
could close the wizard *and* pop whatever was behind it. Removed the redundant pop; the
listener is now the single owner of "close on success."

### P1 — a real, silently-reachable failure and confusing risk signals

**3. ✅ Vehicle form had no unsaved-changes exit guard; the driver form does.**
`fleet_vehicle_form_view.dart` vs. `fleet_driver_form_view.dart` — an established, working
pattern (`PopScope` + a confirm dialog on close) existed on the driver form and was simply
never carried over to its sibling, despite the vehicle form being the longer of the two
(images, a driver assignment, seat-layout preview). One misclick on the × discarded
everything, including already-picked photos, with no confirmation. Mirrored the driver form's
exact pattern: `_hasChanges`, `PopScope`, the same confirm-dialog copy, wired through `Form.onChanged`
plus the image-picker mutators (which sit outside the `Form` tree and would not otherwise
flip `_hasChanges`).

**4. ✅ `RefundDecisionDialog`: approving and rejecting a refund used identical button styling.**
`wallet_action_dialogs.dart` — two opposite financial outcomes ("اعتماد وتنفيذ" / "رفض") were
both a plain-colored `FilledButton`, differing only by label text. The codebase already has an
established destructive-red convention (`trip_cancellation_dialog.dart`'s confirm button).
Applied the same `scheme.error` fill to the reject path only; approve stays the default
primary color.

**5. ✅ The fare editor could not tell the operator *which* package row was incomplete.**
`trip_fare_fields.dart`, shared by the trip wizard and the trip-pricing dialog. `TripFareControllers`
already computes exactly which condition blocks save (`isValid`, `hasIncompletePackage`) — but
none of it ever reached a specific field. The only feedback was a single vague sentence
("أكمل بيانات كل باقة: الاسم وعدد الرحلات والمدة والسعر") that names no row, so with three or
more package rows the operator has to eyeball every one to find the culprit. Added per-field
`errorText` that appears **only once that specific row has been touched** (a brand-new row
starts silent; an existing catalog row is flagged only once its own price has actually been
edited, so a catalog package seeded before the base fare is typed never shows a false error at
dialog-open). See the capture in §5 — a row with only its name filled in now shows "مطلوب"
under exactly the three fields still missing, nowhere else.

**6. ✅ Advanced trip filters collapsed into a bare count, the exact anti-pattern this brief
warned about.** `trips_screen.dart` — the folded filter section showed `"٢ فلتر متقدم"`
instead of naming which two, unlike bookings' and customers' filter bars (which already name
active filters, e.g. "مسار: القاهرة–الإسكندرية") and unlike the *rest of this same section's*
own quick-filter and search chips two lines above it. Replaced the count with the same named-
chip convention: `"الحالة: مجدولة"`, `"المسار: ..."`, `"السائق: ..."`, etc., one chip per active
filter.

**7. ✅ `platform_office_filters.dart` wired a raw `TextField` straight to the cubit on every
keystroke** — the one documented anti-pattern `DebouncedSearchField` exists specifically to
prevent, and on what the auditing pass identified as plausibly the largest list in the
dashboard (every office on the platform). Swapped to `DebouncedSearchField`, following the
exact keyed-remount convention already used in `booking_filters_bar.dart` for "the query also
needs to reset when 'مسح عوامل التصفية' fires externally." The widget had no other local state
once the controller was removed, so it was simplified from a `StatefulWidget` to a
`StatelessWidget` rather than leaving an empty State class behind.

**8. ✅ An expired driver/vehicle document looked identical to a valid one, in the one place
that most needed to explain itself.** `fleet_documents_inline_section.dart` — a document's
saved-document chip showed only its type and expiry date, in the same neutral style whether
`valid`, `expiringSoon`, or `expired`. Elsewhere in the *same form*, an expired document
silently removes that driver or vehicle from the other side's picker
(`_getAvailableVehicles`/`_getAvailableDrivers` both filter out expired-doc owners) — so an
operator staring at "why is this driver missing from the vehicle assignment dropdown" had no
way to see the reason on the one screen that shows the documents. Reused
`fleet_document_manager.dart`'s existing status→color mapping (error/tertiary/primary) so the
chip is now red with "منتهي" appended for an expired doc, amber with "ينتهي قريباً" for one
expiring soon, and unchanged for a valid one.

### Findings verified and *not* acted on — the caller already handles it correctly

**9. 📝 Booking approve/reject/reupload dialogs pop before the actual approve/reject RPC
resolves, with no in-dialog loading state.** True of the dialog file in isolation. Checked
`booking_review_intents.dart` → `BookingsCubit.approveBooking/rejectBooking`: this is the
documented, deliberate dashboard convention — *a failed action keeps the loaded list and
surfaces a transient `actionError`* on the screen, not the dialog, precisely so the operator's
filters/scroll position survive a failure. Not a defect; this is the established pattern
working as designed.

**10. 📝 Trip cancellation dialog has no `_submitting`/loading state of its own.** Checked the
caller (`trips_screen.dart`'s `_cancelTrip`/`_run`): the actual cancel button is already
disabled via `state.isSaving`, and the server's refusal reason is already surfaced via
snackbar. The dialog's only job is collecting the reason; the caller owns the async state
correctly. Also not a defect.

## 4. Findings documented but not fixed this pass (see §7 for why)

Grouped by area, most consequential first. All are traceable to a specific file for a future
pass.

**Credential/admin forms** (`staff_account_form.dart`, `office_onboarding_form.dart`,
`staff_password_dialog.dart`): a manually-typed password has no reveal toggle and no confirm
field anywhere in the console, so a typo locks a colleague out with no way to verify what was
typed before submitting — highest severity in the whole audit, but touches three files and a
shared "credential field" concept that does not exist yet, which is a bigger, more deliberate
change than this pass's scope. Latin-script fields (username, email, slug, phone) are not
forced LTR inside these RTL forms in several places.

**Wallet module risk-proportionality:** `RefundDecisionDialog`'s color fix (finding 5) aside,
`WalletReverseDialog` and the freeze/unfreeze dialog still use the default primary color for a
consequential action, and none of the four dialogs in `wallet_action_dialogs.dart` show a
spinner on submit (they do correctly disable, just without visual feedback that the tap
registered). `WalletRefundDialog` executes a directly-operator-edited amount in one tap, while
the sibling `WalletAmountDialog` debit path — arguably no more consequential — has a genuine
restate-and-confirm second step; the two should probably match.

**`ticket_details_dialog.dart`:** the note-save button correctly checks `state.actionLoading`;
the four status-change buttons ("بدء المراجعة" / "تم التواصل" / "تم الحل" / "إغلاق") do not,
so a fast double-tap can fire two concurrent status RPCs with no client-side re-entrancy guard.
"إغلاق" also fires with no confirmation, unlike every other closing/rejecting action audited.

**Date/time input has six different interaction shapes across the console** (a
`DebouncedSearchField`-style field, a bespoke tile, a sentence-plus-button, two different
`readOnly TextField` treatments, and one raw-ISO button label) with no shared `DateField`
widget, despite the design system's centralization rule. Two of those `readOnly` fields
(`fleet_driver_form_view.dart`'s date field, and both fleet document forms' expiry field) use
hint text ("سنة-شهر-يوم") that reads exactly like an editable placeholder — tapping to type
does nothing, only the calendar icon works. This is a real affordance mismatch, not a style
nit.

**`plan_form_sheet.dart`** (per-office subscription plans) has eight fields with no section
grouping at all, unlike its close sibling `plan_editor_dialog.dart` (platform licensing plans)
which is well-sectioned — the two dialogs share almost the same title ("باقة جديدة") for two
different concepts, which risks confusion on its own.

**`reviews_filter_bar.dart`** has the same raw-`TextField`-to-cubit issue as finding 7, but its
`TextEditingController` is also read directly by the screen for a collapsed-summary chip, so
the fix is not a drop-in swap the way `platform_office_filters.dart` was — it needs the screen
to read the filter's search text from cubit state instead of the raw controller. Left
undone to avoid a rushed change to unrelated screen code.

**Validation-error visual weight:** the driver-form capture in §5 shows every required field
turning fully red-bordered simultaneously on a blank submit. This matches the brief's "after
submit, show all required errors" rule, but the *volume* of red at once on an eight-plus-field
section is closer to "aggressive visual noise" than the brief's ideal — a lighter tint or
error-colored label instead of a full red rectangle per field would reduce the shock without
losing the signal. Affects every form using the same `TextFormField` + red-border default
Material styling, i.e. most of the console — a design-token-level change, not a one-file fix.

**Two competing dialog "skins" coexist.** The trip creation wizard and the fleet driver/vehicle
forms use an older, more decorated style — gradients on icon badges, `boxShadow` on every
section card, colored left-borders — while the route builder, stop editor, trip pricing dialog
and trip cancellation dialog (all touched more recently) use a flatter, more restrained style:
plain `Dialog`, thin borders, no shadow or gradient. Per this brief's §17 ("avoid excessive
gradients/shadows... this is a serious business platform"), the restrained style is the one to
converge on — but the flashier skin sits on the console's two highest-traffic create forms,
which is a larger, more visible pass than this one's scope covers.

## 5. Visual verification

Light Mode, primary. Dark Mode spot-checked for the same two shared files I actually edited
(`trip_creation_wizard.dart`, `trip_fare_fields.dart`) to confirm nothing broke there.

| Screen | Capture file(s) | What it confirms |
|---|---|---|
| Trip creation wizard | `trip_wizard_1_blank_light`, `_2_blank_dark`, `_3_package_row_errors_light` | Blank state in both themes unaffected; the new per-field package errors (finding 5) render exactly on the three untouched fields of a half-filled row, nowhere else |
| Route builder | `route_builder_7_editing_light`, plus the 6 pre-existing dark captures | Section hierarchy, readiness footer and RTL layout hold in Light Mode |
| Stop/waypoint editor | `route_builder_8_stop_editor_light` | The exemplary neutral-until-submit pattern (§6) confirmed in Light Mode |
| Driver form | `fleet_driver_1_new_light`, `_2_validation_light`, `_3_editing_light` | Sectioned layout in Light Mode; submit-time validation now visibly confirmed (all required fields flagged, optional field untouched) |
| Vehicle form | `fleet_vehicle_1_new_light`, `_2_editing_light`, `_3_unsaved_changes_light` | Light Mode layout; **the new unsaved-changes guard (finding 3) firing end-to-end**, matching the driver form's dialog exactly |
| Trip pricing dialog | `trip_pricing_1_new_light`, `_2_validation_light` | Compact dialog sizing; existing submit-time error message confirmed close to the field it concerns |
| Trip cancellation (complex confirmation) | `trip_cancel_1_light`, `_2_validation_light`, `_3_dark` | Consequence banner, destructive-red confirm, conditional required-reason validation, and Dark Mode all intact |

All PNGs are under each feature's `_captures/` directory, generated via
`flutter test <file> --update-goldens`.

## 6. What was already good (preserve; do not "fix")

- **The stop editor's validation copy** is the reference example this brief's own "BETTER"
  illustration describes: no error until submit, then "أدخل اسم النقطة للمتابعة" instead of a
  generic "مطلوب", an optional map location framed in neutral surface colors rather than error
  red.
- **The route builder's save bar**: a single readiness sentence naming the *next* thing to do,
  with a "اذهب إليها" jump straight to the offending stop, instead of a checklist. `saving`/
  `saveError` are props owned by the parent, so — unlike the trip wizard bug this pass fixed —
  a failed save never tears the form down.
- **`trip_cancellation_dialog.dart`**: states concrete counts ("سيتم إلغاء 2 راكب وتحرير 2
  مقعد"), warns that paid bookings need a manual refund, uses the destructive-red convention
  correctly, and validates the reason only on submit.
- **`TripPricingEditorDialog`**: local `saving`/`error` state, never lost on a failed save —
  the correct pattern the trip wizard bug (finding 1) was missing.
- **`assign_plan_dialog.dart`, `incident_resolution_dialog.dart`, `licensing_dialogs.dart`**:
  each states consequences up front in plain language before the action, which is exactly the
  brief's "what happens after submission" requirement.
- **`booking_filters_bar.dart` / `customers_toolbar.dart`**: the reference pattern for a
  folded filter section — named active filters, a "مسح الفلاتر (n)" clear-all, and
  `DebouncedSearchField` throughout.
- **The driver form's per-field validators** carry specific, Egyptian-context-aware Arabic
  messages (national ID digit count, phone format) rather than generic "invalid input" text.

## 7. Why some findings were documented rather than fixed

The brief is explicit that this phase should not "redesign every form because it exists," and
several of the remaining findings genuinely need either (a) a new shared primitive that does
not exist yet (a reveal/confirm credential field, a unified `DateField`), (b) a change to a
file outside the forms/dialogs themselves (the reviews screen's controller ownership), or (c)
a design-token-level decision (how much red is too much red on a validation pass; which dialog
skin the console converges on) that is bigger than one file and deserves its own scoped pass
rather than being folded into this one opportunistically. Fixing those here risked exactly the
kind of scope creep and rushed, under-reviewed change the brief warns against. They are
recorded in §4 with enough detail to scope a follow-up directly.

## 8. Components reused / created

**Reused, no new component needed:** `DebouncedSearchField` (finding 7), the
`fleet_document_manager.dart` document-status color mapping (finding 8), the driver form's
unsaved-changes `PopScope` pattern (finding 3), the destructive-red `FilledButton` convention
already established by `trip_cancellation_dialog.dart` (finding 4).

**Created:** none. Every fix in this pass was implementable by adopting an existing, working
pattern from elsewhere in the same codebase — which is itself a finding: the primitives this
phase needed already existed, they just had not been carried consistently to every form that
needed them.

## 9. Recommended next steps

1. **Credential fields**: a small shared "password field with reveal toggle + confirm field"
   pattern, adopted in `staff_account_form.dart`, `office_onboarding_form.dart` and
   `staff_password_dialog.dart` — highest real-world consequence of anything found, deserves
   its own pass.
2. **Unify date/time input** behind one `DateField`-style widget in `core/widgets/`, fixing the
   two `readOnly`-but-looks-typable fields as part of the same change.
3. **`ticket_details_dialog.dart`**: add `state.actionLoading` guards to the four status
   buttons and a confirmation step before "إغلاق", mirroring the pattern already used by
   `captain_request_reject_dialog.dart`.
4. **Converge the two dialog skins** (§4) — a deliberate, reviewed pass on the trip wizard and
   fleet forms toward the flatter style the newer modules already use, not a drop-in swap.
5. **`reviews_filter_bar.dart`**: move the collapsed-summary chip to read from cubit state so
   the search field can move to `DebouncedSearchField` without the screen losing its "بحث: …"
   summary.
6. Revisit validation-error visual weight (§4) at the design-token level — likely a
   `TextFormField` theme adjustment, not a per-form change.

## 10. Final verification

- **`flutter analyze`**: 21 issues before this pass, 21 after — identical set, none in any file
  this pass touched. Zero new issues introduced.
- **Dashboard test suite** (`flutter test test/apps/dashboard/`): **1428 tests, 1427 passing
  before** this pass → **1429 tests, 1428 passing after** (the +1 is the new regression test
  for finding 1). The one failure, present in both runs
  (`trip_creation_driver_vehicle_test.dart`, "a driver with no vehicle blocks creation and says
  why"), is pre-existing and unrelated — it asserts a navigation target of `/assignments`, a
  route removed by the 2026-08-20 fleet-module-simplification commit that renamed the target to
  `/drivers`; confirmed via `git stash -u` that it fails identically on the pre-Phase-2 tree.
  Left as-is per this task's "don't touch unrelated modules" instruction; it is a one-line test
  fix, not a UX issue, and is called out here rather than folded in silently.
- **New test**: `test/apps/dashboard/features/trips/trip_creation_wizard_dialog_test.dart` —
  regression coverage for finding 1 (route/driver/price survive a rejected submit).
- **New visual captures**: `fleet_forms_visual_capture.dart` (new file, driver + vehicle
  forms), `trip_forms_visual_capture.dart` (new file, wizard + pricing dialog + cancellation
  dialog), plus two new Light Mode cases added to the existing
  `route_builder_visual_capture.dart`. All committed under each feature's `_captures/`.
