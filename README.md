# WiFi Location Switcher

<p align="center">
  <img src="App/AppIcon-1024.png" width="160" alt="WiFi Location Switcher icon">
</p>

一款轻量的 macOS 菜单栏应用，根据当前连接的 Wi-Fi 名称自动切换网络位置。你可以自定义 Wi-Fi 与网络位置的对应关系，让不同网络使用各自保存的 DNS、IP 等设置。

A lightweight macOS menu bar app that automatically switches Network Locations
based on the connected Wi-Fi name (SSID). Define your own Wi-Fi-to-location rules
to use the DNS, IP, and other settings saved in each Network Location.

[下载最新版 / Download the latest release](https://github.com/JasonsAuditores/wifi-location-switcher/releases/latest)

## 功能 / Features

- **自定义规则：** 添加多组 Wi-Fi → 网络位置对应关系。<br>
  **Custom rules:** Add multiple Wi-Fi → Network Location mappings.
- **默认位置：** 为未匹配的 Wi-Fi 选择可选的默认位置。<br>
  **Fallback location:** Optionally choose a location for unmatched Wi-Fi networks.
- **状态查看：** 在菜单栏查看当前 Wi-Fi 和正在使用的网络位置。<br>
  **Live status:** See the current Wi-Fi and active Network Location from the menu bar.
- **登录启动：** 可选择登录 Mac 后自动启动。<br>
  **Launch at login:** Optionally start the app when you log in.
- **本地保存：** 所有规则只保存在你的 Mac 上。<br>
  **Local storage:** All rules stay on your Mac.
- **稳定切换：** 等待 Wi-Fi 连接稳定后再切换，避免网络位置变更导致的短暂断连触发反复切换。<br>
  **Stable switching:** Waits for a stable Wi-Fi connection to avoid switching loops during brief disconnects.

**系统要求：macOS 13 或更新版本，支持 Apple 芯片和 Intel Mac。**<br>
**Requires macOS 13 or later. Supports Apple silicon and Intel Macs.**

## 安装与使用 / Installation and setup

1. 从[下载页面](https://github.com/JasonsAuditores/wifi-location-switcher/releases/latest)下载应用 ZIP 并解压。<br>
   Download and unzip the app ZIP from the [Releases page](https://github.com/JasonsAuditores/wifi-location-switcher/releases/latest).
2. 将 **WiFi Location Switcher.app** 移入“应用程序”。<br>
   Move **WiFi Location Switcher.app** to `/Applications`.
3. 打开应用，点击菜单栏中的路由器图标。<br>
   Open the app and click the router icon in the menu bar.
4. 允许定位服务权限，以便 macOS 提供当前 Wi-Fi 名称；应用不请求实际地理位置，也不上传这些信息。<br>
   Grant Location Services access so macOS can provide the current Wi-Fi name. The app does not request your physical location or upload this information.
5. 添加 Wi-Fi 与已有网络位置的对应规则，按需设置默认位置及登录启动。<br>
   Add rules using your existing Network Locations, then optionally set a fallback location and enable **Launch after login**.

当前社区版本尚未经过 Apple 公证，首次打开时 macOS 可能提示无法验证开发者。请确认下载来源后再决定是否打开。

The current community build is not Apple-notarized. macOS may show an
unverified-developer warning on first launch. Verify the download source before
deciding whether to open it.

## 本地构建 / Build locally

项目使用 Swift Package Manager，无需 Xcode 项目文件。需要 Apple 命令行工具或 Xcode，以及 Swift 5.9 或更新版本。

The project uses Swift Package Manager and does not require an Xcode project.
Apple Command Line Tools or Xcode with Swift 5.9 or later is required.

```bash
swift run SwitcherCoreSelfTest
chmod +x scripts/*.sh
scripts/build_app.sh
scripts/install_local.sh
```

应用和 ZIP 安装包输出到 `dist/`，同一份应用支持 Apple 芯片和 Intel Mac。

The app and ZIP archive are written to `dist/`. The build creates one universal
app for both Apple silicon and Intel Macs.

## 签名与公证 / Signing and notarization

如需减少公开分发时的安全提示，可使用 Apple Developer ID 证书签名并完成公证：

For normal public distribution, use an Apple Developer ID certificate and
notarize the result:

```bash
CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
APP_VERSION=1.0.0 scripts/build_app.sh

NOTARY_PROFILE="your-notarytool-profile" \
APP_VERSION=1.0.0 scripts/notarize_app.sh
```

没有 Apple 开发者账号也可以生成社区安装包，但首次打开时可能出现无法验证开发者的提示。

Without an Apple Developer account, GitHub Actions still creates an ad-hoc
signed ZIP. macOS may show an unverified-developer warning on first launch.

## 发布版本 / GitHub releases

推送更新或提交合并请求时会自动测试和构建。推送版本标签可自动创建下载版本；如果版本已经存在，则保留已发布的文件：

Pushes and pull requests run the test/build workflow. Pushing a version tag
creates a GitHub Release automatically; an existing release keeps its reviewed assets:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## 隐私 / Privacy

应用只读取当前 Wi-Fi 名称和 Mac 的网络位置名称。规则仅保存在本机，不包含统计追踪，不向外部服务器发送信息。

The app reads only the current Wi-Fi name and the Mac's Network Location names.
Rules are saved locally in UserDefaults. There is no analytics, network request,
or external server.

## 许可证 / License

MIT

## ☕ 赏我杯咖啡 / Buy me a coffee

如果这个小工具帮到了你，欢迎用支付宝赏我杯咖啡，支持后续维护。完全自愿，不影响任何功能的使用。谢谢你的支持！

If this app makes your day a little easier, feel free to buy me a coffee via
Alipay to support future maintenance. Donations are entirely optional and do not
unlock or restrict any features. Thank you!

<p align="center">
  <img src="docs/assets/alipay-donation.png" width="320" alt="支付宝收款码：赏我杯咖啡 / Alipay QR code: buy me a coffee">
  <br>
  支付宝扫码支持 / Scan with Alipay
</p>
