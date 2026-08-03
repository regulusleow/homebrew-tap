# Astrolabe Homebrew Tap

[Chinese](README.zh-CN.md)

Install Astrolabe:

```bash
brew install regulusleow/tap/astrolabe
```

Configure Astrolabe for a specific AI client:

```bash
astrolabe install --client codex
astrolabe install --client opencode
astrolabe install --client claude-code
```

To configure every detected AI client at once:

```bash
astrolabe install --all-detected
```

Homebrew installation, upgrade, and removal never modify AI-client configuration.
