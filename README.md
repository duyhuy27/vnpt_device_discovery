# VNPT Device Discovery - Flutter Package

Thư viện Flutter chuyên dụng để dò tìm thiết bị VNPT trong mạng LAN theo cơ chế quét có kiểm soát. Package tập trung vào một nhiệm vụ duy nhất: nhận `VNPTNetworkContext`, sinh danh sách IP mục tiêu, probe cổng `40029`, phát hiện candidate theo từng phase và dừng sớm ngay khi phase hiện tại đã tìm thấy thiết bị.

## Cài đặt (Installation)

Thêm package vào `pubspec.yaml` bằng `path`, Git, hoặc pub.dev khi package đã được publish:

```yaml
dependencies:
  vnpt_device_discovery:
    path: ../vnpt_device_discovery
```

Sau đó chạy:

```bash
fvm flutter pub get
```

## Hướng dẫn sử dụng (Usage Guide)

Chỉ cần import một dòng:

```dart
import 'package:vnpt_device_discovery/vnpt_device_discovery.dart';
```

### 1. Chuẩn bị thông tin mạng (Network Context)

Package không tự lấy `localIp`, `subnet`, hay `subnetMask`. App host cần truyền vào rõ ràng (Nên sử dụng package `network_info_plus`):

```dart
final network = VNPTNetworkContext(
  localIp: '192.168.88.140',
  subnet: '192.168.88',
  subnetMask: '255.255.255.0',
);
```

### 2. Tạo request và chạy discovery

```dart
final discovery = VNPTDiscoveryEngine.standard();

final session = discovery.createSession(
  request: VNPTDiscoveryRequest.production(network),
);
```

### 3. Lắng nghe progress và event

```dart
session.progress.listen((progress) {
  print(
    '[${progress.phaseName}] '
    '${progress.probedTargets}/${progress.totalTargets} '
    'candidates=${progress.candidatesFound}',
  );
});

session.events.listen((event) {
  switch (event) {
    case VNPTDiscoveryStarted(:final plan):
      print('Start scan: totalTargets=${plan.totalTargets}, port=${plan.port}');

    case VNPTCandidateFound(:final device):
      print('Found candidate: ${device.ip}:${device.port}');

    case VNPTCandidateListUpdated(:final devices):
      print('Snapshot: ${devices.length} candidate(s)');

    case VNPTDiscoveryCompleted(:final result):
      print('Completed: ${result.devices.length} candidate(s)');

    case VNPTDiscoveryFailed(:final reason):
      print('Failed: $reason');
  }
});
```

### 4. Hủy scan khi cần

```dart
await session.cancel();
```

Khi hủy:
- Package dừng schedule probe mới.
- Các probe đang chạy được phép kết thúc trong giới hạn `portTimeout`.
- Nếu đang có candidate chưa phát snapshot cuối, package sẽ emit `VNPTCandidateListUpdated` trước khi emit `VNPTDiscoveryCompleted`.

## Public API

Các model và entry point chính:

- `VNPTNetworkContext`
- `VNPTDiscoveryRequest`
- `VNPTScanProfile`
- `VNPTDiscovery`
- `VNPTDiscoverySession`
- `VNPTDiscoveryStarted`
- `VNPTCandidateFound`
- `VNPTCandidateListUpdated`
- `VNPTDiscoveryCompleted`
- `VNPTDiscoveryFailed`

## Scan Strategy

Planner hiện tại là cố định và luôn chỉ probe cổng `40029`.

### Các phase mặc định

- `targeted`: `[133, 132, 134]`
- `nearbyExpanded`: `[133, 132, 134, local, local - 1, local + 1, 100, 101, 102]`
- `genericFallback`: `1..254`

### Quy tắc de-dup giữa các phase

- `nearbyExpanded` sẽ loại toàn bộ suffix đã xuất hiện trong `targeted`
- `genericFallback` sẽ loại toàn bộ suffix đã xuất hiện trong `targeted` và `nearbyExpanded`
- `totalTargets` được tính một lần ngay khi bắt đầu scan

