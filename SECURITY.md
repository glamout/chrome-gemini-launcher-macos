# Security policy

## Trust model

The normal `start` command launches Chrome through macOS Launch Services and
passes command-line flags. It does not edit the Chrome application bundle or
Chrome user data.

The optional `repair` command modifies this file:

```text
~/Library/Application Support/Google/Chrome/Local State
```

It refuses to run while Chrome is active and creates a sibling timestamped
backup before writing. Run it from Terminal only after reviewing the code.

## Installation

Avoid piping a moving remote branch directly into a shell. Clone the project or
download a tagged release, verify the files, and run the local installer.

The installer, launcher, CLI, and repair implementation contain no `curl`,
`wget`, or runtime dependency on `raw.githubusercontent.com`. The upstream
enabler behavior is reimplemented locally; see
`docs/UPSTREAM_INTEGRATION.md`.

## Privacy

The project performs no analytics and sends no telemetry. The configured proxy
can observe browser traffic according to its own capabilities and trust model.
Use only a proxy you trust. Avoid embedding proxy credentials in
`PROXY_SERVER`, because Chrome command-line flags can be visible to local
process-inspection tools and on `chrome://version`.

## Reporting vulnerabilities

Open a GitHub security advisory in the repository that publishes this project.
Do not include Chrome profile data, account identifiers, IP addresses, or proxy
credentials in public reports.
