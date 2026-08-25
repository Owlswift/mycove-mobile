# MyCove Mobile App — Architecture

> Flutter · package `mycove` · app ID `com.zsolutionsit.mycove`
>
> Feature inventory: [FEATURES.md](FEATURES.md) · API:
> [`communityhub-api/docs/ARCHITECTURE.md`](../../communityhub-api/docs/ARCHITECTURE.md)

## 1. System context

```
┌──────────────┐        ┌──────────────┐
│ Resident app │        │  Guard app   │      (same binary, role-selected shell)
└──────┬───────┘        └──────┬───────┘
       └───────────┬───────────┘
                   │ HTTPS + JWT (Dio)
            ┌──────▼───────┐        ┌─────────────────────────────┐
            │  MyCove API  │──────▶ │ PostgreSQL (Prisma)         │
            │ (NestJS :80) │──────▶ │ Firebase Admin → FCM pushes │
            └──────────────┘──────▶ │ Mixpanel (server events)    │
                                    │ VTpass / BuyPower vending   │
┌──────────────┐                    └─────────────────────────────┘
│ Admin web UI │ ── same API (separate repo)
└──────────────┘
   ▲ FCM pushes delivered by Google, tokens registered by this app
```

The mobile app talks **only** to the MyCove API — payment processors and vending
providers are reached server-side, never from the device.

## 2. Layering

Strict one-directional layering; nothing below a layer reaches upward:

```
features/*/pages (widgets)
      │ watch/read providers
state/  AppState (immutable) + AppNotifier (StateNotifier — every mutation)
      │ typed methods
data/my_cove_api.dart  (one method per endpoint, returns decoded JSON;
      │ models parsed at call sites)
core/network/api_client.dart  (Dio singleton + interceptors + storage)
```

- `AppState` is an immutable data class mutated only through
  `state = state.copyWith(...)` inside `AppNotifier` (~60 action methods).
- `MyCoveApi` has no business logic — it is the typed surface of the HTTP API.
- Widgets never call Dio directly.

## 3. Navigation as a state machine

`AuthStage` (`app_state.dart`) is the single source of routing truth:
`bootstrapping → welcome → estateCode → estateFound → login → (otp/newPassword/
resetSuccess | forceReset → onboardingComplete) → app`, plus `locked` for the
biometric gate. `go_router`'s global redirect maps the current stage to its path
and forces users back onto it; once `authStage == app`, role decides between the
`/resident` and `/guard` `StatefulShellRoute.indexedStack` shells (per-tab
IndexedStack keeps tab state alive). The two wizard steps of first-login stay on
one route (`/force-reset`) as local `_step` state — no extra auth stages.

## 4. Networking & session storage

- **ApiClient** is a process-wide singleton exposing one configured `Dio`.
- Interceptors, in order: inject `Authorization: Bearer` from secure storage;
  on 401 (non-auth endpoints) run a **single-flight refresh** (concurrent 401s
  share one `Future`) then replay the request with a `retriedAfterRefresh` guard;
  on `ACCOUNT_DEACTIVATED` error code wipe tokens + estate storage and hard-exit
  to the estate-code screen via a callback.
- **Base URL resolution**: `--dart-define=API_BASE_URL` override → LAN dev
  constant → default.
- **Storage split**: access token always persisted for the session; refresh
  token only when "remember me"; estate code/name/address/lock flag in their own
  storage; biometric-enabled flag separate again.
- Bootstrap order on launch: estate storage read → silent auto-login (`GET
  /users/me`) → bootstrap data fan-out → enter app (biometric lock optional).

## 5. Push pipeline

1. `main.dart`: `Firebase.initializeApp()` reads the native config files
   (`google-services.json` / `GoogleService-Info.plist`) — no Dart-side options.
2. `PushService.initialize()` creates the Android channel, requests permission,
   wires foreground/tap/background listeners. Best-effort: without Firebase
   configs everything no-ops.
