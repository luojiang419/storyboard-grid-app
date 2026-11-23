## 本次更新

- 递增到 `v1.0.0.107`，使用当前 `main` 源码重新编译 Windows 安装包并发布到 GitHub。
- 本次为维护发布：沿用上一版功能集合，包含故事板高清重绘、原图细节导出、第三方 Gemini 代理兼容、浅色导出修复和多宫格裁切编号优化。
- 保持自动更新契约不变：客户端继续从 `luojiang419/storyboard-grid-app-releases` 读取 Latest Release，并按 `StoryboardGridApp-Setup-<version>.exe` 选择安装包。
- 发布方式为本地编译后上传 GitHub Release，未使用 GitHub Actions 云端编译。

> Windows 安装包当前未使用公共代码签名证书，部分设备可能显示 SmartScreen 提示。
