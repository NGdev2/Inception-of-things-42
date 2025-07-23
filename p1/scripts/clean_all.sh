#!/bin/bash

# Define colors
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
PURPLE="\033[35m"
RESET="\033[0m"

echo -e "${RED}🧹 PART 1 CLEANUP - Removing Vagrant VMs and K3s cluster resources${RESET}"
echo -e "${YELLOW}⚠️  This will delete:${RESET}"
echo -e "  • Vagrant VMs (fteganS, fteganSW)"
echo -e "  • VirtualBox VMs created by Vagrant"
echo -e "  • K3s installations on VMs"
echo -e "  • Generated token and config files"
echo -e "  • Vagrant boxes (optional)"
echo ""
echo -e "${GREEN}✅ This will NOT delete:${RESET}"
echo -e "  • Docker containers from other parts"
echo -e "  • k3d clusters from bonus part"
echo -e "  • VirtualBox installation itself"
echo -e "  • Other VirtualBox VMs not created by this Vagrant project"
echo ""
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cleanup cancelled.${RESET}"
    exit 1
fi

echo -e "${GREEN}🚀 Starting Part 1 cleanup...${RESET}"

# Navigate to p1 directory if it exists
if [ -d "p1" ]; then
    echo -e "${YELLOW}📁 Navigating to p1 directory...${RESET}"
    cd p1
elif [ -f "Vagrantfile" ]; then
    echo -e "${YELLOW}📁 Found Vagrantfile in current directory...${RESET}"
else
    echo -e "${YELLOW}📁 No p1 directory or Vagrantfile found, checking for VMs by name...${RESET}"
fi

# Stop and destroy Vagrant VMs
echo -e "${YELLOW}⏹️  Stopping and destroying Vagrant VMs...${RESET}"

# Try to halt VMs gracefully first
if [ -f "Vagrantfile" ]; then
    echo -e "${BLUE}Attempting graceful shutdown of VMs...${RESET}"
    vagrant halt 2>/dev/null || true
    
    echo -e "${BLUE}Destroying Vagrant VMs...${RESET}"
    vagrant destroy -f 2>/dev/null || true
else
    echo -e "${YELLOW}No Vagrantfile found, attempting to remove VMs by name...${RESET}"
fi

# Force remove VirtualBox VMs by name if Vagrant destroy didn't work
echo -e "${YELLOW}🔧 Force removing VirtualBox VMs by name...${RESET}"

# Get list of VMs that match our naming pattern
VMS_TO_REMOVE=$(VBoxManage list vms 2>/dev/null | grep -E "(fteganS|fteganSW)" | awk -F'"' '{print $2}' || true)

if [ -n "$VMS_TO_REMOVE" ]; then
    echo -e "${BLUE}Found VMs to remove: $VMS_TO_REMOVE${RESET}"
    for vm in $VMS_TO_REMOVE; do
        echo -e "${YELLOW}Removing VM: $vm${RESET}"
        # Force power off if running
        VBoxManage controlvm "$vm" poweroff 2>/dev/null || true
        sleep 2
        # Unregister and delete
        VBoxManage unregistervm "$vm" --delete 2>/dev/null || true
    done
else
    echo -e "${GREEN}✅ No matching VMs found to remove${RESET}"
fi

# Clean up Vagrant-specific files
echo -e "${YELLOW}🗑️  Removing Vagrant-generated files...${RESET}"
rm -rf .vagrant 2>/dev/null || true
rm -f token.env 2>/dev/null || true
rm -f k3s.yaml 2>/dev/null || true

# Clean up any remaining VirtualBox host-only adapters for our network range
echo -e "${YELLOW}🌐 Cleaning up VirtualBox network adapters...${RESET}"
HOSTONLYNICS=$(VBoxManage list hostonlyifs 2>/dev/null | grep -B3 "IPAddress:.*192\.168\.56\." | grep "Name:" | awk '{print $2}' || true)

if [ -n "$HOSTONLYNICS" ]; then
    echo -e "${BLUE}Found host-only adapters for 192.168.56.x network${RESET}"
    for nic in $HOSTONLYNICS; do
        # Check if any VMs are still using this adapter
        if ! VBoxManage list runningvms 2>/dev/null | grep -q .; then
            echo -e "${YELLOW}Removing unused host-only adapter: $nic${RESET}"
            VBoxManage hostonlyif remove "$nic" 2>/dev/null || true
        else
            echo -e "${YELLOW}Keeping adapter $nic (other VMs may be using it)${RESET}"
        fi
    done
fi

# Optional: Remove Vagrant boxes (ask user)
echo ""
read -p "Do you want to remove the ubuntu/bionic64 Vagrant box? This will affect other Vagrant projects using this box. (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}📦 Removing ubuntu/bionic64 Vagrant box...${RESET}"
    vagrant box remove ubuntu/bionic64 --force 2>/dev/null || true
else
    echo -e "${GREEN}✅ Keeping ubuntu/bionic64 Vagrant box${RESET}"
fi

# Clean up any leftover SSH keys or known_hosts entries
echo -e "${YELLOW}🔑 Cleaning up SSH configurations...${RESET}"
if [ -f ~/.ssh/known_hosts ]; then
    # Remove entries for our VM IPs
    ssh-keygen -R 192.168.56.110 2>/dev/null || true
    ssh-keygen -R 192.168.56.111 2>/dev/null || true
    ssh-keygen -R fteganS 2>/dev/null || true
    ssh-keygen -R fteganSW 2>/dev/null || true
fi

# Clean up any kubectl context that might point to the VMs
echo -e "${YELLOW}📋 Cleaning up kubectl contexts pointing to Part 1 VMs...${RESET}"
kubectl config delete-context fteganS 2>/dev/null || true
kubectl config delete-cluster fteganS 2>/dev/null || true
kubectl config unset users.admin@fteganS 2>/dev/null || true

echo -e "${GREEN}✅ PART 1 CLEANUP COMPLETED!${RESET}"
echo ""
echo -e "${BLUE}📊 Verification:${RESET}"

echo -e "${PURPLE}VirtualBox VMs:${RESET}"
VBoxManage list vms 2>/dev/null | grep -E "(fteganS|fteganSW)" || echo "No matching VMs found (good!)"

echo -e "${PURPLE}Running VMs:${RESET}"
VBoxManage list runningvms 2>/dev/null | grep -E "(fteganS|fteganSW)" || echo "No matching running VMs found (good!)"

echo -e "${PURPLE}Vagrant status:${RESET}"
if [ -f "Vagrantfile" ]; then
    vagrant status 2>/dev/null || echo "Vagrant environment destroyed"
else
    echo "No Vagrantfile found in current directory"
fi

echo -e "${PURPLE}Host-only network adapters:${RESET}"
VBoxManage list hostonlyifs 2>/dev/null | grep -A2 "IPAddress:.*192\.168\.56\." || echo "No 192.168.56.x network adapters found"

echo ""
echo -e "${GREEN}🎉 Part 1 cleanup complete!${RESET}"
echo -e "${YELLOW}💡 You can now run 'vagrant up' to recreate the environment from scratch${RESET}"
echo -e "${YELLOW}💡 Other VirtualBox VMs and Docker containers are preserved${RESET}"

# Return to original directory if we changed it
if [ -d "../" ] && [ "$(basename $(pwd))" = "p1" ]; then
    cd ..
fi