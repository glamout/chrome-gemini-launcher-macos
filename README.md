# Chrome Gemini Launcher for macOS

An unofficial, auditable macOS launcher that starts Google Chrome with a
configurable region override and proxy. The normal launcher does not modify
`Google Chrome.app` or Chrome's configuration, so it avoids the recurring
macOS “modify apps” privacy notification caused by wrapper apps that patch
Chrome data on every launch.

Chinese documentation: [README.zh-CN.md](README.zh-CN.md)

## Features

- Starts Chrome with `--variations-override-country=<region>`.
- Optionally starts Chrome with `--proxy-server=<proxy>`.
- Refuses to attach flags to an already-running Chrome process.
- Creates a local, ad-hoc-signed-on-install Dock launcher in `~/Applications`.
- Checks Chrome, proxy, configuration, and relevant Local State fields.
- Provides an explicit optional repair command with timestamped backups.
- Does not download or execute remote code during installation.

## Requirements

- macOS
- Google Chrome installed in `/Applications`
- A local or remote proxy if the configured region requires one

This project does not provide a proxy service and cannot grant account or
server-side feature eligibility. Availability remains controlled by Google.

## Install

Clone or download the repository, inspect it, and run:

Choose the proxy mode during installation:

```bash
chmod +x install.sh uninstall.sh bin/chrome-gemini tests/test.sh

# Explicit local proxy (any supported port)
./install.sh --proxy-server http://127.0.0.1:7897

# Or use the current macOS system proxy
./install.sh --system-proxy
```

The installer creates:

- `~/.local/bin/chrome-gemini`
- `~/.local/share/chrome-gemini/patch-local-state.js`
- `~/.config/chrome-gemini/config`
- `~/Applications/Chrome Gemini Launcher.app`

Drag the launcher app to the Dock. Quit Chrome with `Cmd+Q` before using it.

## Configure

Edit `~/.config/chrome-gemini/config`:

```ini
REGION=us
PROXY_SERVER=http://127.0.0.1:7897
PROXY_CHECK=warn
CHROME_APP=/Applications/Google Chrome.app
CHROME_PROCESS=Google Chrome
```

The proxy is not hard-coded. HTTP, HTTPS, SOCKS4, and SOCKS5 URLs are supported.
Use `PROXY_CHECK=strict` to stop when a local proxy is unavailable, or set
`PROXY_SERVER=` to use the macOS system proxy without an explicit Chrome flag.

Change it later without editing the file manually:

```bash
chrome-gemini configure --proxy-server http://127.0.0.1:7890
chrome-gemini configure --proxy-server socks5://127.0.0.1:1080
chrome-gemini configure --system-proxy
```

## Commands

```bash
chrome-gemini start
chrome-gemini start --dry-run
chrome-gemini doctor
chrome-gemini inspect
chrome-gemini repair
chrome-gemini configure --help
```

`start` only launches Chrome. `repair` is intentionally separate: it requires
Chrome to be stopped, creates a timestamped backup, and then updates relevant
fields in Chrome's `Local State` JSON. Chrome may overwrite these internal
fields after an update or restart.

## Verify launch flags

Open `chrome://version` and check the **Command Line** row for:

```text
--variations-override-country=us
--proxy-server=http://127.0.0.1:7897
```

## Uninstall

```bash
./uninstall.sh
```

Configuration and Local State backups are intentionally retained.

## Security

Read [SECURITY.md](SECURITY.md) before using the optional repair command. Do
not install this project with `curl | bash`; download or clone it and inspect
the exact revision first.

See [Troubleshooting](docs/TROUBLESHOOTING.md) for missing flags, location
errors, proxy failures, and macOS privacy notifications.

## Local integration of the upstream enabler

This package never fetches or executes the moving
`appsail/Gemini-in-Chrome` installer. Its macOS behavior—checking that Chrome
is stopped, backing up `Local State`, updating region and eligibility fields,
and verifying the result—is implemented locally by `chrome-gemini repair` and
`scripts/patch-local-state.js`. See
[Upstream integration](docs/UPSTREAM_INTEGRATION.md) for the mapping and design
differences.

## License

MIT. Google, Chrome, and Gemini are trademarks of Google LLC. This project is
not affiliated with or endorsed by Google.
