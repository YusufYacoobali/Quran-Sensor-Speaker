# Quran Speaker BLE Protocol

This is the first app/ESP32 contract for the Quran Speaker prototype. BLE is used for pairing, status, playback control, motion-rule configuration, Wi-Fi provisioning, and upload preparation. Large audio bytes should move over Wi-Fi after provisioning.

## BLE Advertisement

- Device name prefix: `QuranSpeaker-`
- Example name: `QuranSpeaker-01`
- Advertise the primary service UUID below.

## GATT

| Purpose | UUID | Direction | Properties |
| --- | --- | --- | --- |
| Quran Speaker Service | `8f7a1000-4d3f-4a9f-9f2a-91e3b7c5a001` | n/a | primary service |
| Command RX | `8f7a1001-4d3f-4a9f-9f2a-91e3b7c5a001` | app to device | write, write without response |
| Event TX | `8f7a1002-4d3f-4a9f-9f2a-91e3b7c5a001` | device to app | notify |

## Framing

Each BLE write/notification contains one UTF-8 JSON object.

Keep BLE control messages small. The initial target is under 512 bytes per message. MP3 upload data is not sent through this protocol; use `upload.prepare` to create a Wi-Fi upload session.

## Command Envelope

App to ESP32:

```json
{
  "v": 1,
  "kind": "command",
  "id": "app-000001",
  "type": "status.get",
  "payload": {}
}
```

- `v`: protocol version. Current value is `1`.
- `kind`: always `command` from app to device.
- `id`: app-generated message ID. Device must echo it in the response.
- `type`: command type.
- `payload`: command-specific object.

## Response Envelope

Success:

```json
{
  "v": 1,
  "kind": "response",
  "id": "app-000001",
  "type": "status.get",
  "ok": true,
  "payload": {
    "batteryPercent": 84,
    "storageUsedPercent": 62,
    "wifiName": "Home Wi-Fi",
    "firmwareVersion": "0.2.0-dev",
    "isPlaying": true,
    "volume": 0.72
  }
}
```

Error:

```json
{
  "v": 1,
  "kind": "response",
  "id": "app-000001",
  "type": "status.get",
  "ok": false,
  "payload": {},
  "error": {
    "code": "unsupported_command",
    "message": "Command is not implemented"
  }
}
```

## Event Envelope

Device to app, not necessarily tied to a command:

```json
{
  "v": 1,
  "kind": "event",
  "id": "evt-000001",
  "type": "motion.detected",
  "payload": {
    "sensor": "pir",
    "ruleId": "entry",
    "active": true
  }
}
```

## Commands

### `status.get`

Request current device state.

Payload:

```json
{}
```

Expected response payload:

```json
{
  "batteryPercent": 84,
  "storageUsedPercent": 62,
  "wifiName": "Home Wi-Fi",
  "firmwareVersion": "0.2.0-dev",
  "isPlaying": true,
  "volume": 0.72,
  "currentTitle": "Surah Al-Mulk",
  "currentRange": "67:1-10"
}
```

### `playback.playRange`

Play a Quran surah/ayah range from device storage.

Payload:

```json
{
  "surah": 67,
  "fromAyah": 1,
  "toAyah": 10,
  "repeatCount": 3,
  "reciter": "mishary_alafasy",
  "volume": 0.72
}
```

### `playback.playUpload`

Play a custom uploaded file from device storage.

Payload:

```json
{
  "fileId": "upload-test-recitation",
  "repeatCount": 1
}
```

### `playback.pause`

Payload:

```json
{}
```

### `playback.resume`

Payload:

```json
{}
```

### `playback.next`

Payload:

```json
{}
```

### `playback.previous`

Payload:

```json
{}
```

### `playback.setVolume`

Payload:

```json
{
  "volume": 0.72
}
```

`volume` is a double from `0.0` to `1.0`.

### `motionRule.upsert`

Create or replace a motion rule.

Payload:

```json
{
  "id": "entry",
  "enabled": true,
  "trigger": "motion.detected",
  "action": {
    "type": "playRange",
    "surah": 1,
    "fromAyah": 1,
    "toAyah": 7,
    "repeatCount": 3,
    "volume": 0.55
  }
}
```

### `motionRule.delete`

Payload:

```json
{
  "id": "entry"
}
```

### `wifi.provision`

Send Wi-Fi credentials over BLE. The ESP32 should attempt connection and reply with status.

Payload:

```json
{
  "ssid": "Home Wi-Fi",
  "password": "example-password"
}
```

Expected response payload:

```json
{
  "connected": true,
  "ipAddress": "192.168.1.42",
  "uploadBaseUrl": "http://192.168.1.42"
}
```

### `upload.prepare`

Prepare a Wi-Fi upload session for one test file.

Payload:

```json
{
  "fileName": "test_recitation.mp3",
  "sizeBytes": 1048576,
  "mimeType": "audio/mpeg"
}
```

Expected response payload:

```json
{
  "uploadId": "up-000001",
  "method": "PUT",
  "url": "http://192.168.1.42/uploads/up-000001",
  "expiresInSeconds": 300
}
```

## Events

| Event | Meaning |
| --- | --- |
| `status.changed` | Battery, storage, Wi-Fi, or firmware status changed |
| `playback.changed` | Playback state changed |
| `motion.detected` | Motion sensor fired |
| `upload.progress` | Upload session status changed |
| `error.raised` | Device-side error not tied to a command |

## Error Codes

| Code | Meaning |
| --- | --- |
| `bad_json` | JSON could not be parsed |
| `bad_request` | Required field missing or invalid |
| `unsupported_version` | Protocol version is not supported |
| `unsupported_command` | Command type is unknown |
| `busy` | Device is temporarily busy |
| `storage_error` | Storage or SD card operation failed |
| `wifi_failed` | Wi-Fi connection failed |
| `playback_failed` | Audio playback command failed |
