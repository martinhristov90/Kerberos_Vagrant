#IPs
#KDC 192.168.0.10
#KRB client 192.168.0.11
#KRB telnet server 192.168.0.12

Vagrant.configure("2") do |config|
    config.vm.provision "shell", inline: "echo Hello"
  
    config.vm.define "kerberos-server" do |krbserver|
        krbserver.vm.box = "ubuntu/bionic64"
        krbserver.vm.network "private_network", ip: "192.168.0.10"
        krbserver.vm.provision :hosts do |provisioner|
            provisioner.provision "file", source: "./provision/config_files_client/krb5.conf", destination: "/etc/krb5.conf"
            provisioner.add_host '192.168.0.10', ['kdc.marti.local']
            provisioner.add_host '192.168.0.11', ['client.marti.local']
            provisioner.add_host '192.168.0.12', ['telnet.marti.local']
        end
        krbserver.vm.provision "file", source: "./provision/config_files_server/krb5.conf", destination: "/home/vagrant/krb5.conf"
        krbserver.vm.provision "file", source: "./provision/config_files_server/kdc.conf", destination: "/home/vagrant/kdc.conf"
        krbserver.vm.provision "file", source: "./provision/config_files_server/kadm5.acl", destination: "/home/vagrant/kadm5.acl"
        krbserver.vm.provision :shell, path: "provision/krbserver.sh", privileged: true
    end
  
    config.vm.define "kerberos-client" do |krbclient|
      krbclient.vm.box = "ubuntu/bionic64"
      krbclient.vm.network "private_network", ip: "192.168.0.11"
      krbclient.vm.provision :hosts do |provisioner|
        provisioner.add_host '192.168.0.10', ['kdc.marti.local']
        provisioner.add_host '192.168.0.11', ['client.marti.local']
        provisioner.add_host '192.168.0.12', ['telnet.marti.local']
      end
      krbclient.vm.provision "file", source: "./provision/config_files_client/krb5.conf", destination: "/home/vagrant/krb5.conf"
      krbclient.vm.provision :shell, path: "provision/krbclient.sh", privileged: true
    end

    config.vm.define "kerberos-telnet" do |krbtelnet|
      krbtelnet.vm.box = "ubuntu/bionic64"
      krbtelnet.vm.network "private_network", ip: "192.168.0.12"
      krbtelnet.vm.provision :hosts do |provisioner|
        provisioner.add_host '192.168.0.10', ['kdc.marti.local']
        provisioner.add_host '192.168.0.11', ['client.marti.local']
        provisioner.add_host '192.168.0.12', ['telnet.marti.local']
      end
      krbtelnet.vm.provision "file", source: "./provision/config_files_telnet/krb5.conf", destination: "/home/vagrant/krb5.conf"
      krbtelnet.vm.provision "file", source: "./provision/config_files_telnet/telnet", destination: "/home/vagrant/telnet"
      krbtelnet.vm.provision :shell, path: "provision/krbtelnet.sh", privileged: true
    end
  end