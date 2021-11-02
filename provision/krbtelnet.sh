# Provisioning script for the Kerberos telnet

sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y krb5-user krb5-config nfs-kernel-server sssd-krb5 telnetd xinetd

touch /var/log/krb5.log
chown vagrant:vagrant /var/log/krb5.log

[ -f /home/vagrant/krb5.conf ] && {
  sudo cp /home/vagrant/krb5.conf /etc/
}

[ -f /home/vagrant/telnet ] && {
  sudo cp /home/vagrant/telnet /etc/xinetd.d
}

#Setting the correct hostname, it must match the host SPN in KDC - Nov 01 20:47:05 kerberos-telnet sshd[7995]: No key table entry found matching host/kerberos-telnet@
hostnamectl set-hostname telnet.marti.local

