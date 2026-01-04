#!/usr/bin/env bash
set -Eeuo pipefail

# ===============================
# Docker Engine Installer (Ubuntu)
# ===============================

if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Please run as root"
  echo "✅ Usage:"
  echo "curl -fsSL <URL> | sudo bash"
  exit 1
fi

echo "🔹 Detecting Ubuntu version..."
if ! command -v lsb_release >/dev/null 2>&1; then
  apt update -y
  apt install -y lsb-release
fi

UBUNTU_CODENAME="$(lsb_release -cs)"

echo "🔹 Updating system..."
apt update -y

echo "🔹 Removing old Docker versions (if any)..."
apt remove -y docker docker-engine docker.io containerd runc || true

echo "🔹 Installing required dependencies..."
apt install -y \
  ca-certificates \
  curl \
  gnupg

echo "🔹 Adding Docker official GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "🔹 Adding Docker APT repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $UBUNTU_CODENAME stable" \
  > /etc/apt/sources.list.d/docker.list

echo "🔹 Updating package index..."
apt update -y

echo "🔹 Installing Docker Engine..."
apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

echo "🔹 Enabling & starting Docker service..."
systemctl enable docker
systemctl start docker

if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
  echo "🔹 Adding user '$SUDO_USER' to docker group..."
  usermod -aG docker "$SUDO_USER"
  echo "⚠️  Logout & login again to use Docker without sudo"
fi

echo
echo "✅ Docker installation completed successfully!"
echo
docker --version
docker compose version

echo
echo "🎉 Done!"
