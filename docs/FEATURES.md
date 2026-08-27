# MyCove Mobile App — Feature Documentation

> Package `mycove` · application ID `com.zsolutionsit.mycove` · Firebase project
> `mycove-7f39c`. Formerly **MyCove**.
>
> Sibling docs: [`mycove-api/docs/FEATURES.md`](../../mycove-api/docs/FEATURES.md)
> · [`mycove-admin/docs/FEATURES.md`](../../mycove-admin/docs/FEATURES.md)

Flutter app serving two in-app roles: **residents** (bottom-tab shell) and
**security guards** (scan/log/dues tabs). Accounts are admin-created or
household-invited — there is no self-signup; every account completes first-login
setup through the in-app wizard.

---

## 1. Onboarding & account access

- **Welcome screen** (`welcome_page.dart`) — first-run landing; "Find Your
  Estate", "Log In", "I'm a Security Guard" entries.
- **Estate code gate** (`estate_code_page.dart`, `estate_found_page.dart`) —
  fresh installs validate an estate access code (`GET /estates/:code`) before
  anything else; shows name/address/resident count/photo preview; the device
  locks to the estate after confirmation so the code is never asked again.
- **Login** (`login_page.dart`) — phone + password, "remember me" (persisted
  refresh token), role-aware (guard tab pre-selected when entering as guard),
  wrong-role messaging ("This account is registered as a resident…").
- **Forgot password / OTP reset** (`forgot_password_page.dart`, `otp_page.dart`,
  `new_password_page.dart`, `password_reset_success_page.dart`) — phone → OTP →
  new password → success; single-use reset tokens, 10-minute OTP expiry; dev OTP
  surfaced when configured.
- **First-login wizard / force reset** (`force_reset_page.dart`) — two-step local
  wizard shown whenever an account has `mustResetPassword`:
  1. **Password** with live strength rules (≥8 chars, digit, uppercase) and
     confirmation match.
  2. Step two differs by origin:
     - **Admin-created accounts** → full *Complete Your Profile* form: avatar
       picker, full name, house address, vehicle plates (optional), email
       (optional), emergency-contact phone.
     - **Household-invited members** → focused *Almost Done* step: card showing
       who invited them and their inherited house, plus an **emergency-contact
       field**. Every person coming into the app adds an emergency contact during
       onboarding — invited or not.

  One submit to `POST /auth/complete-force-reset`, which also marks household
  invites ACCEPTED and clears the one-time access code.
- **Onboarding complete** (`onboarding_complete_page.dart`) — confetti success
  screen ("You're All Set!") with what's-next cards; taps straight into the ready
  app.

## 2. Security & sessions

- **Biometric unlock** (`biometric_unlock_page.dart`) — Face ID / Touch ID over a
  silently-restored session with PIN fallback; lifecycle-aware (only a genuine
  pause→resume triggers the lock).
- **Transaction PIN** (`set_pin_page.dart`, `authorization_sheet.dart`) — set +
  verify a PIN (argon2-hashed server-side) that authorizes sensitive actions.
- **Device/session management** (`manage_devices_page.dart`) — list all active
  sessions (platform, device name, last used) and revoke any remotely;
  refresh-token rotation is single-use with server-side blacklisting.
- **Logout** — unregisters this device's push token, revokes the refresh token,
  wipes local storage.

## 3. Resident features

- **Dashboard** (`dashboard_page.dart`) — personalized greeting, estate spotlight
  banner (`GET /spotlights/current`), wallet balance card, quick actions into the
  main flows.
- **Announcements** (`announcements_page.dart`, `announcement_detail_page.dart`)
  — paginated list + rich detail (markdown, image/video attachments), per-user
  read receipts.
- **Meetings** (`meetings_page.dart`, `meeting_detail_page.dart`) — upcoming/past
  list, agenda detail, stored meeting report with **read-aloud TTS playback**
  (play/pause/stop).
