# Chrome Gemini Launcher for macOS

这是一个非官方、可审阅的 macOS Chrome 启动器。它使用可配置的地区覆盖和代理参数启动
Google Chrome。默认启动器不会修改 `Google Chrome.app` 或 Chrome 配置，因此可避免那种
由启动器每次修改 Chrome 数据而触发的“修改 Mac 上的 App”隐私提示。

## 功能

- 使用 `--variations-override-country=<地区>` 启动 Chrome。
- 可选使用 `--proxy-server=<代理>` 启动 Chrome。
- Chrome 已在运行时拒绝启动，避免参数被忽略。
- 在 `~/Applications` 创建本机生成并进行临时签名的 Dock 启动器。
- 检查 Chrome、代理、配置以及相关的 `Local State` 字段。
- 提供显式的可选修复命令；修改前自动生成时间戳备份。
- 安装过程不下载或执行远程代码。

## 系统要求

- macOS
- Google Chrome，默认安装在 `/Applications`
- 如目标地区需要，准备一个本地或远程代理

本项目不提供代理服务，也不能授予 Google 账号或服务器端的功能资格。功能是否开放仍由
Google 决定。

## 安装

下载或克隆项目后，先审阅代码，再运行：

安装时直接选择代理方式：

```bash
chmod +x install.sh uninstall.sh bin/chrome-gemini tests/test.sh

# 指定任意本地代理端口
./install.sh --proxy-server http://127.0.0.1:7897

# 或直接使用当前 macOS 系统代理
./install.sh --system-proxy
```

安装器将创建：

- `~/.local/bin/chrome-gemini`
- `~/.local/share/chrome-gemini/patch-local-state.js`
- `~/.config/chrome-gemini/config`
- `~/Applications/Chrome Gemini Launcher.app`

把启动器拖进 Dock。使用前先按 `Cmd+Q` 完全退出 Chrome。

## 配置

编辑 `~/.config/chrome-gemini/config`：

```ini
REGION=us
PROXY_SERVER=http://127.0.0.1:7897
PROXY_CHECK=warn
CHROME_APP=/Applications/Google Chrome.app
CHROME_PROCESS=Google Chrome
```

代理地址没有写死。支持 HTTP、HTTPS、SOCKS4 和 SOCKS5。`PROXY_CHECK=warn` 会在本地代理
不可用时提示但继续；`strict` 会停止启动；`off` 会跳过检查。将 `PROXY_SERVER` 留空时，
Chrome 会使用 macOS 系统代理。

安装后也可以直接修改：

```bash
chrome-gemini configure --proxy-server http://127.0.0.1:7890
chrome-gemini configure --proxy-server socks5://127.0.0.1:1080
chrome-gemini configure --system-proxy
```

## 命令

```bash
chrome-gemini start             # 启动 Chrome
chrome-gemini start --dry-run   # 只显示将执行的命令
chrome-gemini doctor            # 诊断环境
chrome-gemini inspect           # 查看相关配置字段
chrome-gemini repair            # 备份并修复 Local State
chrome-gemini configure --help  # 修改地区和代理
```

`start` 只负责启动，不修改 Chrome 数据。`repair` 被有意设计成独立的显式操作：它要求 Chrome
已经完全退出，先生成时间戳备份，然后用结构化 JSON 处理相关字段。Chrome 更新或重启后仍可能
重新写入这些内部字段。

## 确认参数生效

打开 `chrome://version`，在“命令行”一栏确认包含：

```text
--variations-override-country=us
--proxy-server=http://127.0.0.1:7897
```

## 卸载

```bash
./uninstall.sh
```

卸载器会保留用户配置以及所有 `Local State` 备份。

## 安全说明

使用可选修复功能前请阅读 [SECURITY.md](SECURITY.md)。不要通过 `curl | bash` 安装本项目；
应当先下载或克隆一个确定的版本，审阅后再执行。

参数缺失、地区错误、代理失败和 macOS 隐私提示请参阅
[故障排查](docs/TROUBLESHOOTING.md)。

## 上游脚本的本地整合

本分发包不会下载或执行随时可能变化的 `appsail/Gemini-in-Chrome` 远程安装脚本。该脚本在
macOS 上的核心行为——确认 Chrome 已退出、备份 `Local State`、修改地区与资格字段、验证结果——
已由本地的 `chrome-gemini repair` 和 `scripts/patch-local-state.js` 实现。具体对应关系和改进请见
[上游功能整合说明](docs/UPSTREAM_INTEGRATION.md)。

## 许可证

MIT。Google、Chrome 和 Gemini 是 Google LLC 的商标。本项目与 Google 无隶属或背书关系。
