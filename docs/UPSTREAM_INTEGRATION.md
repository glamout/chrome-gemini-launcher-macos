# Upstream integration / 上游功能整合

## Source reviewed

The behavior was compared with the public MIT-licensed project:

- Repository: <https://github.com/appsail/Gemini-in-Chrome>
- Script: <https://raw.githubusercontent.com/appsail/Gemini-in-Chrome/main/install.sh>
- Snapshot reviewed: 2026-08-28

No remote copy of that script is downloaded or executed by this package.

## Behavior mapping

| Upstream behavior | Local implementation |
| --- | --- |
| Detect whether Chrome is active | `chrome-gemini repair` uses `pgrep` and refuses to continue |
| Locate Chrome `Local State` | Local CLI uses the standard macOS path, with a test override |
| Back up `Local State` | Creates timestamped, permission-preserving backups |
| Set `is_glic_eligible=true` | Structured JSON repair for every profile in `info_cache` |
| Set region fields to `us` | Structured JSON repair using the configured two-letter region |
| Verify text replacements | Parses the resulting JSON and prints a structured summary |

The local implementation also handles safe-seed region fields and
`glic.launcher_enabled`. It avoids regular-expression editing of JSON and does
not overwrite one fixed `.bak` file on every run.

## Runtime network behavior

The project does not need network access to install, configure, inspect, repair,
or launch Chrome. Chrome itself and the user-configured proxy naturally use the
network after launch.

## 中文说明

原脚本的 macOS 核心功能已用本地结构化 JSON 方式重新实现。安装器不会执行
`curl | bash`，运行时也不会访问 GitHub。`repair` 必须由用户在终端显式执行，默认 Dock
启动器只负责带参数启动 Chrome，不会修改配置文件。

