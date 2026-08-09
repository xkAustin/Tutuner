# 验证记录

环境：

- macOS / Apple Silicon
- Flutter 3.44.8
- Dart 3.12.2
- Xcode 26.6
- Android SDK 35/36
- JDK 17（Android 构建指定）

已执行：

- `dart format lib test`
- `flutter analyze`：通过，0 个问题
- `flutter test --no-pub`：29 项通过
  - YIN 合成采样：82.4069、110、196、329.6276、880、1396.91 Hz
  - 静音噪声门
  - 平滑与八度跳变抑制
  - 12-TET / 24-TET 频率与 cents
  - 固定锚点 10,000 事件时间线与恢复跳拍
  - Tap Tempo 异常间隔、误双击过滤及超时重开序列
  - 暂停保留拍位、继续接下一拍、停止复位
  - 节拍器拍号、细分、逐拍重音、声音与视觉开关可恢复并同步到控制器
  - 节拍器配置写入异步偏好后可由新的设置实例完整恢复
  - 琴弦最近目标选择、连续帧确认与相邻弦边界防抖
  - 停止请求作废延迟中的麦克风启动
  - 快速停止/重启严格等待前一录音会话结束
  - 停止后过期 Isolate 分析结果不可发布
  - `inactive`、`hidden`、`paused`、`detached` 均暂停音频
  - 窗口宽度反复跨越 840/1120 响应式导航断点
  - 800×600、1024×768、1280×800、1440×900、1920×1080 经典分辨率布局矩阵
  - Liquid Glass 内容区在宽屏下居中并限制为 1160 px，紧凑窗口无越界

- `flutter build macos --debug`：通过
- `flutter build apk --debug`：通过
  - 产物：`build/app/outputs/flutter-apk/app-debug.apk`
  - 使用 Android Debug 证书并通过 APK Signature Scheme v2 验证
  - Debug 包包含 Flutter 调试通信所需的 `INTERNET`；产品主清单只声明 `RECORD_AUDIO` 与 `VIBRATE`
- `flutter build apk --release --no-pub`（无签名配置负向测试）：按预期失败
  - 明确缺少 `storeFile`、`storePassword`、`keyAlias`、`keyPassword`
  - 未回退到 Android Debug 签名
- 依赖复检：82 个 Pub 包与 89 个 Android Maven 坐标经 OSV 查询无命中
- macOS 实际启动：通过
  - 麦克风 PCM 输入产生实时频率、目标音和 cents 读数
  - 调音器、节拍器、设置与调弦库统一 Liquid Glass 界面正常渲染
  - 调音器与节拍器在宽窗口使用双栏，在紧凑窗口自动切换单栏
  - 自动识弦、手动琴弦图选弦在桌面常用尺寸首屏可见
  - 设置页在宽屏使用两列玻璃卡片，避免全屏内容被横向拉伸
  - 特殊调弦页面顶部背景连续，无透明 AppBar 黑条
  - 系统语言为英文时默认显示英文
  - 最终构建连续进入/退出全屏 12 次，每次窗口均可恢复，进程持续运行且无辅助功能桥错误
  - 节拍器音频引擎初始化无错误，视觉拍点运行

macOS 27 的 Flutter 辅助功能桥在窗口重排语义树时存在原生崩溃路径。当前版本通过 `SafeFlutterViewController` 仅在 macOS 27 跳过该原生语义更新，避免调节窗口和全屏切换闪退；较早 macOS 版本仍转发完整语义更新。该兼容策略意味着 macOS 27 当前版本暂不向 VoiceOver 发布 Flutter 内容语义，待上游引擎修复后应移除。

真机麦克风、签名和实际声学/节拍抖动检查不能由单元测试或桌面运行替代，详见 `platform-setup.md`。
