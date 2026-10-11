# Agent Instructions — VPS Initializer

## Purpose

This repository holds scripts and configurations for automating the initialization of a fresh VPS as root. Everything here is one-shot: runs once when provisioning a new machine and configures it for the project.

## Guidelines

1. **Scripts must be idempotent** (safe to re-run). Check whether a user, directory, or crontab entry exists before creating or modifying it.
2. **Declare explicit dependencies**. When installing something, check first (`command -v`, `dpkg -l`, `npm ls`) before installing.
3. **No hardcoded passwords**. Secrets go through environment variables or `read -s` with confirmation.
4. **No backend agent needed**. Create files, run commands, verify results — all within a single session.
5. **Linux-centric**. Bash/sh scripts, package managers via apt/apk/yum depending on the distro.

## Typical Initialization Steps

- Update packages (`apt update && apt upgrade`)
- Create a user, configure sudo
- Install dependencies (Node.js, Python, Docker, utilities)
- Configure firewall (ufw)
- Configure SSH
- Set up Cron / systemd services
- Deploy application
- Configure domain and SSL

## Format

Preferred approach:
- Bash scripts (`.sh`)
- YAML / JSON for configuration files
- Run commands via `bash` with `set -euo pipefail`
