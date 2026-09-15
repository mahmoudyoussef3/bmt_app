# Captain · Splash

`lib/apps/captain/features/splash/presentation/screens/captain_splash_screen.dart` — shown by
`_CaptainAuthGate` (`main.dart:164`) only while the local session store is being read
(`CaptainSessionStore.readSession()` / `readPendingPhone()`, SharedPreferences).

**No backend calls.** Nothing to port. The Supabase session itself is restored by the SDK before the
first frame (`bootstrapFlavorApp` → `Supabase.initialize`), so the splash never waits on the network.
