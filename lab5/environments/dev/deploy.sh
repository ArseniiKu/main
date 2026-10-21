#!/bin/bash
set -e

echo "=== [1/3] Provisioning Infrastructure with Terraform ==="
terraform init -input=false
terraform apply -auto-approve

echo "=== [2/3] Waiting for SSH to be ready ==="
INVENTORY_FILE="inventory.ini"
MAX_RETRIES=30
RETRY_COUNT=0

while ! ansible -i $INVENTORY_FILE web_servers -m ping > /dev/null 2>&1; do
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "Timeout: SSH is not ready after $MAX_RETRIES attempts."
    exit 1
  fi
  echo "Waiting... ($RETRY_COUNT/$MAX_RETRIES)"
  sleep 5
  RETRY_COUNT=$((RETRY_COUNT + 1))
done

echo "=== [3/3] Configuring with Ansible ==="
ansible-playbook -i $INVENTORY_FILE configure.yml

WEB_IP=$(grep ansible_host $INVENTORY_FILE | awk '{print $2}' | cut -d= -f2)
echo "=== DEPLOYMENT SUCCESSFUL ==="
echo "Access your web server at: http://$WEB_IP"
