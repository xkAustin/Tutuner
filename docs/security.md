# 安全与隐私架构

## 产品边界

Tutuner 是纯离线应用：没有账号、后台服务、遥测、广告 SDK、WebView 或产品网络客户端。Android 主清单不申请 `INTERNET`；macOS Release entitlement 不开放网络客户端或服务端权限。

麦克风权限由操作系统控制。调音开始后，`record` 输出单声道 PCM 流，Dart 侧只在内存中完成噪声门、YIN 基频检测、平滑和琴弦识别。应用不会将原始或派生音频写入文件、偏好设置或网络。停止调音、应用进入任意非 `resumed` 生命周期状态或控制器销毁时，会立即作废当前会话，并按顺序停止录音与处理订阅；过期的异步启动和 DSP 结果不能恢复监听或回写状态。

## 信任边界与安全属性

| 边界 | 主要风险 | 必须保持的属性 |
|---|---|---|
| 系统麦克风 → 原生插件 → Dart | 未授权采集、离开页面后继续采集、音频外泄 | 先授权、随生命周期停止、仅内存处理 |
| 内置资源/本机偏好 → 解析与状态恢复 | 异常数据导致不可用或资源消耗 | 内置资源随应用签名交付；偏好数据不形成跨用户授权边界 |
| 构建环境 → 发布包 | 调试密钥签署正式包、密钥进入仓库 | Release 使用独立密钥；配置缺失时失败；密钥文件被忽略 |
| 依赖与构建工具 → 应用二进制 | 供应链漏洞或恶意更新 | 锁定解析版本、审查直接依赖、发布前检查公开漏洞信息 |
| 平台清单/entitlement → 系统能力 | 多余网络、后台或导出能力 | 只声明麦克风、必要触觉和沙盒能力 |

## Android 正式签名

正式包不再使用 Gradle 调试签名。创建发布密钥后，将 `android/key.properties.example` 复制为 `android/key.properties`，填写四项配置：

```properties
storeFile=/absolute/path/to/tutuner-release.jks
storePassword=<secret>
keyAlias=tutuner
keyPassword=<secret>
```

`android/key.properties`、`*.jks` 和 `*.keystore` 已被忽略。CI 应从机密存储临时生成这些内容，构建结束后销毁临时文件。不要把真实路径、密码、证书或密钥写入日志、Issue、构建产物或仓库。

执行任何包含 `release` 的 Gradle/Flutter 构建任务时，只要配置文件缺失或字段为空，构建就会立即失败。Debug 构建仍使用本机 Android 调试密钥。

Gradle Wrapper 同时固定版本和官方分发包 SHA-256；Pub 解析版本及包内容摘要由 `pubspec.lock` 固定。发布构建应使用已审计的锁文件，不应在同一次发布任务中隐式升级依赖。

发布前还必须核对签名证书指纹，并将 keystore 与恢复材料保存在受访问控制且有离线备份的位置。首次公开发布后不得随意更换应用签名身份。

## 平台发布要求

- Android：使用专用上传/应用签名密钥，检查证书指纹及商店签名设置。
- iOS：在 Xcode 配置 Team、唯一 Bundle ID、Distribution 证书和 Provisioning Profile。
- macOS：使用 Developer ID 签名、启用 Hardened Runtime，并完成公证与 Gatekeeper 验证。
- Windows：为安装包或可执行文件配置受信任代码签名证书，并在干净系统验证安装来源提示。

## 安全验证范围

源码审计覆盖 Dart 业务逻辑、四个平台 runner 与权限、音频数据流、本地持久化、依赖清单、资产和构建配置。生成目录、版本控制内部文件和本机密钥不属于源码审计对象。物理设备权限流程、商店签名/公证和真实声学输入属于发布验收，不能由桌面单元测试替代。

具体审计结论和执行证据见 [安全审计记录](security-audit-2026-08-08.md)，安全漏洞报告规则见仓库根目录 [SECURITY.md](../SECURITY.md)。
