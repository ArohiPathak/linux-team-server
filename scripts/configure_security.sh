#!/bin/bash
# configure_security.sh - Configures sudo privileges and enforces SSH policies

set -e

echo "[*] Step 1: Deploying DevOps sudo policy..."
sudo cp config/devops-sudoers /etc/sudoers.d/devops-access
sudo chmod 0440 /etc/sudoers.d/devops-access

# Validate syntax
if sudo visudo -cf /etc/sudoers.d/devops-access; then
    echo "[+] Sudoers syntax verified successfully."
else
    echo "[-] Sudoers syntax error detected! Removing invalid file."
    sudo rm -f /etc/sudoers.d/devops-access
    exit 1
fi

echo "[*] Step 2: Applying SSH hardening configuration..."
sudo mkdir -p /etc/ssh/sshd_config.d/
sudo cp config/sshd_config_snippet.conf /etc/ssh/sshd_config.d/99-team-security.conf

# Restart SSH daemon based on service manager
if systemctl is-active --quiet ssh; then
    sudo systemctl restart ssh
    echo "[+] SSH service restarted."
elif systemctl is-active --quiet sshd; then
    sudo systemctl restart sshd
    echo "[+] SSHD service restarted."
else
    echo "[!] Warning: SSH daemon not active or running in WSL. Verify manually."
fi

echo "[+] Security configuration deployed."
