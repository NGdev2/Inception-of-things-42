## Server.sh

The [`server.sh`](http://server.sh) is a Bash script that creates a **K3s server node** in a **K3s cluster** intended to be used with **Vagrant.** It is run automatically via the **`Vagrantfile` .**

The script begins by updating the package list and installing `curl` which is needed to download the K3s installer. Then, it downloads the official **K3s installation script**  https://get.k3s.io/ . The scripts modify environment variables in order to fit the subject requirement :

`--node-ip 192.168.56.110`: Sets the IP address

`--tls-san serverS` : adds serverS as Subject Alternative Name in the TLS certificate. A **Subject Alternative Name** allows the TLS certificate to be valid for multiple DNS names or IPs. Without it, clients trying to access the API server using an alias (like `serverS`) would get a certificate error.

`K3S_KUBECONFIG_MODE="644"`: Sets read permissions on the kubeconfig file so that non-root users (or automated tools) can access it.

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
- **K3s Documentation** : https://docs.k3s.io/