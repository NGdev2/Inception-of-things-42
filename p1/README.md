## Usage

To **launch the virtual machine** using **Vagrant**, run : 

```bash
cd p1

# Start the Vagrant environment
vagrant up
```

**You can then SSH into the VMs :** 

```bash
# Access the Kubernetes server VM
vagrant ssh fteganS

# Access the Kubernetes server VM
vagrant ssh fteganSW
```

Then we can use the `kubectl` commands to **interact with the Kubernetes cluster from the server VM.** Only the **server node** will have access to the full `kubectl` command set, including control over the Kubernetes cluster. The worker node acts as a client with limited visibility.

```bash
# Shows all resources (pods, services, etc.) in the default namespace
kubectl get all

# Shows all resources in all namespaces
kubectl get all --all-namespaces

# Describe a specific Kubernetes resource
kubectl describe <type> <name>
# OR
kubectl describe <type>/<name>

# Examples
kubectl describe pod kubernetes
kubectl describe pod kubernetes -o wide   # More detailed output
kubectl describe pod kubernetes -o yaml   # Output in YAML format
```

**For networking and system info :**

```bash
# Display network interfaces
ifconfig
ip show <exact interfcace> 
```

**To edit and debug :** 

```bash
# List active containers
docker ps 

# Edit a resource's YAML definition directly
kubectl edit  pod <podname>
```

**You can create pods imperatively or declaratively :**

- **Imperative** (direct from command line):
    
    ```bash
    kubectl run <podname> --image=nginx:latest
    ```
    
- **Declarative** (from a YAML file)
    
    ```bash
    kubectl apply -f pod.yaml
    ```
    

**To stop the Vagrant environment :**

```bash
vagrant halt
vagrant down
```

## Vagrantfile

**Overview**

To optimize and simplify the structure of the `Vagrantfile`, we declare the core configuration (`VAGRANT_BOX`, `MEMORY`, `CPUS`, etc.) at the top of the file. Instead of repeating similar configuration blocks for each virtual machine, we use a custom `define_node` function that takes the shared `config` object as an argument. This allows us to create and provision both the **server** and **worker** nodes in a modular and reusable way, while keeping the code clean and maintainable.

Additionally, for the worker node, we implement a **trigger** mechanism that waits for the `token.env` file to be created by the server before proceeding with provisioning. This ensures proper synchronization between the cluster components during setup.

**Detailed explanation of the script**

The `Vagrantfile` uses the `ubuntu/bionic64` Vagrant box which is an official Ubuntu 18.04 LTS image for 64-bit systems. This version is selected because it is stable, lightweight, and compatible with K3s. It does not include a graphical interface, which makes it faster to boot and consume fewer system resources. The box is also fully configured for Vagrant: SSH access is preconfigured and the system includes the necessary settings to work seamlessly with Vagrant's provisioning and networking features.

```
VAGRANT_BOX = "ubuntu/bionic64"
```

We configure a **boot timeout** that is twice as long as the usual time required to create the Vagrant machine, to ensure it doesn't fail on slower systems:

```
config.vm.boot_timeout = 600
```

We also enable the box_check_update option instead of hardcoding a specific box version. This allows the code to remain compatible with future updates to the Vagrant box:

```
config.vm.box_check_update = true
```

As the subject requires : *“You will set up your Vagrantfile according to modern practices”*, we set the configuration version 2, which is the standard and modern syntax supported by current versions of Vagrant.

```
Vagrant.configure("2") do |config|
```

After the initial configuration, a helper function called `define_node` is declared. Its purpose is to define and configure a virtual machine based on the provisioning script passed as an argument. It is either `server.sh` for the K3s server or `serverWorker.sh` for a K3s agent.

The function accepts parameters such as the VM's hostname, IP address, and the path to the provisioning script. Additionally, if the `with_token_trigger` flag is set to `true`, the function sets up a trigger that causes the VM to wait until the file `/vagrant/token.env` is present and non-empty before running the script. This ensures that the agent nodes only attempt to join the cluster after the server has generated the necessary token.

This mechanism is specifically used for provisioning the K3s agent node which needs to join an existing K3s server using the token.

Finally, the Vagrantfile calls `define_function` to create the **K3s server node** and **one K3s agent node**. They are named according to the subject requirements : adding S and SW to one of the teammates' login names.

```
# SERVER NODE
define_node(config, "fteganS", "#{NETWORK_PREFIX}.110", "scripts/server.sh")
 
# WORKER NODE
define_node(config, "fteganSW", "#{NETWORK_PREFIX}.111", "scripts/serverWorker.sh" with_token_trigger: true)
```

## Server.sh

The [`server.sh`](http://server.sh) is a Bash script that creates a **K3s server node** in a **K3s cluster** intended to be used with **Vagrant.** It is run automatically via the **`Vagrantfile` .**

The script begins by updating the package list and installing `curl` which is needed to download the K3s installer. Then, it downloads the official **K3s installation script**  https://get.k3s.io/ . The scripts modify environment variables in order to fit the subject requirement :

`--node-ip 192.168.56.110`: Sets the IP address

`--tls-san serverS` : adds serverS as Subject Alternative Name in the TLS certificate. A **Subject Alternative Name** allows the TLS certificate to be valid for multiple DNS names or IPs. Without it, clients trying to access the API server using an alias (like `serverS`) would get a certificate error.

`K3S_KUBECONFIG_MODE="644"`: Sets read permissions on the kubeconfig file so that non-root users (or automated tools) can access it. This way, we can now communicate with the containers using the kubectl command.

```bash
# Download the installation script
if curl -sfL https://get.k3s.io | \

# Set the IP adress of the node and adds serverS as SAN in the TLS certificate
INSTALL_K3S_EXEC="--node-ip 192.168.56.110 --tls-san serverS" \

# Set the kubeconfig file permissions to 644 so it can be read by the workers.
K3S_KUBECONFIG_MODE="644" \

# Execute the script
sh -;
```

Then, the scripts waits for the `/vagrant` folder to be mounted. If not, it waits for it to be available. The `/vagrant` folder is shared between the Vagrant host and the virtual machine.

Once `/vagrant` is available,  the script copies the K3s **cluster token** to `/vagrant/token.env.` The **K3s token** is a secret string used by worker nodes to securely **join the cluster**. It is generated automatically on the server and must be shared with all joining agents (workers).

Finally, the script changes the ownershop of the K3s Kubeconfig file.

## serverWorker.sh

The [`serverWorker.sh`](http://server.sh) is a Bash script used to configure a **K3s agent node** that connects to a **K3s server node** as part of a **K3s cluster.**  

The script begins by updating the package list and installing `curl` .

Then, it checks for the presence of a token file (`/vagrant/token`). This file must exist and contain the server node's join token. If the file is missing, the script exits with an error:

```bash
if [ ! -f /vagrant/token.env ]; then
    echo -e "${RED}Token file not found.${RESET}"
    exit 1
fi
```

Then, it downloads the official **K3s installation script**  https://get.k3s.io/ . The scripts modify environment variables in order to fit the subject requirement just like the `server.sh` script. Then it is executed.

Finally, for security, the token file is deleted after use to prevent unauthorized access to the K3s server:

```bash
sudo rm /vagrant/token.env
```


## Resources

- **K3s Quick-start guide :** https://docs.k3s.io/quick-start
- **K3s Documentation :** https://docs.k3s.io/
- **Vagrant Documentation :** https://developer.hashicorp.com/vagrant/docs/vagrantfile