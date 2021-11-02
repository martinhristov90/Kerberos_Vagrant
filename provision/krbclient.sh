# Provisioning script for the Kerberos client

sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y krb5-user krb5-config sssd-krb5 nfs-common

touch /var/log/krb5.log
chown vagrant:vagrant /var/log/krb5.log

[ -f /home/vagrant/krb5.conf ] && {
  sudo cp /home/vagrant/krb5.conf /etc/
}

#Set hostname to match the Kerberos principal
hostnamectl set-hostname client.marti.local

#Create home_kerberos_telnet directory
mkdir /home_kerberos_telnet
chown vagrant:vagrant /home_kerberos_telnet