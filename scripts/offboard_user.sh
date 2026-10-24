#!/bin/bash
# offboard_user.sh - Safe user deprovisioning and home archival

set -e

TARGET_USER="$1"
ARCHIVE_DIR="/var/archives/home_backups"

# 1. Check for username argument
if [[ -z "$TARGET_USER" ]]; then
    echo "Usage: sudo $0 <username>"
    exit 1
fi

# 2. Check if user exists on the system
if ! id "$TARGET_USER" &>/dev/null; then
    echo "[-] Error: User '$TARGET_USER' does not exist."
    exit 1
fi

echo "[*] Starting offboarding process for user: $TARGET_USER"

# 3. Terminate active sessions and processes
echo "[*] Terminating active processes..."
pkill -u "$TARGET_USER" 2>/dev/null || true

# 4. Lock password and disable login shell
echo "[*] Locking account and redirecting shell to nologin..."
usermod -L -s /usr/sbin/nologin "$TARGET_USER"

# 5. Revoke SSH keys
USER_HOME=$(eval echo "~$TARGET_USER")
if [[ -f "$USER_HOME/.ssh/authorized_keys" ]]; then
    rm -f "$USER_HOME/.ssh/authorized_keys"
    echo "[+] Revoked SSH authorized keys."
fi

# 6. Archive user home directory
mkdir -p "$ARCHIVE_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_PATH="$ARCHIVE_DIR/${TARGET_USER}_backup_${TIMESTAMP}.tar.gz"

if [[ -d "$USER_HOME" ]]; then
    echo "[*] Compressing home directory..."
    tar -czf "$ARCHIVE_PATH" -C /home "$TARGET_USER"
    rm -rf "$USER_HOME"
    echo "[+] Home directory archived to: $ARCHIVE_PATH"
fi

# 7. Delete user from system database
userdel "$TARGET_USER"
echo "[+] Successfully offboarded and deleted user: $TARGET_USER"
