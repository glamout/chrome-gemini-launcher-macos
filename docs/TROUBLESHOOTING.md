# Troubleshooting / 故障排查

## Chrome says Gemini is not available in this location

1. Quit Chrome completely with `Cmd+Q`. Closing the last window is not enough.
2. Start the configured proxy and confirm it uses the intended exit region.
3. Start Chrome with `chrome-gemini start` or the generated Dock launcher.
4. Open `chrome://version` and verify the region and proxy flags in the
   **Command Line** row.
5. In Chrome's Gemini settings, disable precise location if IP-based location
   is intended.

Chrome, Google account, device, IP, and server-side eligibility can all affect
availability. This launcher cannot override account or server-side controls.

## Chrome reports that it is already running

Use `Cmd+Q`, wait for Chrome to disappear from the Dock's running indicators,
and try again. Consider disabling Chrome's “continue running background apps”
setting.

Flags cannot reliably be added to an existing Chrome main process.

## The local proxy warning appears

Run:

```bash
chrome-gemini doctor
```

Confirm `PROXY_SERVER` matches the listening port in the proxy application.
There is no mandatory port. Configure one explicitly or use the system proxy:

```bash
chrome-gemini configure --proxy-server http://127.0.0.1:7897
chrome-gemini configure --proxy-server http://127.0.0.1:7890
chrome-gemini configure --proxy-server socks5://127.0.0.1:1080
chrome-gemini configure --system-proxy
```

Change `PROXY_CHECK` to `strict` to stop instead of launching when an explicit
local proxy is unavailable.

## macOS says the launcher was blocked from modifying apps

The generated launcher runs only `chrome-gemini start`, which does not patch
Chrome files. Remove older launcher apps that run `chrome-gemini repair` or a
legacy `sed`-based patch on every launch, reinstall this project's launcher,
and replace the old Dock item.

The optional `repair` command should be run explicitly from Terminal, not from
the Dock launcher.

## The launcher app cannot be opened

Run the local installer again so the app is generated and ad-hoc signed on the
current Mac. Do not copy the generated `.app` between Macs; copy the repository
and run `./install.sh` on each Mac instead.

## 中文快速检查

- 必须按 `Cmd+Q` 完全退出 Chrome，不能只关闭窗口。
- 先启动代理，再使用生成的启动器。
- 在 `chrome://version` 检查地区和代理参数。
- 默认启动器不会修改 Chrome 配置；`repair` 只能在终端中显式运行。
- 启动器应在每台 Mac 上通过 `./install.sh` 本地生成，不要直接复制 `.app`。
