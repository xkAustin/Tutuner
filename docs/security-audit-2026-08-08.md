# 安全审计记录（2026-08-08）

## 结论

本次审计覆盖 Tutuner 当前仓库的 Dart/Flutter 源码、Android/iOS/macOS/Windows runner、权限与 entitlement、签名配置、资源文件、本地持久化、Pub 与 Android Maven 依赖以及拟提交文件中的敏感信息。由于当前会话没有可调用的 Codex Security 扫描服务，审计按提示词降级流程执行：独立完成资产与信任边界建模、三轮候选发现、逐项可达性验证、攻击路径分析、修复和复检。

确认的麦克风生命周期问题已修复；两个供应链防御缺口也已关闭。修复后未发现仍可报告的安全漏洞。这里的“未发现”只适用于下述源码与本机构建范围，不替代真机权限、商店签名、公证或未来依赖状态的持续检查。

## 威胁模型

需要保护的资产包括麦克风隐私、发布包身份、本地设置完整性、平台沙盒边界和可预测的实时处理。主要边界与攻击面如下：

- 操作系统麦克风权限、原生 `record` 插件和 Dart PCM 分析链路；
- Flutter 生命周期、异步录音启动/停止和 DSP Isolate 之间的并发边界；
- Android launcher activity、Apple entitlement、Windows runner 与系统能力声明；
- 应用签名资源、Android keystore 配置和构建环境；
- Pub、Maven、Gradle 分发服务与本地构建产物；
- 已签名内置资源和应用私有偏好设置进入解析器的路径。

假设攻击者可以提供任意声学输入、诱导快速切换应用生命周期、影响公开依赖基础设施，或分发被替换的安装包。已经以同一用户权限直接修改应用私有偏好数据的进程不视为新的授权边界；这类损坏仍作为可靠性问题检查，但不单独上升为安全漏洞。

## 已确认并修复的问题

### TT-SEC-001：异步麦克风启动可越过停止/后台请求

- 严重度：中
- 类型：CWE-362（并发执行中的共享资源竞态）
- 影响：录音权限或设备初始化尚未返回时，用户切离调音器或应用进入非活动状态，旧的 `start()` 完成结果可能重新把控制器置为监听状态。旧 DSP 结果也可能在停止后回写界面。
- 根因：启动、停止和分析任务没有共享的会话世代；生命周期只处理 `paused` 与 `detached`，未覆盖 `inactive` 和 `hidden`。
- 修复：所有录音转换按顺序执行；每次开始/停止递增会话世代；过期启动会立即停止输入；样本监听和 Isolate 结果只允许写入当前会话；销毁时先作废会话再停止并释放录音器。所有非 `resumed` 生命周期状态都会停止调音并暂停节拍器。
- 回归证据：测试覆盖“停止作废延迟启动”“快速停止后重启等待前一停止完成”“停止后旧分析结果不可发布”以及五种 Flutter 生命周期状态。

## 已修复的供应链防御项

### 未使用测试依赖进入 Android Debug 运行时

`integration_test` 没有对应测试文件，却被 Flutter 注册到 Android Debug 运行时，连带引入 Guava `28.1-android` 与 JUnit `4.12`。OSV 分别命中 `GHSA-5mg8-w23w-74h3`、`GHSA-7g45-4rm6-3mm3` 和 `GHSA-269g-pwp5-87pp`。审计未找到应用调用相关临时文件 API 的攻击路径，而且该依赖仅用于开发，因此不判定为可利用的产品运行时漏洞；但这些类不应存在于应用包中。

已删除未使用的 `integration_test` 依赖。复检后的 Android Debug 运行时图不再包含 `integration_test`、Guava `28.1-android` 或 JUnit `4.12`。AndroidX 仍按设计传递依赖仅含异步接口的 `com.google.guava:listenablefuture:1.0`；它不是 Guava `28.1-android`，已纳入 Maven OSV 查询且无命中。

### Gradle 分发包缺少独立完整性锁定

