#!/bin/bash

set -e

############################################
# CONFIGURATION
############################################

STACK_NAME="k8s-cluster"
TEMPLATE="k8s-heat.yaml"
OPENRC="$HOME/admin-openrc"

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
  --template $TEMPLATE \
  $STACK_NAME

############################################
# WAIT FOR STACK COMPLETION
############################################

echo "⏳ Waiting for stack to complete..."

while true; do
    STATUS=$(openstack stack show $STACK_NAME -f value -c stack_status)
    echo "Current status: $STATUS"

    if [[ "$STATUS" == "CREATE_COMPLETE" ]]; then
        echo "✅ Stack created successfully!"
        break
    fi

    if [[ "$STATUS" == "CREATE_FAILED" ]]; then
        echo "❌ Stack creation failed!"
        openstack stack failures list $STACK_NAME
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

cat > inventory/hosts.ini <<EOF
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

for HOST in $MASTER_FIP $WORKER1_FIP $WORKER2_FIP
do
  echo "Waiting for SSH on $HOST ..."
  until nc -z $HOST 22; do
    sleep 5
  done
  echo "✅ $HOST SSH is up!"
done

############################################
# TEST SSH CONNECTIVITY
############################################

echo "🔍 Testing SSH connectivity..."

ansible all -m ping

############################################
# DEPLOY KUBERNETES
############################################

echo "🚀 Deploying Kubernetes cluster..."

ansible-playbook site.yml

############################################
# DONE
############################################

echo "🎉 Kubernetes cluster deployed successfully!"

