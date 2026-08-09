# Tutuner

Tutuner 是一款完全离线、无账号、无广告的跨平台吉他调音器与节拍器，使用 Flutter 与 Dart 构建，目标平台为 Android、iOS、macOS 和 Windows。

## 已实现

- `record` 提供四端单声道 48 kHz PCM 麦克风流
- 独立 Isolate 中运行的 YIN 基频检测，覆盖 60–1400 Hz
- RMS 噪声门、置信度过滤、中值/指数平滑、异常与八度跳变抑制
- A4 430–450 Hz 动态参考音高
- 稳定、平衡、灵敏三档调音置信度策略
- 正确的 24 平均律自由调音（每音级 50 cents）
- 标准调弦、14 套内置特殊调弦、带迟滞防抖的自动识弦与琴颈图手动锁弦
- 调弦搜索、收藏、自定义、编辑、删除和本地持久化
- 30–300 BPM 节拍器、Tap Tempo、8 套预设与自定义拍号
- 四分、八分、三连音、十六分细分；逐拍重音/普通/静音
- 预加载 PCM 节拍音、基于单调时钟固定锚点的无累积漂移调度
- 经典、木质、电子三套离线节拍音效
- 暂停保留拍位并从下一拍继续；停止清空拍位并从第一拍重启
- BPM、拍号、细分、逐拍重音以及声音/视觉开关均在本地持久化
- Tap Tempo 中值/加权过滤、误双击忽略与超时自动重开序列
- 声音、视觉、移动端触觉反馈和播放防休眠开关
- 中文、英文、默认跟随系统语言，支持升降号与浅色/深色/系统主题
- 全应用统一的 iOS Liquid Glass 视觉语言、玻璃控件与稳定响应式导航
- 调音器/节拍器按有效内容宽度切换单双栏，设置页宽屏两列，超宽窗口内容居中限宽
- 已覆盖 800×600、1024×768、1280×800、1440×900、1920×1080 经典布局尺寸
- 所有设置与用户数据只保存在本机，不请求网络权限
- 麦克风权限被永久拒绝后可从错误提示直接进入系统设置

## 开发

项目基于 Flutter 3.44.8 / Dart 3.12.2。

```text
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter run -d macos
```

Android 构建使用 JDK 17。首次运行调音器时，系统会请求麦克风权限。

## 文档

- [架构与实时音频](docs/audio-architecture.md)
- [平台构建与权限](docs/platform-setup.md)
- [第三方依赖审查](docs/dependencies.md)
- [安全与隐私架构](docs/security.md)
- [安全审计记录](docs/security-audit-2026-08-08.md)
- [验证记录](docs/verification.md)
- [品牌资源](docs/branding.md)
- [商店发布文案](docs/store-listing.md)
- [发布检查清单](docs/release-checklist.md)
- [隐私说明](PRIVACY.md)
- [漏洞报告与安全策略](SECURITY.md)

## 隐私

麦克风采样只在内存中用于实时音高分析，不写入文件、不上传，也不包含遥测、账号或广告 SDK。
