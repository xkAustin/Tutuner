# 平台构建与权限

## Android

- `minSdk` 使用 Flutter 当前默认值，满足 `record` 的 API 23+ 要求。
- 主清单包含 `RECORD_AUDIO` 与 `VIBRATE`，不包含 `INTERNET`。
- 构建要求 JDK 17 与 Android SDK；本项目使用 Gradle/AGP 的 Flutter 3.44 默认版本。
- Release 构建必须使用维护者提供的专用 keystore；缺少 `android/key.properties` 或任一必需字段时会安全失败，不会回退到调试签名。
- 配置模板与密钥管理要求见 [安全与隐私架构](security.md#android-正式签名)。

## iOS

- `Info.plist` 包含 `NSMicrophoneUsageDescription`。
- 真实设备运行或发布前，维护者必须在 Xcode 选择自己的 Team、Bundle ID 与签名证书。
- iOS 模拟器不能替代真实设备的麦克风延迟与触觉反馈验证。

## macOS

- `Info.plist` 包含麦克风用途说明。
- Debug/Profile 与 Release entitlement 均启用 `com.apple.security.device.audio-input`。
- Release entitlement 未加入网络客户端或服务端权限。
- 分发前仍需维护者配置 Developer ID 签名、公证与应用沙盒能力。

## Windows

- `record_windows` 通过 Windows Media Foundation 采集 PCM。
- Win32 桌面应用的麦克风隐私开关由 Windows“隐私和安全性 → 麦克风 → 允许桌面应用访问麦克风”控制。
- 构建需要 Visual Studio 2022 的“使用 C++ 的桌面开发”工作负载与 Windows 10/11 SDK。

## 需要真机完成的检查

- iOS 与 Android 首次授权、拒绝、永久拒绝和系统设置恢复授权
- 蓝牙/USB 音频设备插拔与来电/导航中断
- 四个平台的端到端音高延迟、低音 E2 噪声场景和实际硬件节拍抖动
- Android/iOS 正式签名、macOS 公证、Windows 安装包签名