### Quy tắc fallback runtime

- Chạy `targeted` trước
- Nếu `targeted` không tìm thấy candidate nào, chuyển sang `nearbyExpanded`
- Nếu `nearbyExpanded` vẫn không có candidate, chuyển sang `genericFallback`

### Quy tắc dừng

- Khi một phase tìm thấy candidate đầu tiên, package emit `VNPTCandidateFound` ngay lập tức
- Package vẫn tiếp tục scan hết các IP còn lại trong phase đó
- Sau khi phase kết thúc, nếu phase đó có ít nhất một candidate, package emit `VNPTCandidateListUpdated`
- Sau đó dừng toàn bộ discovery, không chạy các phase phía sau nữa

## Profiles

`VNPTScanProfile` chỉ ảnh hưởng tới default timeout và concurrency, không ảnh hưởng tới chiến lược phase:

- `production`: default cho môi trường app thật
- `test`: default nhanh, phù hợp automation và unit test
- `diagnostic`: default chậm hơn để debug

Bạn vẫn có thể override:

```dart
final request = VNPTDiscoveryRequest(
  network: network,
  profile: VNPTScanProfile.diagnostic,
  portTimeoutOverride: const Duration(milliseconds: 1200),
  concurrencyOverride: 4,
);
```

## Model kết quả

`VNPTDiscoveredDevice` đã được giữ ở mức tối giản:

```dart
class VNPTDiscoveredDevice {
  final String ip;
  final int port;
  final int? responseTimeMs;
  final DateTime firstSeen;
  final DateTime lastSeen;
}
```

`VNPTDiscoveryCompleted.result.devices` chỉ chứa candidate thực sự được tìm thấy, không chứa danh sách IP đã probe thất bại.

## Kiến trúc & Tính năng nổi bật

- `Focused by design`: chỉ giải quyết discovery VNPT qua `ip:40029`, không mở rộng sang enrichment hay fingerprinting.
- `Phase-based fallback`: ưu tiên các IP có xác suất cao trước, chỉ mở rộng khi phase trước không tìm thấy candidate.
- `Immediate candidate events`: emit `VNPTCandidateFound` ngay khi phát hiện thiết bị.
- `Milestone snapshots`: emit `VNPTCandidateListUpdated` ở phase boundary thay vì spam sau từng probe.
- `Stable progress model`: progress dùng `probedTargets` và `totalTargets`, dễ bind vào UI.
- `Low surface area`: API nhỏ, dễ maintain, phù hợp publish package và tích hợp vào app thực tế.

## Không nằm trong phạm vi của package

Package này không làm các việc sau:

- mDNS discovery
- hostname / MAC / vendor enrichment
- service hint / fingerprint / heuristic classification
- persistence / cache / local database
- generic network scan ngoài flow VNPT hiện tại

## Ví dụ (Example)

Ví dụ Flutter tối giản nằm tại thư mục [`example/`](example).

## Kiểm thử (Testing)

Package đã có test cho:

- planner de-dup giữa các phase
- phase fallback flow
- cancel behavior
- progress throttling
- nhiều candidate trong cùng phase, bao gồm tình huống LAN có `2`, `3`, `4` AIBox

Chạy test bằng:

```bash
flutter test
```

## Quyền hạn (Permissions)

Package không tự xin quyền hệ thống. Tuy nhiên app host có thể cần cấu hình quyền mạng tùy nền tảng:

- `Android`: bảo đảm app có quyền truy cập mạng nội bộ
- `iOS`: có thể cần mô tả Local Network Usage tùy cách app được đóng gói và chạy trong LAN

## Đóng góp & Phát triển

Dự án được xây dựng để phục vụ hệ sinh thái thiết bị VNPT với API nhỏ gọn, dễ kiểm thử và dễ publish. Nếu bạn muốn mở rộng thêm luồng discovery hoặc tinh chỉnh planner, hãy cập nhật cùng với test tương ứng để giữ hành vi ổn định.
