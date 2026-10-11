#!/usr/bin/env bash
#
# VPS Initializer — create user, grant sudo, install Docker, configure logging.
# Must be run as root.
#
set -euo pipefail

reboot_system() {
  echo "Rebooting the system..."
  exec reboot
}

# ──────────────────────────────────────────────
# 0. Create a new user with sudo access
# ──────────────────────────────────────────────

read -rp 'Enter username to create: ' USERNAME

# Skip if user already exists
if id "$USERNAME" &>/dev/null; then
  echo "User '$USERNAME' already exists, skipping creation."
else
  # -m  — create home directory automatically
  useradd -m -s /bin/bash "$USERNAME"
  echo "User '$USERNAME' created."

  # Set password interactively (no echo)
  read -s -rp "Enter password for '$USERNAME': " PASSWORD
  echo
  read -s -rp "Confirm password for '$USERNAME': " CONFIRM
  echo
  if [[ "$PASSWORD" != "$CONFIRM" ]]; then
    echo "Passwords do not match. Exiting."
    exit 1
  fi
  # chpasswd expects input in format: login:password
  printf '%s:%s\n' "$USERNAME" "$PASSWORD" | chpasswd 2>/dev/null
  echo "User created and password set."
fi

# Add user to sudo group
if id -nG "$USERNAME" 2>/dev/null | grep -qw sudo; then
  echo "'$USERNAME' is already in the sudo group."
else
  usermod -aG sudo "$USERNAME"
  echo "Added '$USERNAME' to sudo group."
fi

# ──────────────────────────────────────────────
# 1. Install Docker (if not already installed)
# ──────────────────────────────────────────────

if command -v docker &>/dev/null; then
  echo "Docker is already installed ($(docker --version 2>/dev/null || true))."
  DOCKER_NEW_INSTALL=false
else
  echo "Installing Docker packages..."
  apt-get update
  apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

  # Add official Docker GPG key
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  # Add Docker apt repository
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list

  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin
  echo "Docker installed."
  DOCKER_NEW_INSTALL=true
fi

# ──────────────────────────────────────────────
# 2. Start and enable Docker service
# ──────────────────────────────────────────────

if systemctl is-active --quiet docker; then
  echo "Docker service is already running."
else
  systemctl enable docker
  systemctl start docker
  echo "Docker service enabled and started."
fi

# ──────────────────────────────────────────────
# 3. Add user to docker group
# ──────────────────────────────────────────────

if id -nG "$USERNAME" 2>/dev/null | grep -qw docker; then
  echo "'$USERNAME' is already in the docker group."
else
  usermod -aG docker "$USERNAME"
  echo "Added '$USERNAME' to docker group."
fi

# ──────────────────────────────────────────────
# 4. Apply daemon.json configuration (only on fresh Docker install)
# ──────────────────────────────────────────────

if [[ "$DOCKER_NEW_INSTALL" == true ]]; then
  mkdir -p /etc/docker
  cp "$(dirname "$0")/daemon.json" /etc/docker/daemon.json
  echo "Copied daemon.json to /etc/docker/daemon.json."

  if systemctl is-active --quiet docker; then
    systemctl restart docker
    echo "Docker restarted to apply new configuration."
  fi
fi

# ──────────────────────────────────────────────
# 5. Reboot
# ──────────────────────────────────────────────

reboot_system