3. Tokens are fetched (`getToken()`) and POSTed to `/push/register-token`
   **on every successful login and silent auto-login**, unregistered on logout —
   so changing Firebase projects self-heals without token migration.
4. Foreground pushes render through `flutter_local_notifications`; taps route by
   `data.type`.

## 6. Voice subsystem

`speech_to_text` captures a turn → `VoiceIntentParser` matches it against
keyword tables into one of 13 `VoiceIntent`s (recording *why*: matched keywords,
amount, network, month) → resolution is hybrid: transactional intents POST to
`/voice/prepare`, informational intents are computed client-side from loaded
state → reply spoken via `flutter_tts`. Every turn is logged locally
(`voice_log_storage`) and batch-uploaded to `/voice/logs`; meeting reports play
back through TTS with pause/resume state.

## 7. Analytics

`AnalyticsService` wraps the Mixpanel Flutter SDK: identify-on-login,
fire-and-forget init (never blocks startup), events across auth/payments/voice/
guard/visitor/screen/search flows. Token injected at build time via
`--dart-define=MIXPANEL_TOKEN`.

## 8. Third-party integrations

### External services

| Service | Purpose | Where | Configuration |
|---|---|---|---|
| **Firebase Cloud Messaging** | Push notifications (token registration, message delivery) | `main.dart`, `core/push/push_service.dart` | Native config files: `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` (project `mycove-7f39c`) — no Dart-side options |
| **Mixpanel** | Product analytics (client-side events) | `core/analytics/analytics_service.dart` | Token via `--dart-define=MIXPANEL_TOKEN`; no-op when absent |
| **MyCove API** | All business data & actions | `core/network/`, `data/my_cove_api.dart` | Base URL: `--dart-define=API_BASE_URL` → LAN constant |

> Payment processing (Paystack interface) and electricity/airtime vending
> (VTpass/BuyPower) are integrated **server-side only** — the app never talks to
> them directly; it only sees the API's initiate/verify/receipt surface.

### Plugin stack (what each is for)

| Plugin | Role in the app |
|---|---|
| `dio` | HTTP client behind ApiClient (interceptors, per-request timeouts) |
| `flutter_riverpod` | State management (`StateNotifier` + providers) |
| `go_router` | Declarative routing driven by the `AuthStage` state machine |
| `flutter_secure_storage` | Access/refresh tokens on device |
| `firebase_core` / `firebase_messaging` | Firebase init + FCM |
| `flutter_local_notifications` | Foreground push rendering + Android channel |
| `local_auth` | Face ID / Touch ID biometric gate |
| `speech_to_text` | Voice-command capture |
| `flutter_tts` | Spoken replies + meeting-report read-aloud |
| `google_fonts` | Brand typography bundle |
| `intl` | Naira/date formatting |
| `video_player` | Announcement/project media playback |
| `share_plus` | Share receipts/passes |
| `add_2_calendar` | Save meeting/receipt events |
| `flutter_markdown` | Rich announcement/report bodies |
| `path_provider` | Local file paths (logs, media cache) |
| `device_info_plus` / `package_info_plus` | Session device names, analytics context |
| `iconsax_flutter` | Icon set |

## 9. Build targets & native notes

- **Android**: `namespace`/`applicationId = com.zsolutionsit.mycove`; Kotlin
  `FlutterFragmentActivity` subclass (required by local_auth's BiometricPrompt);
  google-services Gradle plugin applied only when `google-services.json` exists;
  cleartext HTTP enabled for dev against a LAN IP.
- **iOS**: bundle id `com.zsolutionsit.mycove`; ATS exception for dev IPs;
  usage descriptions for Face ID, microphone, speech recognition.
- **macOS / Linux / Windows**: desktop runners carry matching product/bundle
  names; same feature set where plugins support it.
- **Web**: manifest/title branded; used mainly as a dev target.