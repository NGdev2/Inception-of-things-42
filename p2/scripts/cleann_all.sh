#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${YELLOW}Starting complete K3s Vagrant cleanup...${RESET}"

# Step 1: Clean up Kubernetes resources (if VM is still running)
echo -e "${YELLOW}Step 1: Cleaning up Kubernetes resources...${RESET}"
if vagrant status | grep -q "running"; then
    echo "VM is running, cleaning up K3s resources first..."
    
    # SSH into the VM and clean up K3s resources
    vagrant ssh -c "
        # Delete all applications
        kubectl delete -f /vagrant/configs/app1 --ignore-not-found=true
        kubectl delete -f /vagrant/configs/app2 --ignore-not-found=true
        kubectl delete -f /vagrant/configs/app3 --ignore-not-found=true
        
        # Delete ingress
        kubectl delete -f /vagrant/configs/ingress/ingress.yaml --ignore-not-found=true
        
        # Delete all pods, services, ingresses in default namespace
        kubectl delete pods,services,ingresses --all
        
        # Uninstall K3s completely
        sudo /usr/local/bin/k3s-uninstall.sh
        
        echo 'K3s and all resources cleaned up inside VM'
    "
    echo -e "${GREEN}Kubernetes resources cleaned up${RESET}"
else
    echo "VM is not running, skipping K3s cleanup"
fi

# Step 2: Destroy the Vagrant VM
echo -e "${YELLOW}Step 2: Destroying Vagrant VM...${RESET}"
vagrant destroy -f
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Vagrant VM destroyed successfully${RESET}"
else
    echo -e "${RED}Error destroying Vagrant VM${RESET}"
fi

# Step 3: Clean up Vagrant files and caches
echo -e "${YELLOW}Step 3: Cleaning up Vagrant files...${RESET}"

# Remove .vagrant directory (contains VM metadata, keys, etc.)
if [ -d ".vagrant" ]; then
    rm -rf .vagrant
    echo -e "${GREEN}Removed .vagrant directory${RESET}"
fi

# Step 4: Clean up VirtualBox artifacts (optional but recommended)
echo -e "${YELLOW}Step 4: Cleaning up VirtualBox artifacts...${RESET}"

# List and remove any remaining VMs with the hostname
VM_NAME="lduheronS"
if VBoxManage list vms | grep -q "$VM_NAME"; then
    echo "Found remaining VirtualBox VM: $VM_NAME"
    VM_UUID=$(VBoxManage list vms | grep "$VM_NAME" | sed 's/.*{\(.*\)}.*/\1/')
    VBoxManage co+ntrolvm "$VM_UUID" poweroff 2>/dev/null || true
    VBoxManage unregistervm "$VM_UUID" --delete 2>/dev/null || true
    echo -e "${GREEN}Removed VirtualBox VM: $VM_NAME${RESET}"
fi

# Clean up any orphaned VirtualBox files
VBoxManage list hdds | grep -i vagrant | while read line; do
    if echo "$line" | grep -q "lduheronS\|InceptionOfThings"; then
        UUID=$(echo "$line" | sed 's/.*UUID: *\([^ ]*\).*/\1/')
        VBoxManage closemedium disk "$UUID" --delete 2>/dev/null || true
    fi
done

# Step 5: Clean up host file entries (if they were added to host machine)
echo -e "${YELLOW}Step 5: Cleaning up host file entries...${RESET}"

# Remove entries from /etc/hosts if they exist
if grep -q "app1.com\|app2.com\|app3.com" /etc/hosts 2>/dev/null; then
    echo "Found app entries in /etc/hosts. You may want to remove them manually:"
    echo "sudo sed -i '/192.168.56.110.*app[123].com/d' /etc/hosts"
else
    echo "No app entries found in /etc/hosts"
fi

# Step 6: Clean up Vagrant global status
echo -e "${YELLOW}Step 6: Cleaning up Vagrant global status...${RESET}"
vagrant global-status --prune

echo -e "${GREEN}Complete cleanup finished!${RESET}"
echo -e "${YELLOW}Summary of what was cleaned:${RESET}"
echo "✓ K3s cluster and all pods/services/ingresses"
echo "✓ Vagrant VM destroyed"
echo "✓ .vagrant directory removed"
echo "✓ VirtualBox VM and associated files"
echo "✓ Vagrant global status pruned"
echo ""
echo -e "${YELLOW}Manual cleanup needed:${RESET}"
echo "- Check /etc/hosts for any remaining app entries"
echo "- Verify VirtualBox Manager shows no remaining VMs"