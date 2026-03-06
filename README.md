# xfce-macos-transform

Skill for AI agents to make XFCE look like macOS, or fix XFCE after a bad theming attempt.

## Use Cases

- Full XFCE -> macOS style setup
- Fix panel/layout/font issues after theming
- Apply only parts (icons, cursor, dock, fonts)
- Keep existing menu shortcuts unless explicitly replaced

## Install (One Command)

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills" && git clone https://github.com/baseergroot/xfce-macos-transform-skill.git "${CODEX_HOME:-$HOME/.codex}/skills/xfce-macos-transform"
```

## Simple Prompt

`make XFCE look like macOS`

## More Prompt Examples

- `make XFCE look like macOS but keep my MX menu shortcuts`
- `fix panel layout and font size only`
- `apply only macOS icons and cursor`
- `$xfce-macos-transform generate a safe bash script for Ubuntu XFCE`

## What It Does

- Generates either a prompt, a bash script, or live fix commands
- Prioritizes safe changes and backup-first behavior
- Preserves existing launcher/menu shortcuts by default

## Repository Contents

- `SKILL.md`
- `agents/openai.yaml`
- `references/components.md`
