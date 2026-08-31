# Contributing

Contributions are welcome. Keep the default launcher read-only with respect to
Chrome application and profile data. Any mutating behavior must remain an
explicit command, create a recoverable backup, and be documented.

Before submitting a change:

```bash
bash -n bin/chrome-gemini install.sh uninstall.sh tests/test.sh
./tests/test.sh
```

Please keep compatibility with the Bash version shipped by macOS and avoid
adding required package-manager dependencies.