Gradle Wrapper 原本只通过 HTTPS 获取 `gradle-9.1.0-all.zip`。现已在 `gradle-wrapper.properties` 中加入 Gradle 官方公布的 SHA-256：

```text
b84e04fa845fecba48551f425957641074fcc00a88a84d2aae5808743b35fc85
```

这不是已验证的仓库入侵路径，但能在分发服务、代理或缓存被篡改时提供独立的内容校验。

## 验证为不可报告或未发现问题的区域

- 网络与数据外传：产品 Dart 代码没有 HTTP、socket、WebView、文件写入或遥测路径。Android 主清单没有 `INTERNET`；Debug/Profile 为 Flutter 调试通信添加该权限。macOS Release entitlement 不含网络能力。
- 音频数据：PCM 只进入固定大小的内存帧和 Isolate；未写入偏好、文件或网络。停止、非活动生命周期和销毁会作废当前会话。
- Android 组件：唯一对外 activity 是标准 `MAIN`/`LAUNCHER` 入口，不解析外部 URI 或自定义参数。AndroidX provider 未导出；Profile Installer receiver 受系统 `android.permission.DUMP` 保护。
- 发布身份：Android Release 在四项签名配置缺失时构建失败，不回退到调试签名；真实 keystore、`key.properties`、`*.jks` 和 `*.keystore` 均被忽略。Apple 与 Windows 正式签名仍需发布者在受控环境完成。
- 平台沙盒：macOS Release 仅启用应用沙盒和麦克风输入；Debug 的 JIT、调试服务和网络服务权限不进入 Release entitlement。
- 本地数据：仅持久化用户设置、自定义调弦和收藏，不包含账号、令牌、音频或其他敏感数据。直接篡改同一用户私有存储不跨越新的权限边界。
- 资源处理：音频帧固定为 8192 样本，DSP 频率范围固定为 60–1400 Hz；用户界面将自定义调弦限制为 1–12 根弦。内置 JSON 与 WAV 随签名应用交付并已验证结构/格式。
- 敏感信息：拟提交文件未发现私钥、keystore、访问令牌、密码或真实签名配置；示例占位值不构成秘密。

## 依赖检查

- `pubspec.lock` 中 81 个 `pub.dev` 托管包均带内容 SHA-256；2026-08-08 OSV 批量查询无命中。
- 移除未使用测试依赖后，Android Debug 运行时解析出的 89 个唯一 Maven 坐标经 OSV 批量查询无命中。
- 直接依赖许可证文件均存在；用途、版本和许可证见 [第三方依赖审查](dependencies.md)。
- `flutter pub outdated --no-dev-dependencies` 显示少量可升级版本；没有 OSV 安全公告，因此本次保留已经构建和测试的锁定版本，避免把普通升级混同为安全修复。

## 执行证据

最终交付前执行并通过：

- `flutter pub get --offline --enforce-lockfile`
- `dart format --output=none --set-exit-if-changed lib test`
- `flutter analyze --no-pub`
- `flutter test --no-pub`（27 项）
- `flutter build macos --debug --no-pub`
- `flutter build apk --debug --no-pub`
- APK 清单、签名证书和导出组件检查
- macOS 应用严格代码签名验证与 entitlement 检查
- Apple plist/entitlement 语法、14 套调弦 JSON 和 9 个 PCM WAV 资源校验
- Pub 与 Maven OSV 批量查询
- 拟提交文件敏感信息与忽略规则复检

Android Release 无签名配置的负向测试按预期失败，并明确列出缺少的四项配置；这证明门禁生效，不代表已经生成或验证正式发布包。

## 尚需发布环境完成

- Android/iOS 真机的首次授权、拒绝、永久拒绝和设置恢复流程；
- 来电、锁屏、蓝牙/USB 设备插拔及厂商后台策略；
- Android/iOS 正式签名、macOS Developer ID 公证与 Gatekeeper、Windows 安装包签名；
- 四个平台真实硬件上的音高延迟、低音 E2 噪声场景和节拍抖动测量；
- 每次发布前重新查询依赖漏洞与审阅平台权限。