- **Community projects** (`projects_page.dart`, `project_detail_page.dart`) —
  progress detail (% funded, timeline), make and track **pledges**.
- **Polls** (`polls_page.dart`, `poll_card.dart`) — active polls, one vote per
  resident, results display.
- **Dues & levies** (`dues_page.dart`) — dues status (months paid/owing) with a
  "not liable" banner for invited household members; levy records and payment;
  payment initiation → verification → shareable **receipt**
  (`payment_page.dart`, `receipt_page.dart`; save to calendar).
- **Wallet** — balance + transaction history (dashboard card and history views).
- **Visitor passes** (`visitor_page.dart`, `visitor_create_page.dart`,
  `visitor_detail_page.dart`) — create passes (visitor name/phone plus an auto
  **fallback code** for manual gate entry), detail view, revoke; guards verify at
  the gate.
- **Complaints** (`complaint_page.dart`, `complaint_success_page.dart`,
  `complaint_log_page.dart`) — submit (category + description), success
  reference, personal complaint log.
- **Notifications** (`notifications_page.dart`) — in-app notification center,
  mark-all-read, deep-links by payload type.
- **Rules** (`rules_page.dart`) — community rules & regulations by section.
- **SOS** (`sos_page.dart`) — one-tap emergency dialing: estate security-desk
  phone, management office phone, and the resident's own **emergency contact**.
