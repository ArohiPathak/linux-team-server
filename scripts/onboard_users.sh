#!/bin/bash
# onboard_users.sh - Bulk user provisioning from CSV

set -e

CSV_FILE="${1:-data/users.csv}"

if [[ ! -f "$CSV_FILE" ]]; then
    echo "[-] Error: CSV file not found at $CSV_FILE"
    echo "Usage: sudo $0 <path_to_csv>"
    exit 1
fi

echo "[*] Processing user accounts from $CSV_FILE..."

tail -n +2 "$CSV_FILE" | while IFS=',' read -r username group ssh_key; do
    username=$(echo "$username" | xargs)
    group=$(echo "$group" | xargs)
    ssh_key=$(echo "$ssh_key" | xargs)

    [[ -z "$username" || -z "$group" ]] && continue

    if ! getent group "$group" >/dev/null; then
        echo "[!] Group $group does not exist. Creating group..."
        groupadd "$group"
    fi

    if ! id "$username" &>/dev/null; then
        useradd -m -s /bin/bash -g "$group" "$username"
        echo "[+] Created account: $username with primary group: $group"

        if [[ "$group" != "interns" ]]; then
            if getent group devteam >/dev/null; then
                usermod -aG devteam "$username"
                echo "[+] Added $username to devteam group"
            fi
        fi
    else
        echo "[*] Account $username already exists. Skipping creation."
    fi

    USER_HOME="/home/$username"
    SSH_DIR="$USER_HOME/.ssh"
    AUTH_KEYS="$SSH_DIR/authorized_keys"

    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"

    if [[ -n "$ssh_key" ]]; then
        echo "$ssh_key" > "$AUTH_KEYS"
        chmod 600 "$AUTH_KEYS"
        chown -R "$username:$group" "$SSH_DIR"
        echo "[+] Added SSH public key for: $username"
    fi
done

echo "[+] Onboarding completed successfully."
