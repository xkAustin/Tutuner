# 发布检查清单

本文将仓库内可自动完成的验证与必须由发布者提供身份、证书或实体设备的步骤分开，避免把 Debug 构建误报为正式发布完成。

## 已自动完成

- Dart 格式、静态分析和单元/组件测试由 `Flutter CI` 持续执行。
- Android 与 macOS Debug 源码构建已在本机验证，并由 CodeQL 手动构建再次覆盖。
- iOS 模拟器和 Windows Debug 构建由 `iOS and Windows Builds` 工作流持续验证。
- Java/Kotlin 与 Swift CodeQL 使用 manual build，完成源码捕获、分析和结果上传。
- Android Release 缺少任一签名字段时安全失败，不回退到 Debug 证书。
- Android、iOS、macOS 与 Windows 已替换 Tutuner 图标；Android/iOS 已配置品牌启动画面。
- 隐私说明、商店中英文文案、关键词、首版更新说明和截图顺序已经准备。

## 首次发布前必须确定

- [ ] 确认最终 Android Application ID 与 Apple Bundle ID。仓库当前值为 `com.tutuner.tutuner`；首次上架后不要随意更改。
- [ ] 确认应用名称和图标未侵犯现有商标。
- [ ] 确认隐私说明的公开 URL，并填写商店隐私问卷。
- [ ] 确定支持邮箱、网站或公开问题反馈入口。

## 需要开发者账号或密钥

- [ ] Android：创建独立上传密钥，配置 Play App Signing，在受控环境生成 AAB 并核对证书指纹。
- [ ] iOS：配置 Apple Team、Distribution 证书与 Provisioning Profile，归档并上传 App Store Connect。
- [ ] macOS：配置 Developer ID、Hardened Runtime、公证和 Gatekeeper 验证。
- [ ] Windows：使用受信任代码签名证书签名安装包或可执行文件。

密钥、证书私钥、密码和恢复材料不得写入仓库、Issue、构建日志或聊天内容。

## 需要实体设备

- [ ] Android 与 iPhone：首次允许、拒绝、永久拒绝、系统设置恢复权限。
- [ ] 六根空弦与 14 套内置调弦的真实声学识别，包含低音 E2 与噪声环境。
- [ ] 30、120、300 BPM 长时间输出抖动测量；分别检查扬声器、有线、蓝牙和 USB 音频。
- [ ] 后台、锁屏、来电/导航中断以及音频设备插拔。
- [ ] 移动端触觉反馈与防休眠行为。
- [ ] 从实际手机、平板和桌面构建生成商店截图。

## 已知限制

- macOS 27 暂时绕过 Flutter 原生语义更新以避免窗口缩放/全屏崩溃，因此该系统版本当前不发布 Flutter VoiceOver 内容语义。待上游修复后必须移除此兼容层并重新执行无障碍验收。
- Flutter 3.44.8 会提示 `app_settings` 尚未迁移到未来的 Built-in Kotlin。升级 Flutter 前复查插件兼容性。
