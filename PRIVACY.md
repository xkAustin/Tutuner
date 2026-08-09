# Tutuner 隐私说明 / Privacy Notice

生效日期 / Effective date: 2026-08-09

## 中文

Tutuner 是一款离线吉他调音器与节拍器。应用不要求账号，不包含广告、分析、遥测或第三方跟踪 SDK，也不会向开发者或第三方服务器发送个人数据。

### 麦克风

调音功能需要麦克风权限。麦克风采样仅在设备内存中用于实时计算音高、置信度和音量；采样与分析结果不会录制到文件、上传或用于识别用户。停止调音或应用进入后台后，当前录音会话会停止。

### 本地数据

参考音高、界面语言、主题、节拍器配置、收藏和自定义调弦等设置只保存在设备本地。卸载应用或清除应用数据会删除这些内容。Tutuner 不提供云端同步。

### 系统权限

用户可以随时在系统设置中撤销麦克风权限。权限被拒绝时，调音功能不可用，但节拍器和本地设置仍可使用。

### 联系与变更

隐私问题或安全问题请通过本仓库的 GitHub Issues 或 `SECURITY.md` 中的私密报告方式联系维护者。若未来版本增加联网或数据处理能力，本说明会在发布前更新。

## English

Tutuner is an offline guitar tuner and metronome. It requires no account and includes no advertising, analytics, telemetry, or third-party tracking SDK. It does not send personal data to the developer or third-party servers.

### Microphone

The tuner requires microphone access. Audio samples are processed only in device memory to calculate pitch, confidence, and signal level in real time. Samples and analysis results are not recorded to files, uploaded, or used to identify the user. The recording session stops when tuning stops or the app leaves the foreground.

### Local data

Reference pitch, language, theme, metronome configuration, favorites, and custom tunings are stored only on the device. Uninstalling the app or clearing its data removes them. Tutuner does not provide cloud synchronization.

### System permissions

Microphone access can be revoked at any time in system settings. If access is denied, the tuner is unavailable, while the metronome and local settings continue to work.

### Contact and changes

For privacy or security questions, contact the maintainers through GitHub Issues or the private reporting method in `SECURITY.md`. This notice will be updated before release if a future version adds networking or new data processing.
