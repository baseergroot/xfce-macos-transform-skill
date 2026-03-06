# xfce-macos-transform

![Skill](https://img.shields.io/badge/type-codex%20skill-0A7B83)
![Desktop](https://img.shields.io/badge/desktop-XFCE-1c71d8)
![Style](https://img.shields.io/badge/style-macOS%20look-333333)

Skill for AI agents to make XFCE look like macOS, or fix XFCE after a bad theming attempt.

## Use Cases

- Full XFCE -> macOS style setup
- Fix panel/layout/font issues after theming
- Apply only parts (icons, cursor, dock, fonts)
- Keep existing menu shortcuts unless explicitly replaced

## Install (One Command)

Option A (`npx`):

```bash
npx skills add https://github.com/baseergroot/xfce-macos-transform-skill.git
```

Option B (manual clone, works everywhere):

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
