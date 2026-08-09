# 品牌资源

Tutuner 1.0 图标使用调音指针、六根琴弦与节拍脉冲构成统一标志，并采用应用内一致的深靛蓝、青色和紫色 Liquid Glass 视觉语言。

## 源文件

- `assets/branding/app_icon_1024.png`：iOS 等要求不透明、由系统应用蒙版的平台源图。
- `assets/branding/app_icon_rounded_1024.png`：带透明圆角的平台源图，用于 Android、macOS、Windows 和启动标志。

平台尺寸已经写入 Android `mipmap-*`、iOS/macOS Asset Catalog 和 Windows ICO。修改主图后必须重新派生所有尺寸，并至少检查 1024 px、192 px 和 48 px 三档效果。

## 生成方式

主图使用 Codex 内置图像生成工具制作，最终提示词为：

```text
Create a production app icon for Tutuner, combining an upward tuner needle,
exactly six vertical guitar strings, a circular tuner scale, and a subtle
metronome pulse. Use a premium iOS Liquid Glass style with a full-bleed opaque
midnight indigo background, cyan and violet glass, and one warm coral needle
accent. Keep a strong centered silhouette that remains legible at 48 px. No
text, letters, numbers, watermark, musical note, guitar body, border, or
pre-rendered platform mask.
```

公开发布前仍应执行商标近似性检索；图标视觉完成不等于商标注册或独占权确认。
