#!/bin/bash

set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

############################################
# CONFIGURATION
############################################

STACK_NAME="k8s-cluster"
TEMPLATE="k8s-heat.yaml"
OPENRC="$HOME/admin-openrc"
MAX_WAIT_SECONDS="${MAX_WAIT_SECONDS:-900}"
SSH_WAIT_SECONDS="${SSH_WAIT_SECONDS:-600}"
INVENTORY_FILE="${INVENTORY_FILE:-$SCRIPT_DIR/inventory/generated-hosts.ini}"

############################################
# LOAD OPENSTACK CREDENTIALS
############################################

echo "🔐 Loading OpenStack credentials..."

if [ -f "$OPENRC" ]; then
    source "$OPENRC"
else
    echo "❌ admin-openrc not found!"
    exit 1
fi

############################################
# CREATE STACK
############################################

echo "🚀 Creating OpenStack stack..."

openstack stack create \
  --template "$TEMPLATE" \
  "$STACK_NAME"

############################################
# WAIT FOR STACK COMPLETION
############################################

echo "⏳ Waiting for stack to complete..."

START_TIME=$(date +%s)
while true; do
    STATUS=$(openstack stack show "$STACK_NAME" -f value -c stack_status)
    echo "Current status: $STATUS"

    case "$STATUS" in
      CREATE_COMPLETE)
        echo "Stack created successfully."
        break
        ;;
      CREATE_FAILED|ROLLBACK_IN_PROGRESS|ROLLBACK_FAILED|ROLLBACK_COMPLETE|DELETE_IN_PROGRESS|DELETE_FAILED)
        echo "Stack creation failed or rolled back: $STATUS"
        openstack stack failures list "$STACK_NAME" || true
        exit 1
        ;;
    esac

    if (( $(date +%s) - START_TIME >= MAX_WAIT_SECONDS )); then
        echo "Timed out waiting for stack creation."
        openstack stack show "$STACK_NAME" || true
        exit 1
    fi

    sleep 10
done

############################################
# RETRIEVE FLOATING IPS
############################################

echo "📡 Retrieving Floating IPs..."

MASTER_FIP=$(openstack stack output show $STACK_NAME master_fip -f value -c output_value)
WORKER1_FIP=$(openstack stack output show $STACK_NAME worker1_fip -f value -c output_value)
WORKER2_FIP=$(openstack stack output show $STACK_NAME worker2_fip -f value -c output_value)

echo "Master:  $MASTER_FIP"
echo "Worker1: $WORKER1_FIP"
echo "Worker2: $WORKER2_FIP"

############################################
# GENERATE INVENTORY
############################################

echo "📝 Generating dynamic inventory..."

mkdir -p "$(dirname "$INVENTORY_FILE")"
cat > "$INVENTORY_FILE" <<EOF
[master]
k8s-master ansible_host=$MASTER_FIP

[workers]
k8s-worker1 ansible_host=$WORKER1_FIP
k8s-worker2 ansible_host=$WORKER2_FIP

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

############################################
# WAIT FOR SSH PORT 22
############################################

echo "⏳ Waiting for SSH to be ready..."

SSH_START_TIME=$(date +%s)
for HOST in "$MASTER_FIP" "$WORKER1_FIP" "$WORKER2_FIP"
do
  echo "Waiting for SSH on $HOST ..."
  until nc -z "$HOST" 22; do
    if (( $(date +%s) - SSH_START_TIME >= SSH_WAIT_SECONDS )); then
      echo "Timed out waiting for SSH on $HOST."
      exit 1
    fi
    sleep 5
  done
  echo "✅ $HOST SSH is up!"
done

############################################
# TEST SSH CONNECTIVITY
############################################

echo "🔍 Testing SSH connectivity..."

ansible -i "$INVENTORY_FILE" all -m ping

############################################
# DEPLOY KUBERNETES
############################################

echo "🚀 Deploying Kubernetes cluster..."

ansible-playbook -i "$INVENTORY_FILE" site.yml

############################################
# DONE
############################################

echo "Kubernetes cluster deployment completed successfully."

