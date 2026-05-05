# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`odoo_attendance` is an **Android-only** Flutter app for employee attendance check-in / check-out, integrated with the Odoo 17 backend that lives at the repo root (`d:\odoo17\server\`). It is a sub-project under `flutter/` of that backend repo, but independent in tooling — Flutter SDK, Gradle build, no shared dependencies with Python.

The app talks to upstream Odoo `hr.attendance` (extended in [tcs_erp/tcs_attendance_management_product/](../../tcs_erp/tcs_attendance_management_product/) — currently a near-empty scaffold inheriting `hr.attendance` and `hr.employee`). Check-in / check-out is just `employee_id` + UTC timestamp; no GPS, no face matching at this point.

**Windows desktop platform was deliberately removed** earlier in development. Don't add it back; if you regenerate platforms, target `android` only.

> Note: the project briefly had a Face ID feature (TFLite + MobileFaceNet + selfie audit). It was rolled back per product decision. If you see git history mentioning `face_match_service`, `face_capture`, `face_enroll`, `mobilefacenet.tflite` — those are gone. Do not re-introduce without product approval.

## Running and building

The Flutter SDK on this machine is at `D:\src\flutter\bin\flutter.bat` and is **not on PATH**. All Flutter commands must use the full path.

```powershell
# From repo root: d:\odoo17\server\flutter\odoo_attendance\
D:\src\flutter\bin\flutter.bat pub get
D:\src\flutter\bin\flutter.bat analyze
D:\src\flutter\bin\flutter.bat test
D:\src\flutter\bin\flutter.bat run                              # to attached Android device
D:\src\flutter\bin\flutter.bat clean                            # if Gradle native cache is stale
D:\src\flutter\bin\flutter.bat logs                             # tail device logs in another terminal
```

A typical build cycle is `clean → pub get → run`. Required when:
- AndroidManifest.xml or `build.gradle.kts` changed (manifest changes are NOT picked up by hot reload, **only full rebuild**).
- Native dependencies changed.
- Gradle cache is corrupted or `.dart_tool` is locked.

App id: `com.tcs.odoo_attendance`. minSdk: configured by Flutter SDK default (currently 21+); some plugins (`flutter_secure_storage` 10.x) actually need 23 — if you see runtime crashes about Keystore, bump `minSdk = 23` in [android/app/build.gradle.kts](android/app/build.gradle.kts).

## Backend connection (Odoo)

The Odoo server URL and database are **hard-coded** in [lib/app/core/constants/api_constants.dart](lib/app/core/constants/api_constants.dart). To switch environment (dev → prod) you edit this file and rebuild — there is no runtime config screen by design.

```dart
static const String odooBaseUrl = 'http://192.168.1.28:8069';
static const String odooDatabase = 'tcs_erp_01';
```

The local Odoo dev server typically runs on port **8069** with `http_interface = ` (bind all). Two side-effects to know:
- **Cleartext HTTP**: Android 9+ blocks `http://` by default. `android:usesCleartextTraffic="true"` is set in [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml). Do not remove unless deploying behind HTTPS.
- **Phone must be on same Wi-Fi as the PC** running Odoo. If `flutter run` succeeds but login times out, check Wi-Fi and Windows firewall (port 8069).

All RPC goes through [lib/app/data/providers/odoo_provider.dart](lib/app/data/providers/odoo_provider.dart) which wraps `/web/dataset/call_kw` and `/web/session/authenticate`. Session cookie is injected by [lib/app/services/api_service.dart](lib/app/services/api_service.dart) via Dio interceptor — don't manually set `Cookie` headers in callers.

Datetime helpers in [lib/app/data/models/attendance_model.dart](lib/app/data/models/attendance_model.dart): `parseOdooDateTime` (UTC string → local DateTime) and `formatOdooDateTime` (local → UTC string). Always use these — Odoo stores in UTC without TZ marker, raw `DateTime.parse` will misinterpret.

## Architecture: GetX, with two non-obvious gotchas

State management is GetX (`get: ^4.7.3`). Three patterns repeated across the app:

1. **Each screen has a `XController extends GetxController` + `XView extends GetView<XController>`**, registered as a `GetPage` with a `BindingsBuilder` in [lib/app/routes/app_pages.dart](lib/app/routes/app_pages.dart).

2. **Cross-controller dependencies happen via `Get.find<T>()` in `onInit`**. `HomeController` and `StatisticsController` `Get.find<ProfileController>()` to read `employeeId`.

3. **Reactive cross-tab updates via `ever()` watchers**. When `ProfileController.refreshProfile()` updates `employeeId`, dependent controllers' `ever<int?>(profile.employeeId, ...)` fire, triggering attendance fetches.

### Gotcha 1 — `Get.put` order in route bindings matters

```dart
// app_pages.dart — /home binding
Get.put(MainController());
Get.put(ProfileController());   // ← MUST come before HomeController
Get.put(HomeController());      //   because HomeController.onInit() Get.finds Profile
Get.put(StatisticsController());
```

Symptom of getting this wrong: `"ProfileController" not found. You need to call "Get.put..."` thrown during route transition. Comment in `app_pages.dart` documents this — preserve it.

