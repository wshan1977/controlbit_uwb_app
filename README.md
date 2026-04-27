# ControlBit UWB App

Flutter Android app that turns a UWB-capable phone into a ranging tag,
replacing the **maUWB_DW3000** hardware tag. The phone pairs with the anchor
over BLE, exchanges UWB session parameters out-of-band, and starts a FiRa
Static STS ranging session via Android's native UWB stack.

## Features

- **BLE OOB handshake** — discovers and pairs with maUWB_DW3000 anchors,
  exchanges UWB addresses and session configuration.
- **Native UWB ranging** — uses `androidx.core.uwb` (FiRa Static STS) through a
  Kotlin platform bridge.
- **Live visualization** — distance gauge, AoA compass, distance sparkline,
  RSSI bar.
- **Session log** — ranging samples can be reviewed and exported.
- **Settings screen** — channel, preamble code, ranging interval, and other
  UWB session parameters.

## Architecture

```
lib/
├── app.dart              # MaterialApp shell
├── main.dart
├── ble/                  # BLE OOB protocol
│   ├── ble_codec.dart    # binary encode/decode for OOB payloads
│   └── ble_uuids.dart    # service/characteristic UUIDs
├── models/               # data classes (freezed)
├── screens/              # scan / ranging / log / settings
├── services/
│   ├── ble_service.dart           # GATT client
│   ├── uwb_service.dart           # platform-channel UWB client
│   ├── session_orchestrator.dart  # BLE ↔ UWB lifecycle
│   ├── permission_service.dart
│   └── log_service.dart
├── state/providers.dart  # Riverpod providers
├── uwb/                  # platform-channel models
└── widgets/              # gauges, compass, sparkline, rssi bar

android/app/src/main/kotlin/com/controlbituwb/app_uwb/
├── MainActivity.kt
└── uwb/UwbBridge.kt      # androidx.core.uwb wrapper
```

State management: **Riverpod**. Models: **freezed** + **json_serializable**.

## BLE OOB protocol

Custom 128-bit GATT service exposed by the anchor:

| UUID suffix | Characteristic     | Direction        | Purpose                          |
| ----------- | ------------------ | ---------------- | -------------------------------- |
| `…0001`     | Service            | —                | Primary service                  |
| `…0002`     | Anchor Info        | Read / Notify    | Anchor UWB address, capabilities |
| `…0003`     | Session Config     | Write            | Channel, preamble, STS key, …    |
| `…0004`     | Session State      | Read / Notify    | Idle / starting / ranging / err  |
| `…0005`     | Phone Address      | Write            | Phone's UWB short address        |

- Base UUID: `8E7A0000-4F2D-4D1E-9F6F-1B7D5C9A0000`
- Negotiated ATT MTU: **100** (SessionConfig is 32 B; default 23 is too small)
- Protocol version: `0x01` (major version must match anchor firmware)

## Requirements

- Android device with hardware UWB (e.g. Pixel 6 Pro+, Galaxy S21 Ultra+,
  Galaxy Note 20 Ultra, Xiaomi MIX 4)
- Android 13+ (`minSdk = 31`, `compileSdk = 36`)
- maUWB_DW3000-style anchor running compatible firmware

## Toolchain

- Flutter **3.41+** / Dart **3.7+**
- AGP **8.9.1+**, Gradle **8.11.1+**
- Kotlin/JVM target: 17
- `androidx.core.uwb:uwb:1.0.0-rc01` (forces compileSdk 36)

## Permissions

Declared in `AndroidManifest.xml`:

- `UWB_RANGING`
- `BLUETOOTH_SCAN` (`neverForLocation`), `BLUETOOTH_CONNECT`
- Legacy `BLUETOOTH`, `BLUETOOTH_ADMIN`, `ACCESS_FINE_LOCATION` (≤ Android 11)
- Required hardware features: `android.hardware.uwb`, `android.hardware.bluetooth_le`

## Build & run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # freezed/json
flutter run -d <android-device-id>
```

Tests:

```bash
flutter test
```

## License

TBD
