# Provisioning script for the Kerberos server

sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y krb5-kdc krb5-admin-server

touch /var/log/krb5.log
chown vagrant:vagrant /var/log/krb5.log

[ -f /home/vagrant/krb5.conf ] && {
  sudo cp /home/vagrant/krb5.conf /etc/
}

[ -f /home/vagrant/kdc.conf ] && {
  sudo cp /home/vagrant/kdc.conf /etc/krb5kdc
}

[ -f /home/vagrant/kadm5.acl ] && {
  sudo cp /home/vagrant/kadm5.acl /etc/krb5kdc
}

#Set correct hostname
hostnamectl set-hostname kdc.marti.local