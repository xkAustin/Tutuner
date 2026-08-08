# 第三方依赖审查

审查日期：2026-08-08。版本由 `pubspec.lock` 锁定；下表记录直接依赖的解析版本、用途、平台覆盖与许可证。

| 依赖 | 用途 | 目标平台 | 许可证 |
|---|---|---|---|
| `record` 7.1.1 | PCM 麦克风流与权限请求 | Android / iOS / macOS / Windows | BSD-3-Clause |
| `flutter_soloud` 4.1.3 | 预加载、低延迟节拍音输出 | Android / iOS / macOS / Windows | MIT；SoLoud 核心为 zlib/libpng |
| `audio_session` 0.2.4 | Android/iOS/macOS 音频焦点与中断 | Android / iOS / macOS | MIT |
| `provider` 6.1.5+1 | 轻量状态注入与 `ChangeNotifier` 订阅 | 全部 Flutter 目标平台 | MIT |
| `shared_preferences` 2.5.5 | 本地设置、自定义调弦与收藏 | Android / iOS / macOS / Windows | BSD-3-Clause |
| `wakelock_plus` 1.7.0 | 节拍播放时可选防休眠 | Android / iOS / macOS / Windows | BSD-3-Clause |

选择依据：

- `record` 当前 PCM16 stream 功能在四个目标平台均受支持，原生后端分别使用 AudioRecord/AVFoundation/Media Foundation。
- `flutter_soloud` 在四端提供统一的内存预加载、并发播放与低延迟后端；节拍时间线未耦合到该插件，可按平台替换。
- 新代码使用 `SharedPreferencesAsync`，避免旧的同步缓存 API 与多 Isolate 缓存不一致。
- 移动端触觉反馈使用 Flutter SDK 自带的 `HapticFeedback`，不引入仅支持 Android/iOS 的额外插件。
- 安全审计以 `pubspec.lock` 的完整解析结果为准；发布日期、检查方式与限制记录在 [安全审计记录](security-audit-2026-08-08.md)。
- 未使用的 `integration_test` 已移除，避免 Android Debug 包带入 Guava 28.1、JUnit 4.12 和整套测试运行时。
- AndroidX 仍传递依赖 `com.google.guava:listenablefuture:1.0` 作为异步接口；它不是完整 Guava 28.1，已纳入下述 OSV 检查且无命中。
- 81 个锁定 Pub 包和 Android Debug 运行时的 89 个 Maven 坐标已于审查日批量查询 OSV，修复后无命中。
- Gradle 9.1.0 分发包使用官方 SHA-256 锁定；`pubspec.lock` 中所有托管包均来自 `https://pub.dev` 并带内容摘要。
- `flutter_soloud` 等包存在非安全性质的新版本；本次没有将普通依赖升级伪装成安全修复，保留已经过完整构建验证的锁定版本。

参考：

- https://pub.dev/packages/record
- https://pub.dev/packages/flutter_soloud
- https://pub.dev/packages/audio_session
- https://pub.dev/packages/provider
- https://pub.dev/packages/shared_preferences
- https://pub.dev/packages/wakelock_plus