### Gotcha 2 — `Get.lazyPut` doesn't run `onInit` if view never reads `controller`

Lazy-put controllers are only instantiated on first `Get.find` or via the `controller` getter on `GetView`. If a view body never accesses `controller`, the controller is never created, `onInit`/`onReady` never fires. We hit this with `SplashView` (which rendered logo + spinner only, no `controller` reference) and switched its binding to eager `Get.put`. Use `Get.put` for any controller whose lifecycle you need to start regardless of view access (timers, RPC fetches in onInit, etc.).

### Folder layout
```
lib/app/
├── core/
│   ├── constants/   api_constants.dart
│   └── theme/       app_colors.dart (TCS green/blue/red), app_theme.dart
├── controllers/     home_controller.dart (only Home tab uses this folder; others live next to their view)
├── views/           splash, onboarding, login, main (bottom nav wrapper),
│                    home, statistics, profile, personal_info, change_password
├── services/        api_service, storage_service, permission_service
├── data/
│   ├── models/      employee_model, attendance_model (+ datetime helpers)
│   └── providers/   odoo_provider.dart (the only RPC entry point)
├── widgets/         primary_button, app_text_field, tcs_logo,
│                    app_dialog (AwesomeDialog wrapper), app_notify (Flushbar wrapper)
├── bindings/        initial_binding.dart (services Get.put permanent at app start)
└── routes/          app_routes.dart, app_pages.dart
```

## Testing

Tests live in [test/widget_test.dart](test/widget_test.dart). The smoke test boots the full `OdooAttendanceApp` and verifies the Splash screen renders. Two non-obvious rules apply:

1. **`GetStorage.init()` needs `path_provider` mocked** in the test environment, because `flutter test` runs on the host (no native channel). The setup mocks `plugins.flutter.io/path_provider` to return a `Directory.systemTemp.createTempSync(...)` path. Do not delete this — without it, `GetStorage()` throws `MissingPluginException` and tests can't boot.

2. **Always tear down with `pumpWidget(SizedBox.shrink())` at the end of each test** so timers in `SplashController` (`Timer(400ms)`) and `HomeController` (`Timer.periodic(1s)`) get cancelled. Otherwise you get `A Timer is still pending even after the widget tree was disposed.`

## Avatar / image rendering quirk

`hr.employee.image_1920` returns base64 from Odoo, but the bytes are sometimes in a format Android's native `ImageDecoder` doesn't support (HEIC variants on certain employee uploads). Direct `Image.memory(base64Decode(...))` fails with `Failed to create image decoder with message 'unimplemented'`.

The fix in [lib/app/views/profile/profile_controller.dart](lib/app/views/profile/profile_controller.dart) `_fetchAvatar()`:
1. Fetches via Dio (`/web/image/hr.employee/{id}/image_512`) — gets binary with proper Content-Type.
2. Pipes bytes through `compute(_decodeAndReencode, ...)` — `image` package decodes any format and re-encodes as PNG.
3. PNG is what Android always handles — `Image.memory` then renders fine.

If you add a new place that displays employee photos, prefer this pattern (URL + image-package re-encode) over reading `image_1920` straight from RPC.

## UI conventions specific to this codebase

- **Vietnamese strings inline.** No i18n / `intl_translation` setup yet. All user-facing text is Vietnamese hard-coded.
- **`flutter_screenutil`** is used everywhere — `.w`, `.h`, `.sp`, `.r` extensions on numbers. Design size is `Size(390, 844)` (iPhone 14 baseline) set in `main.dart`. Don't write raw pixel values for layout.
- **Color tokens are derived from the TCS Tech logo** — see [lib/app/core/theme/app_colors.dart](lib/app/core/theme/app_colors.dart). Primary green `#16A34A`, accent blue `#2563EB`, error red `#DC2626`, warning amber `#F59E0B`. The 3 Lottie files in `assets/lottie/` have these RGB values baked in their JSON; if you change `AppColors.primary`, you must also edit the Lottie JSONs (or accept color mismatch).
- **`AppDialog.confirm` / `AppDialog.success` / `AppNotify.{success, error, info, warning}`** are the standard wrappers. Don't use raw `Get.dialog`/`Get.snackbar` — the wrappers ensure consistent styling.

## Navigation gotcha — Flushbar collides with Get.back

`AppNotify.*` uses `another_flushbar` which internally pushes an overlay route. Calling `Get.back()` immediately after triggers Navigator's `_debugLocked` assertion (`'!_debugLocked': is not true`).

Fix pattern:

```dart
Get.back<bool>(result: true);                                 // pop first
SchedulerBinding.instance.addPostFrameCallback((_) {
  AppNotify.success('...', '...');                            // notify after pop frame
});
```

Use this any time you need to both pop and notify. The notification shows on the destination screen — usually better UX anyway.

## Files NOT to commit

- `android/key.properties`, `*.jks` — release signing (not yet set up; debug keys in use).
- `build/`, `.dart_tool/`, `.flutter-plugins-dependencies` — generated.
- `pubspec.lock` is currently committed; keep it that way for reproducible builds.
