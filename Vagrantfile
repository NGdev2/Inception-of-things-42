Vagrant.configure("2") do |config|
  config.vm.define "fteganS" do |server|
    server.vm.box = "ubuntu/bionic64"
    server.vm.hostname = "fteganS"
    server.vm.network "private_network", ip: "192.168.56.110"
    server.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
    end
    server.vm.provision "shell", path: "scripts/install_k3s_server.sh"
   end

  config.vm.define "fteganSW" do |worker|
    worker.vm.box = "ubuntu/bionic64"
    worker.vm.hostname = "fteganSW"
    worker.vm.network "private_network", ip: "192.168.56.111"
    worker.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
    end
    worker.vm.provision "shell", path: "scripts/install_k3s_agent.sh"
  end
end