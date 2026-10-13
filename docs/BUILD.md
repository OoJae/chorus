# Building and running Chorus

Every command assumes Flutter 3.47.7 and the Serverpod CLI 4.0.4 are on the
`PATH`. Paths are relative to the repository root.

Do not run `pub upgrade`, and do not `pub add` without a version: the pins in
the README are exact on purpose.

## Where the app finds the server

The app asks `getServerUrl()` (from `serverpod_flutter`) for the API address.
It answers in this order:

1. `--dart-define=SERVER_URL=...`, if it was given at build or run time. This
   always wins.
2. `apiUrl` in `assets/config.json`.
3. `http://localhost:8080/` (`10.0.2.2` on Android) if that file cannot be read.

`chorus_flutter/assets/config.json` is the scaffold's file and points at
`http://localhost:8080`. That is right for the web app and the macOS app on
the development machine and wrong everywhere else:

- **Web app served by the server.** The server answers
  `/assets/assets/config.json` itself with its own public API address
  (`chorus_server/lib/src/web/routes/app_config_route.dart`), so the bundled
  file is never read and no define is needed.
- **Android APK.** The bundled file is read, and `localhost` on a phone is the
  phone. Always pass `SERVER_URL`. The trailing slash is part of the value.

## Web SQLite assets

The local database cannot open in a browser without two files in
`chorus_flutter/web/`. They are committed. `serverpod_database` 4.0.4 opens
the database with `sqlite_async`'s default locations, which are exactly
`sqlite3.wasm` and `db_worker.js` beside `index.html`, so the names must not
change.

Each file must match the version resolved in `pubspec.lock`.

| File | Matches | Bytes | sha256 |
|---|---|---|---|
| `sqlite3.wasm` | `sqlite3` 3.7.1 | 757984 | `87c1869b533ea4b6daa1f4dc6aa7e9cf3dae6e6ea53f8ed57080c08eb5f64303` |
| `db_worker.js` | `sqlite_async` 0.14.5 | 227086 | `c28b6a65e7d62fc5da157a82da1506cf856d81613ea0cf385fdfe24e6827313e` |

Sources, downloaded 2026-10-13:

- https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.7.1/sqlite3.wasm
- https://github.com/powersync-ja/sqlite_async.dart/releases/download/sqlite_async-v0.14.5/db_worker.js

Both hashes equal the digests the release pages publish for those assets.

To check the committed files, or to fetch them again after a version change:

```sh
grep -A7 -E '^  (sqlite3|sqlite_async):' pubspec.lock | grep version
shasum -a 256 chorus_flutter/web/sqlite3.wasm chorus_flutter/web/db_worker.js

curl -L --fail -o chorus_flutter/web/sqlite3.wasm \
  https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-<version>/sqlite3.wasm
curl -L --fail -o chorus_flutter/web/db_worker.js \
  https://github.com/powersync-ja/sqlite_async.dart/releases/download/sqlite_async-v<version>/db_worker.js
```

The tag formats differ: `sqlite3-3.7.1` has no `v`, `sqlite_async-v0.14.5`
has one. If either version in `pubspec.lock` changes, replace the file and
update the table above in the same commit.

## Run locally

```sh
cd chorus_server
serverpod start
```

This generates code, starts the server on port 8080, applies pending
migrations and launches the Flutter app in the browser. No Docker is needed:
`config/development.yaml` sets `database.dataPath`, so Serverpod starts and
manages its own embedded PostgreSQL. The first start downloads the PostgreSQL
binaries.

To run a second copy of the app by hand while the server is up:

```sh
cd chorus_flutter
flutter run -d chrome
flutter run -d macos
```

## Build the web app into the server

```sh
cd chorus_server
serverpod run flutter_build
```

The script is defined under `serverpod: scripts:` in
`chorus_server/pubspec.yaml`. It deletes `chorus_server/web/app`, then runs
`flutter build web --base-href / --output ../chorus_server/web/app` in
`chorus_flutter`, cleaning and retrying once if the first build fails. The
server serves that directory at `/` when it exists, and a "build the app" page
when it does not.

After the build, check that both SQLite files were copied:

```sh
ls -l chorus_server/web/app/sqlite3.wasm chorus_server/web/app/db_worker.js
```

## Build the release APK against the Cloud API

```sh
cd chorus_flutter
flutter build apk --release \
  --dart-define=SERVER_URL=https://<id>.api.serverpod.space/
```

Replace `<id>` with the project's Cloud id. The APK is written to
`chorus_flutter/build/app/outputs/flutter-apk/app-release.apk`.

Things to know about this build:

- It is signed with the debug key (`android/app/build.gradle.kts` still has
  the scaffold's signing config). That is enough to install it by hand; it is
  not enough for a store.
- The application id is still the scaffold's `com.example.chorus_flutter`.
- The main manifest declares the `INTERNET` permission. Flutter adds it only
  to the debug and profile manifests, so without it a release build cannot
  reach the server at all.
- The main manifest also declares the `android.intent.action.TTS_SERVICE`
  query. From Android 11 the speech plugin finds no engine without it.
- `minSdk` is Flutter's default, 24. The highest minimum any plugin in
  `chorus_flutter/.flutter-plugins-dependencies` asks for is also 24
  (`flutter_tts`, `url_launcher_android`, `google_sign_in_android`,
  `sign_in_with_apple`), so it was not raised.

## Run on the phone

Install the release build over USB, with USB debugging on:

```sh
cd chorus_flutter
flutter install --release
# or
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Run from source against the Cloud API:

```sh
cd chorus_flutter
flutter devices
flutter run -d <device id> --release \
  --dart-define=SERVER_URL=https://<id>.api.serverpod.space/
```

Run from source against the server on the development machine. Either forward
the port over USB, so that `localhost` on the phone reaches the Mac:

```sh
adb reverse tcp:8080 tcp:8080
flutter run -d <device id> --dart-define=SERVER_URL=http://localhost:8080/
```

or put both on the same network and use the Mac's address:

```sh
ipconfig getifaddr en0
flutter run -d <device id> --dart-define=SERVER_URL=http://<mac address>:8080/
```

Not yet tried on our phone: both of these use plain `http`. If the app reports
that insecure connections are not allowed, use the Cloud address instead.

An Android emulator reaches the development machine at `10.0.2.2`, so pass
`--dart-define=SERVER_URL=http://10.0.2.2:8080/`; the bundled `localhost`
would point at the emulator itself.

The device clock matters: a merge is refused when a device is more than a
minute away from the server's time. Leave automatic date and time on.

## macOS

`macos/Runner/DebugProfile.entitlements` and `Release.entitlements` both
already carry `com.apple.security.network.client`, which is what the sandboxed
app needs to reach the server. Nothing was changed there.
