# History

## 2026-04-27 — Project bootstrap (Day 0)

### Done

**Project skeleton**
- Flutter Android 앱 신규 생성 (`name: app_uwb`, `package: com.controlbituwb.app_uwb`)
- 툴체인: Flutter 3.41+, Dart 3.7+, AGP 8.9.1+, Gradle 8.11.1+, Kotlin/JVM 17
- `androidx.core.uwb:uwb:1.0.0-rc01` 의존성 추가 → `compileSdk = 36` 강제, `minSdk = 31`

**Manifest / 권한**
- `UWB_RANGING`
- `BLUETOOTH_SCAN`(`neverForLocation`), `BLUETOOTH_CONNECT`
- 레거시 `BLUETOOTH`, `BLUETOOTH_ADMIN`, `ACCESS_FINE_LOCATION` (≤ Android 11)
- 필수 하드웨어: `android.hardware.uwb`, `android.hardware.bluetooth_le`

**Native UWB 브리지** — `android/.../uwb/UwbBridge.kt`
- MethodChannel `com.controlbit.app_uwb/uwb`
  - `isUwbAvailable`, `getRangingCapabilities`, `getLocalAddress`,
    `startRanging`, `stopRanging`
- EventChannel `com.controlbit.app_uwb/uwb/ranging`
  - `STARTED` / `RESULT(distance, azimuth, elevation)` /
    `PEER_DISCONNECTED` / `STOPPED` / `ERROR`
- `UwbControleeSessionScope` 기반 controlee 구현
- `RangingParameters` 빌더 분리 (rc01 기준; 필드 변경 시 한 곳만 수정)

**BLE OOB 프로토콜** — `lib/ble/`
- 커스텀 128-bit GATT 서비스, base UUID `8E7A0000-4F2D-4D1E-9F6F-1B7D5C9A0000`
- 캐릭터리스틱 5종: Service / AnchorInfo / SessionConfig / SessionState / PhoneAddress
- 협상 MTU = 100 (SessionConfig 32 B)
- `ble_codec.dart`: AnchorInfo(16B) decode, SessionConfig(32B) encode, SessionState(4B) decode
- 프로토콜 버전 `0x01`

**Flutter 레이어** — `lib/`
- 모델 (freezed): `anchor_device`, `anchor_info`, `uwb_session_config`,
  `ranging_sample`, `session_state`, `settings`
- 서비스: `ble_service`, `uwb_service`, `permission_service`,
  `log_service`, `session_orchestrator` (BLE ↔ UWB 라이프사이클)
- 상태: Riverpod 프로바이더 (`lib/state/providers.dart`)
- 화면: scan / ranging / settings / log
- 위젯: `aoa_compass`, `distance_gauge`, `distance_sparkline`, `rssi_bar`

**테스트**
- `test/ble_codec_test.dart` (BLE 인코더/디코더)
- `test/widget_test.dart`

**저장소**
- Git init → GitHub `wshan1977/controlbit_uwb_app` 리모트 연결
- `.claude/` 등 IDE 산출물 .gitignore 처리
- 커밋 2건:
  - `03eda8b` Initial commit: ControlBit UWB Flutter app
  - `051dc7e` docs: rewrite README with project overview, architecture, BLE OOB protocol

---

## TODO

### 단기 (다음 세션)

- [ ] 실제 디바이스(Pixel 6 Pro+/S21 Ultra+)에서 `flutter run` 빌드 검증
- [ ] `freezed`/`json_serializable` 코드 생성 확인 — `dart run build_runner build --delete-conflicting-outputs`
- [ ] `androidx.core.uwb:uwb:1.0.0-rc01` 실제 API 시그니처 vs `UwbBridge.kt` 가정 검증
  - `RangingParameters` 생성자 필드명 (`uwbConfigType` 등)
  - `RangingResult` sealed class 변종 (Position / PeerDisconnected / 그 외)
- [ ] `CONFIG_UNICAST_DS_TWR` 등 상수 위치 확인 (`RangingParameters` 내부 vs 별도 객체)
- [ ] 권한 런타임 요청 흐름 점검 (BLE_SCAN/CONNECT, UWB_RANGING)

### 중기 (펌웨어 합 맞추기)

- [ ] maUWB_DW3000 안커 펌웨어와 BLE OOB 와이어 포맷 교차검증
  - AnchorInfo 16 B / SessionConfig 32 B / SessionState 4 B 바이트 오프셋
  - 엔디안: 모든 멀티바이트 필드 little-endian
  - Phone short address 쓰기 타이밍 (SessionConfig write 전/후 어느 쪽이냐)
- [ ] 세션 키 (SessionConfig.sessionKey 8 B) 생성/배포 정책 확정
  - 현재는 폰이 정해 안커로 푸시한다고 가정 — 펌웨어 측 기대값 확인
- [ ] STS config 모드 (Static STS 0) 외 옵션 필요 여부

### 중장기

- [ ] AoA 활용 화면 개선 (compass UX, 신뢰도 표시)
- [ ] 거리 측정 로그 export (CSV/JSON)
- [ ] 다중 안커 (controller multiple) 지원 검토 — 현재는 unicast DS-TWR
- [ ] iOS/Nearby Interaction 백엔드 (장기) — 현재 코드는 Android 전용
- [ ] 안커 펌웨어용 BLE OOB 사양 문서를 별도 파일로 분리 (`docs/ble_protocol.md`)
- [ ] CI: `flutter analyze` + `flutter test` 워크플로 추가

### 알려진 한계

- iOS 코드 경로는 starter 그대로 — UWB 미구현
- `RangingResult.RangingResultPosition`의 `rssiDbm`은 현재 `null` 고정
  (rc01 API에서 RSSI를 직접 노출하지 않음 — RSSI 표시 위젯은 BLE RSSI 등 다른 소스 필요)
- Release 서명은 디버그 키 그대로 (`buildTypes.release.signingConfig = signingConfigs.debug`)
