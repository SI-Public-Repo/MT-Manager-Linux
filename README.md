# MT Manager for Linux

A small desktop app to manage MetaTrader 4 and MetaTrader 5 terminals running under Wine on Linux:
install brokers, duplicate or rename terminals, manage EAs and indicators, clean up logs, start on boot.

> This repository only holds **compiled releases and installer scripts**. The source code is private.

## Install

On the Linux machine (VPS / RDP), run:

```bash
curl -fsSL https://raw.githubusercontent.com/SI-Public-Repo/MT-Manager-Linux/main/install.sh | bash
```

It downloads the latest release, checks its checksum, installs to `~/mtml`, and creates a desktop
shortcut. You will be asked for your `sudo` password once, to install two small packages
(`python3-tk`, `yad`). Git is not needed.

## Update

The app checks for updates when it starts (Auto-update switch in the footer) and has a
**Check for updates** button. Nothing to do by hand.

## What is in this repository

| Path | What it is |
|---|---|
| `install.sh` | First-time installer (what the command above runs) |
| `update.sh` | Used by the app to update itself |
| `doinstall.sh` | Installs dependencies and the desktop shortcut |
| `MT_BROKER_LIST.txt` | Broker download list shown in **Install MT** |
| `releases/latest.txt` | Name of the newest release folder (e.g. `v1.3`) |
| `releases/vX.Y/` | One folder per version: `mtml-linux-x86_64.tar.gz` + `.sha256` |

## Broker list (`MT_BROKER_LIST.txt`)

The app downloads this file every time **Install MT** is opened, so editing it changes the list for
all users within a few minutes, **no new release needed**.

One broker per line, `VERSION|Broker Name|Installer URL`:

```
MT5|Exness|https://download.mql5.com/cdn/web/exness.technologies.ltd/mt5/exness5setup.exe
```

- `VERSION` is `MT4` or `MT5`. Lines starting with `#` and blank lines are ignored.
- Keep each section sorted A–Z by name.
- `MetaQuotes (Original)` is the plain MetaQuotes installer; it can log in to any broker.
- Check the URL downloads (`curl -sIL <url>`) before adding it.

## Releases are published by the maintainer

Do not edit `releases/` by hand. Each version folder is created by the release process in the private
repository, and `latest.txt` is changed last so users never see a half-uploaded version.
GitHub's raw CDN caches files for about 5 minutes, so a new release or list change can take that
long to show up.