- **Household** (`household_page.dart`, `invite_resident_page.dart`) — members
  list (who joined, when); invite a resident by name+phone (generates a shareable
  8-char access code excluding look-alike characters); cancel pending invites;
  inviter-only policy (invitees can't chain invites); invited members show a
  "not billed for dues" banner (`duesLiable: false`).
- **Profile** (`profile_page.dart`) — identity card (initials avatar, phone,
  house), email display, vehicle plates, and the personal **emergency contact
  add/edit/remove dialog** (name optional, phone required; Remove clears it
  server-side via `PATCH /users/me`); emits `emergency_contact_updated`
  analytics distinguishing set / update / remove.
- **Utilities — electricity** (six wizard pages +
  `utility_wizard_stepper.dart`) — select DISCO → enter meter → verify (live
  name/address lookup) → confirm → amount → payment → success; saved meters;
  extended request timeouts for real VTpass/BuyPower vends.
- **Utilities — airtime** (`buy_airtime_page.dart`) — network picker, phone,
  amount, purchase + success screen.
- **Utility history** (`utility_history_page.dart`,
  `utility_purchase_success_page.dart`) — purchase history with month filter and
  "MyCove Balance" spend context; tapping any purchase opens its full **receipt**.
- **Purchase receipts** (`utility_receipt_page.dart`,
  `core/pdf/utility_receipt_pdf.dart`) — per-purchase receipt showing reference,
  status, date, customer details and, for electricity, the DISCO/meter, units,
  tariff, vend provider and the copyable **prepaid token**; downloadable as a
  branded PDF via the system share sheet (Save to Files) — available for every
  past purchase, not just the one just made.

## 4. Voice assistant

- **13 intents** (`voice_intent_parser.dart`): `buyElectricity`, `buyAirtime`,
  `checkBalance`, `transactionHistory`, `checkDues`, `duesMonthsPaid`,
  `electricitySpendByMonth`, `nextMeeting`, `lastMeetingReport`,
  `meetingDecisions`, `meetingActionItems`, `visitorCount`, `newUpdates` — with
  mishearing variants and false-positive guards ("am I going to the meeting" ≠
  nextMeeting).
- **Hybrid resolution**: purchase/balance/history intents call backend
  `POST /voice/prepare`; informational intents resolve fully client-side from
  already-loaded state.
- **TTS replies** with configurable per-platform voice selection
  (`voice_settings_page.dart`), plus spoken meeting-report playback from meetings.
- **Interaction logging**: every turn (transcript, matched keywords, parser trail)
  logged locally and batch-uploaded to `POST /voice/logs`; email export of logs.

## 5. Guard features

- **Pass verification** (`guard_scan_page.dart`, `guard_code_page.dart`,
  `guard_result_page.dart`) — camera scan or manual fallback-code entry; instant
  result: valid / expired / unknown.
- **Entry & exit recording** against the pass.
- **Access log** (`guard_log_page.dart`) — chronological gate activity feed.
- **Guard dues** (`guard_dues_page.dart`) — read-only view of the household's
  dues standing.

## 6. Cross-cutting capabilities

- **Push notifications (FCM)** — permission prompt, foreground local-notification
  rendering, background isolate handler, tap-navigation by payload type
  (`visitor`→passes, `payment`→dues, else notifications). Token lifecycle:
  fetched from Firebase and POSTed to `/push/register-token` on **every login and
  silent auto-login**; unregistered on logout.
- **Product analytics (Mixpanel)** — identify-on-login; events across auth
  (`login_success/failed`, `password_reset_completed`, `force_reset_completed`),
  payments, voice turns, guard scans, visitor actions, screen views, searches,
  and `emergency_contact_updated` (action: set/update/remove).
- **Resilient networking** — Dio client with bearer injection, single-flight 401
  refresh + retry, account-deactivated hard exit, dev LAN/tunnel base-URL
  override via `--dart-define=API_BASE_URL`.
- **Design system** — ChTheme/ChColors/ChTextStyles/ChResponsive scaling composed
  on top of the OS accessibility text-size setting.

## 7. Where things live

```
lib/
├── app.dart                  # MaterialApp composition, lifecycle, lock gate
├── main.dart                 # Firebase init, push/analytics bootstrap
├── core/
│   ├── network/              # ApiClient (Dio), token/biometric/estate storage
│   ├── push/                 # FCM PushService + background handler
│   ├── voice/                # intent parser, TTS/STT log storage
│   ├── analytics/            # Mixpanel wrapper
│   ├── router/app_router.dart# every route (auth + resident shell + guard shell)
│   └── theme/ widgets/       # design system + shared widgets
├── data/
│   ├── my_cove_api.dart      # one typed method per API endpoint
│   └── models/               # JSON model classes
├── features/
│   ├── auth/pages/           # welcome → estate code → login → OTP reset →
│   │                         # force-reset wizard → onboarding complete → biometric
│   ├── guard/                # scan, code entry, result, access log, dues
│   └── resident/             # all resident pages + shell/widgets
└── state/                    # Riverpod AppState + AppNotifier (all actions)
```

## 8. Recent changes

1. **Emergency contact for everyone during onboarding** — household-invited
   members no longer skip it: they walk a dedicated *Almost Done* step capturing
   an emergency contact (admin-created residents capture it inside the full
   profile step). Persisted via `complete-force-reset`.
2. **Self-service emergency contact** — editable/removable anytime from Profile;
   save requires a phone; dedicated Remove action clears it server-side;
   `emergency_contact_updated` analytics distinguishes set/update/remove.
3. **Rebrand to MyCove** — all `MyCove` naming replaced (`MyCove` display /
   `mycove` package / `myCove` identifiers): pubspec name, imports, classes,
   native runner names, web manifest/title, docs; `community_hub_api.dart` →
   `my_cove_api.dart`.
4. **New application ID `com.zsolutionsit.mycove`** — Android
   namespace/applicationId/Kotlin package directory, iOS/macOS bundle IDs
   (incl. RunnerTests), Linux APPLICATION_ID, Windows company strings.
5. **Firebase migration to new project `mycove-7f39c`** — fresh
   `google-services.json` / `GoogleService-Info.plist` installed and validated;
   the old `communityhub-55855` is no longer referenced anywhere.
6. **Utility purchase receipts + download** — API now returns meter/DISCO
   details on every purchase; new receipt screen (token + transaction details)
   reachable from history tiles and post-purchase success; PDF generation with
   share-sheet download (`pdf` + `printing` packages).