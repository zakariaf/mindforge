# E02 verification — the database opens on iOS

`flutter test` runs in a plain Dart VM against the **host** SQLite. It therefore
cannot prove that the store opens on a device at all, which is why this check is
run by hand on the canonical simulator and recorded here.

**Device.** `MindForge iPhone 14`, UDID `C13DDC02-375D-4E1B-8F81-44EB407D09A4`,
iOS 18.6. **Date.** 2026-08-19. **Bundle.** `com.mindforge.mindforge`.

```
xcrun simctl get_app_container C13DDC02-375D-4E1B-8F81-44EB407D09A4 \
  com.mindforge.mindforge data
```

## What was found

```
Library/Application Support/
  mindforge.sqlite        4096 bytes
  mindforge.sqlite-shm   32768 bytes
  mindforge.sqlite-wal   61832 bytes
```

`Application Support`, not `Documents` — deliberately, on two counts: it is
included in the iCloud and Finder device backup, and this database is the only
copy of a player's history; and it is not exposed through the Files app the way
`Documents` is under `UIFileSharingEnabled`.

The `-wal` and `-shm` sidecars are the proof that `PRAGMA journal_mode = WAL`
took effect on a **file** database, which an in-memory test cannot show — an
in-memory database reports `memory` and has no sidecars.

## Assertions, run against the file on disk

| Check | Result |
|---|---|
| `PRAGMA integrity_check` | `ok` |
| `PRAGMA journal_mode` | `wal` |
| Tables | `runs`, `settings` |
| Both declared `STRICT` | yes — both names returned by `sql LIKE '%STRICT%'` |
| Indexes | `ux_runs_client_key`, `idx_runs_game_difficulty_time`, `idx_runs_day` |
| Seeded settings row | `app\|1\|1\|0\|0\|NULL` — sound on, haptics on, reduce motion off, colour-blind off, **`locale_tag` NULL** |

`locale_tag IS NULL` on a fresh install is the one that matters for E04: NULL
means *follow the system locale*, and it is not the string `'en'`.

## The two SQLite versions, which are different libraries

| Where | Version |
|---|---|
| Host, used by `flutter test` | **3.44.3** |
| Bundled into the app by `package:sqlite3` 3.5.1 | **3.53.4** |

Both are comfortably above the 3.37 that `STRICT` tables require, and
`app_database_schema_test.dart` asserts that floor at runtime rather than
trusting it.

The bundled version is also the direct confirmation of E01's decision to drop
`sqlite3_flutter_libs`: the native library arrives through `package:sqlite3`'s
own build hook, exactly as that package's README says, and the deprecated
`0.6.0+eol` shim would have added nothing.

## Not checked, and not claimed

**Android.** No Android device was booted and no claim is made about one.
Android is deferred by decision; when it is picked up it is its own epic, and
this check is repeated there against its own container path.
