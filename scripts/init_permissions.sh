#!/bin/bash
# init_permissions.sh - Sets up base company groups, /projects directory, SGID, and ACLs

set -e

echo "[*] Step 1: Creating company groups..."
for grp in developers testers devops interns devteam; do
    if ! getent group "$grp" >/dev/null; then
        sudo groupadd "$grp"
        echo "[+] Created group: $grp"
    else
        echo "[*] Group $grp already exists."
    fi
done

echo "[*] Step 2: Creating and configuring /projects directory..."
sudo mkdir -p /projects

# Set owner to root, and group to devteam
sudo chown root:devteam /projects

# Apply SGID (2), full access for owner (7), full access for devteam (7), no access for others (0)
sudo chmod 2770 /projects
echo "[+] /projects configured with permissions 2770 and group 'devteam'."

echo "[*] Step 3: Enforcing read-only ACLs for interns..."
if ! command -v setfacl &>/dev/null; then
    sudo apt-get update -y && sudo apt-get install -y acl
fi

# Apply immediate read+execute access to /projects for interns
sudo setfacl -m g:interns:r-x /projects

# Apply default inheritance so all future files/folders created inside give interns read+execute
sudo setfacl -d -m g:interns:r-x /projects

echo "[+] POSIX ACLs successfully applied for group 'interns'."
