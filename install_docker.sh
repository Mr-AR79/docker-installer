#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Run as root:"
  echo "curl -fsSL <URL> | sudo bash"
  exit 1
fi

echo "🔹 Purging old Docker APT configs (hard clean)..."

rm -f /etc/apt/sources.list.d/docker*
rm -f /etc/apt/keyrings/docker.*
rm -f /usr/share/keyrings/docker*
sed -i '/download.docker.com/d' /etc/apt/sources.list || true

apt clean
apt update -y

echo "🔹 Installing dependencies..."
apt install -y ca-certificates curl gnupg lsb-release

CODENAME="$(lsb_release -cs)"

echo "🔹 Adding Docker official GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "🔹 Adding Docker APT repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $CODENAME stable" \
> /etc/apt/sources.list.d/docker.list

echo "🔹 Updating package index..."
apt update -y

echo "🔹 Installing Docker Engine..."
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker

if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]]; then
  usermod -aG docker "$SUDO_USER"
  echo "⚠️ Logout/login required to use docker without sudo"
fi

docker --version
echo "✅ Docker installed successfully"
