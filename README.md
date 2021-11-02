## A simple Vagrant demonstration project of using Kerberos protocol for SSH(possible Telnet) and NFS access

![Kerberos Vagrant Diagram](https://lucid.app/publicSegments/view/c5ae9723-970f-43f0-bfa5-8da23c023fd9/image.jpeg)

### The project consists of the following Vagrant VMs:
- `kerberos-server` - VM that hosts the KDC - IP: `192.168.0.10` - DNS: `kdc.marti.local`
- `kerberos-client` - VM that consumes SSH and NFS services from `kerberos-telnet` VM - IP: `192.168.0.11` - DNS: `client.marti.local`
- `kerberos-telnet` - VM which provides SSH and NFS servers to be consumed by `kerberos-client` VM - IP: `192.168.0.12` - DNS: `telnet.marti.local`

### Prerequisites:

- VirtualBox
- Vagrant
- Vagrant plugin named `vagrant-hosts`

---

- Execute `vagrant up --provision` to start the three VMs.
- Login to the `kerberos-server`, change to `root` user by `sudo su` command and initialize the Kerberos Database (the `-s` flag creates a `stash` file to avoid entering the DB password upon restart):
    
    ```
    root@kerberos-server:/home/vagrant#/usr/sbin/kdb5_util create -s
    Loading random data
    Initializing database '/var/lib/krb5kdc/principal' for realm 'MARTI.LOCAL',
    master key name 'K/M@MARTI.LOCAL'
    You will be prompted for the database Master Password.
    It is important that you NOT FORGET this password.
    Enter KDC database master key:
    Re-enter KDC database master key to verify:
    ```
- Create a principal named `hristov/admin` (the pattern - username/instance of the user) in order to administer the KDC database, the command should be executed on `kerberos-server` VM. This Kerberos principal is going to be used to administer the KDC database remotely from `kerberos-client` and from `kerberos-telnet` VMs via `kadmin` tool.

    ```
    root@kerberos-server:/home/vagrant# kadmin.local
    Authenticating as principal root/admin@MARTI.LOCAL with password.
    kadmin.local:  addprinc hristov/admin
    WARNING: no policy specified for hristov/admin@MARTI.LOCAL; defaulting to no policy
    Enter password for principal "hristov/admin@MARTI.LOCAL":
    Re-enter password for principal "hristov/admin@MARTI.LOCAL":
    Principal "hristov/admin@MARTI.LOCAL" created.
    kadmin.local:
    ```
- The administrative permissions are given to all the users(principals) that have `admin` as instance via `kadm5.acl` file, which is located in `/etc/krb5kdc/kadm5.acl` and specified via `acl_file` parameter in `kdc.conf` file on the KDC server.
- The KDC on `kerberos-server` has initially failed due to the fact that no KDC DB has been present, lets start it:

    ```
    root@kerberos-server:/home/vagrant# systemctl status krb5-kdc
    ● krb5-kdc.service - Kerberos 5 Key Distribution Center
    Loaded: loaded (/lib/systemd/system/krb5-kdc.service; enabled; vendor preset: enabled)
    Active: failed (Result: exit-code) since Mon 2021-11-01 16:37:15 UTC; 2h 40min ago

    Nov 01 16:37:15 kerberos-server systemd[1]: Starting Kerberos 5 Key Distribution Center...
    Nov 01 16:37:15 kerberos-server krb5kdc[2927]: Cannot open DB2 database '/etc/krb5kdc/principal': No such file or directory - while initi
    Nov 01 16:37:15 kerberos-server krb5kdc[2927]: krb5kdc: cannot initialize realm ATHENA.MIT.EDU - see log file for details
    Nov 01 16:37:15 kerberos-server systemd[1]: krb5-kdc.service: Control process exited, code=exited status=1
    Nov 01 16:37:15 kerberos-server systemd[1]: krb5-kdc.service: Failed with result 'exit-code'.
    Nov 01 16:37:15 kerberos-server systemd[1]: Failed to start Kerberos 5 Key Distribution Center.
    root@kerberos-server:/home/vagrant# systemctl start krb5-kdc
    root@kerberos-server:/home/vagrant# systemctl status krb5-kdc
    ● krb5-kdc.service - Kerberos 5 Key Distribution Center
    Loaded: loaded (/lib/systemd/system/krb5-kdc.service; enabled; vendor preset: enabled)
    Active: active (running) since Mon 2021-11-01 19:18:06 UTC; 1s ago
    Process: 3451 ExecStart=/usr/sbin/krb5kdc -P /var/run/krb5-kdc.pid $DAEMON_ARGS (code=exited, status=0/SUCCESS)
    Main PID: 3463 (krb5kdc)
        Tasks: 1 (limit: 1152)
    CGroup: /system.slice/krb5-kdc.service
            └─3463 /usr/sbin/krb5kdc -P /var/run/krb5-kdc.pid

    Nov 01 19:18:06 kerberos-server krb5kdc[3451]: Setting up UDP socket for address ::.88
    Nov 01 19:18:06 kerberos-server krb5kdc[3451]: setsockopt(12,IPV6_V6ONLY,1) worked
    Nov 01 19:18:06 kerberos-server krb5kdc[3451]: Setting pktinfo on socket ::.88
    Nov 01 19:18:06 kerberos-server krb5kdc[3451]: Setting up TCP socket for address 0.0.0.0.88
    Nov 01 19:18:06 kerberos-server krb5kdc[3451]: Setting up TCP socket for address ::.88
    Nov 01 19:18:06 kerberos-server krb5kdc[3451]: setsockopt(14,IPV6_V6ONLY,1) worked
    Nov 01 19:18:06 kerberos-server krb5kdc[3451]: set up 6 sockets
    Nov 01 19:18:06 kerberos-server systemd[1]: krb5-kdc.service: Can't open PID file /var/run/krb5-kdc.pid (yet?) after start: No such file
    Nov 01 19:18:06 kerberos-server krb5kdc[3463]: commencing operation
    Nov 01 19:18:06 kerberos-server systemd[1]: Started Kerberos 5 Key Distribution Center.
- Let's start the `kadmin` (server) on the `kerberos-server` VM, so it can accept connections remotely.

    ```
    root@kerberos-server:/home/vagrant# /usr/sbin/kadmind
    root@kerberos-server:/home/vagrant# ps aux | grep kadmind
    root      3551  0.0  0.0  43200   448 ?        Ss   19:37   0:00 /usr/sbin/kadmind
    root      3553  0.0  0.1  14856  1048 pts/0    S+   19:37   0:00 grep --color=auto kadmind
    root@kerberos-server:/home/vagrant#
    ```
    The `/usr/sbin/kadmind` is binary which will go into background automatically.
- In order to test that KDC is working correctly and `hristov/admin` principal is able to administer the KDC DB using the `kadmin` tool logged in as `hristov/admin` from the `kerberos-client` VM, lets create another regular principal (user) named `hristov` which is not going to have any special privileges, the `kadmin` command can be executed as regular `vagrant` user.

    ```
    vagrant@kerberos-client:~$ kadmin -p hristov/admin
    Authenticating as principal hristov/admin with password.
    Password for hristov/admin@MARTI.LOCAL:
    kadmin:  addprinc hristov
    WARNING: no policy specified for hristov@MARTI.LOCAL; defaulting to no policy
    Enter password for principal "hristov@MARTI.LOCAL":
    Re-enter password for principal "hristov@MARTI.LOCAL":
    Principal "hristov@MARTI.LOCAL" created.
    kadmin:  q
    ```
- Let's verify if the `hristov` principal can receive TGT (Ticket Granting Ticket) via `kinit` executed on the `kerberos-client`

    ```
    vagrant@kerberos-client:~$ kinit hristov
    Password for hristov@MARTI.LOCAL:
    vagrant@kerberos-client:~$ klist
    Ticket cache: FILE:/tmp/krb5cc_1000
    Default principal: hristov@MARTI.LOCAL

    Valid starting     Expires            Service principal
    11/01/21 19:44:00  11/02/21 05:44:00  krbtgt/MARTI.LOCAL@MARTI.LOCAL
    	renew until 11/02/21 19:43:57
    vagrant@kerberos-client:~$
    ```
    The `krbtgt/MARTI.LOCAL@MARTI.LOCAL` record SPN signifies TGT (Ticket Granting Ticket)
- The next step is to set up SSH, Telnet and NFS server on `kerberos-telnet` VM.
    * For SSH server the following two options should be present in `/etc/ssh/sshd_config`

        ```
        # GSSAPI options
        GSSAPIAuthentication yes
        GSSAPICleanupCredentials yes
        ```
    * Create local user `hristov` via `useradd -s /bin/bash -c "Kerberos User" hristov`
    * Restart the SSH server via `systemctl restart sshd` executed as `root` user.
    * For NFS to be Kerberized, create the following sample export in `/etc/exports/`:

        ```
        /home   192.168.0.0/24(rw,sync,no_subtree_check,sec=krb5)
        ```
    * Verify that NFS exports are available on `kerberos-telnet` :

        ```
        root@kerberos-telnet:/# exportfs -a
        root@kerberos-telnet:/# showmount -e
        Export list for kerberos-telnet:
        /home 192.168.0.0/24
        root@kerberos-telnet:/#
        ```
- Create `keytab` file at `/etc/krb5.keytab` location which is special location for `host` and `service` keytab used by Kerberized services such as SSH and NFS. In order to create `/etc/krb5.keytab` file, the `kadmin` tool with `hristov/admin` user(principal) is going to be used to login to the KDC remotely from `kerberos-telnet` VM and save the `/etc/krb5.keytab` locally on `kerberos-telnet` VM.
Each service or host should have a record (Kerberos principal) in the KDC DB in order to be Kerberized. The principals for hosts and services use the following pattern, `host/telnet.marti.local@MARTI.local` for host principal and `nfs/telnet.marti.local@MARTI.local` for NFS service principal (SPN).

    ```
    root@kerberos-telnet:/# kadmin -p hristov/admin
    Authenticating as principal hristov/admin with password.
    Password for hristov/admin@MARTI.LOCAL:
    kadmin:  addprinc -randkey host/telnet.marti.local
    WARNING: no policy specified for host/telnet.marti.local@MARTI.LOCAL; defaulting to no policy
    Principal "host/telnet.marti.local@MARTI.LOCAL" created.
    kadmin:  addprinc -randkey nfs/telnet.marti.local
    WARNING: no policy specified for nfs/telnet.marti.local@MARTI.LOCAL; defaulting to no policy
    Principal "nfs/telnet.marti.local@MARTI.LOCAL" created.
    kadmin:  ktadd host/telnet.marti.local@MARTI.LOCAL
    Entry for principal host/telnet.marti.local@MARTI.LOCAL with kvno 2, encryption type aes256-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
    Entry for principal host/telnet.marti.local@MARTI.LOCAL with kvno 2, encryption type aes128-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
    kadmin:  ktadd nfs/telnet.marti.local@MARTI.LOCAL
    Entry for principal nfs/telnet.marti.local@MARTI.LOCAL with kvno 2, encryption type aes256-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
    Entry for principal nfs/telnet.marti.local@MARTI.LOCAL with kvno 2, encryption type aes128-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
    kadmin: q
    ```
    Note : the `ktadd` subcommand of `kadmin` automatically adds specified principals to `/etc/krb5.keytab` file locally.
- Verify that the `/etc/krb5.keytab` keytab file on `kerberos-telnet` VM contains the necessary principals via `ktutil` tool:

    ```
    root@kerberos-telnet:/# ktutil
    ktutil:  read_kt /etc/krb5.keytab
    ktutil:  list
    slot KVNO Principal
    ---- ---- ---------------------------------------------------------------------
       1    2      host/telnet.marti.local@MARTI.LOCAL
       2    2      host/telnet.marti.local@MARTI.LOCAL
       3    2       nfs/telnet.marti.local@MARTI.LOCAL
       4    2       nfs/telnet.marti.local@MARTI.LOCAL
    ktutil:
    ```
- The `kerberos-client` VM is going to be used as SSH client for `kerberos-telnet` VM, insert the following content into `~/.ssh/config` file as `vagrant` user.

    ```
    # Hosts we want to authenticate to with Kerberos
    Host *.marti.local
    # User authentication based on GSSAPI is allowed
    GSSAPIAuthentication yes
    # Key exchange based on GSSAPI may be used for server authentication
    GSSAPIKeyExchange yes
    # Hosts to which we want to delegate credentials. Try to limit this to
    # hosts you trust, and were you really have use for forwarded tickets.
    Host *.marti.local
    # Forward (delegate) credentials (tickets) to the server.
    GSSAPIDelegateCredentials yes
    # Prefer GSSAPI key exchange
    PreferredAuthentications gssapi-keyex,gssapi-with-mic
    # All other hosts
    Host *
    ```
- Now, the `kerberos-client` machine should be able to login to `kerberos-telnet` SSH server using Kerberos TGS (Ticket Granting Service):

    * Receiving TGT (Ticket Granting Ticket) first via `kinit`, the `KRB5_TRACE=/dev/stderr` is used for more visibility on the actions taken behind the scenes.
    ```
    vagrant@kerberos-client:~$ KRB5_TRACE=/dev/stderr kinit hristov

    [5106] 1635800184.578163: Getting initial credentials for hristov@MARTI.LOCAL
    [5106] 1635800184.578165: Sending unauthenticated request
    [5106] 1635800184.578166: Sending request (173 bytes) to MARTI.LOCAL
    [5106] 1635800184.578167: Resolving hostname kdc.marti.local
    [5106] 1635800184.578168: Sending initial UDP request to dgram 192.168.0.10:88
    [5106] 1635800184.578169: Received answer (237 bytes) from dgram 192.168.0.10:88
    [5106] 1635800184.578170: Sending DNS URI query for _kerberos.MARTI.LOCAL.
    [5106] 1635800184.578171: No URI records found
    [5106] 1635800184.578172: Sending DNS SRV query for _kerberos-master._udp.MARTI.LOCAL.
    [5106] 1635800184.578173: Sending DNS SRV query for _kerberos-master._tcp.MARTI.LOCAL.
    [5106] 1635800184.578174: No SRV records found
    [5106] 1635800184.578175: Response was not from master KDC
    [5106] 1635800184.578176: Received error from KDC: -1765328359/Additional pre-authentication required
    [5106] 1635800184.578179: Preauthenticating using KDC method data
    [5106] 1635800184.578180: Processing preauth types: 136, 19, 2, 133
    [5106] 1635800184.578181: Selected etype info: etype aes256-cts, salt "MARTI.LOCALhristov", params ""
    [5106] 1635800184.578182: Received cookie: MIT
    Password for hristov@MARTI.LOCAL:
    [5106] 1635800187.380952: AS key obtained for encrypted timestamp: aes256-cts/92C0
    [5106] 1635800187.380954: Encrypted timestamp (for 1635800187.385788): plain 301AA011180F32303231313130313230353632375AA105020305E2FC, encrypted D05180C59CE53F251AED52282494D35F8CE5193C2B4A77703AEEF335C610FC9CEC35DF2FFA6963AB47B393BE7F8FD844129A346118F4E0B8
    [5106] 1635800187.380955: Preauth module encrypted_timestamp (2) (real) returned: 0/Success
    [5106] 1635800187.380956: Produced preauth for next request: 133, 2
    [5106] 1635800187.380957: Sending request (268 bytes) to MARTI.LOCAL
    [5106] 1635800187.380958: Resolving hostname kdc.marti.local
    [5106] 1635800187.380959: Sending initial UDP request to dgram 192.168.0.10:88
    [5106] 1635800187.380960: Received answer (753 bytes) from dgram 192.168.0.10:88
    [5106] 1635800187.380961: Sending DNS URI query for _kerberos.MARTI.LOCAL.
    [5106] 1635800187.380962: No URI records found
    [5106] 1635800187.380963: Sending DNS SRV query for _kerberos-master._udp.MARTI.LOCAL.
    [5106] 1635800187.380964: Sending DNS SRV query for _kerberos-master._tcp.MARTI.LOCAL.
    [5106] 1635800187.380965: No SRV records found
    [5106] 1635800187.380966: Response was not from master KDC
    [5106] 1635800187.380967: Processing preauth types: 19
    [5106] 1635800187.380968: Selected etype info: etype aes256-cts, salt "MARTI.LOCALhristov", params ""
    [5106] 1635800187.380969: Produced preauth for next request: (empty)
    [5106] 1635800187.380970: AS key determined by preauth: aes256-cts/92C0
    [5106] 1635800187.380971: Decrypted AS reply; session key is: aes256-cts/42F2
    [5106] 1635800187.380972: FAST negotiation: available
    [5106] 1635800187.380973: Initializing FILE:/tmp/krb5cc_1000 with default princ hristov@MARTI.LOCAL
    [5106] 1635800187.380974: Storing hristov@MARTI.LOCAL -> krbtgt/MARTI.LOCAL@MARTI.LOCAL in FILE:/tmp/krb5cc_1000
    [5106] 1635800187.380975: Storing config in FILE:/tmp/krb5cc_1000 for krbtgt/MARTI.LOCAL@MARTI.LOCAL: fast_avail: yes
    [5106] 1635800187.380976: Storing hristov@MARTI.LOCAL -> krb5_ccache_conf_data/fast_avail/krbtgt\/MARTI.LOCAL\@MARTI.LOCAL@X-CACHECONF: in FILE:/tmp/krb5cc_1000
    [5106] 1635800187.380977: Storing config in FILE:/tmp/krb5cc_1000 for krbtgt/MARTI.LOCAL@MARTI.LOCAL: pa_type: 2
    [5106] 1635800187.380978: Storing hristov@MARTI.LOCAL -> krb5_ccache_conf_data/pa_type/krbtgt\/MARTI.LOCAL\@MARTI.LOCAL@X-CACHECONF: in FILE:/tmp/krb5cc_1000
    ```

    ```
    vagrant@kerberos-client:~$ ssh hristov@telnet.marti.local
    Welcome to Ubuntu 18.04.4 LTS (GNU/Linux 4.15.0-101-generic x86_64)

    * Documentation:  https://help.ubuntu.com
    * Management:     https://landscape.canonical.com
    * Support:        https://ubuntu.com/advantage

    System information as of Mon Nov  1 20:57:31 UTC 2021

    System load:  0.0               Processes:             123
    Usage of /:   13.1% of 9.63GB   Users logged in:       1
    Memory usage: 18%               IP address for enp0s3: 10.0.2.15
    Swap usage:   0%                IP address for enp0s8: 192.168.0.12


    188 packages can be updated.
    135 updates are security updates.

    New release '20.04.3 LTS' available.
    Run 'do-release-upgrade' to upgrade to it.


    Last login: Mon Nov  1 20:54:51 2021 from 192.168.0.11
    hristov@telnet:~$
    ```
- In order NFS to work, so a NFS mount can be visible on `kerberos-client` originating from `kerberos-telnet`, a keytab should be created for `nfs/client.marti.local@MARTI.LOCAL` and saved on `/etc/krb5.keytab` on the `kerberos-client` VM. For the purpose the `hristov/admin` principal and the `kadmin` tool can be used directly from the `kerberos-client` VM.

    ```
    root@kerberos-client:/home/vagrant# kadmin -p hristov/admin
    Authenticating as principal hristov/admin with password.
    Password for hristov/admin@MARTI.LOCAL:
    kadmin: Password read interrupted while initializing kadmin interface
    root@kerberos-client:/home/vagrant# kadmin -p hristov/admin
    Authenticating as principal hristov/admin with password.
    Password for hristov/admin@MARTI.LOCAL:
    Principal "nfs/client.marti.local@MARTI.LOCAL" created.
    kadmin:  ktadd nfs/client.marti.local@MARTI.local
    kadmin: Principal nfs/client.marti.local@MARTI.local does not exist.
    kadmin:  ktadd nfs/client.marti.local@MARTI.LOCAL
    Entry for principal nfs/client.marti.local@MARTI.LOCAL with kvno 2, encryption type aes256-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
    Entry for principal nfs/client.marti.local@MARTI.LOCAL with kvno 2, encryption type aes128-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
    kadmin:  q
    ```
- Verify that the `/etc/krb5.keytab` file contains the correct `nfs` principal via `klist -k` (`-k` uses `/etc/krb5.keytab` by default, not the cache):

    ```
    root@kerberos-client:/home/vagrant# klist -k
    Keytab name: FILE:/etc/krb5.keytab
    KVNO Principal
    ---- --------------------------------------------------------------------------
    2 nfs/client.marti.local@MARTI.LOCAL
    2 nfs/client.marti.local@MARTI.LOCAL
    ```
- Now mount the NFS mount via `mount -vvv -t nfs4 -o sec=krb5 telnet.marti.local:/home /home_kerberos_telnet` command.
- Now the `/home` directory from the `kerberos-telnet` should be mounted at `/home_kerberos_telnet` path on `kerberos-client` VM. Verify in the following manner :

    ```
    root@kerberos-client:/home/vagrant# cat /proc/mounts | grep telnet.marti.local
    telnet.marti.local:/home /home_kerberos_telnet nfs4 rw,relatime,vers=4.2,   rsize=131072,wsize=131072,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=krb5,  clientaddr=192.168.0.11,local_lock=none,addr=192.168.0.12 0 0
    ```
    ```
    root@kerberos-client:/home/vagrant# ls -l /home_kerberos_telnet
    total 12
    drwxr-xr-x 4 nobody  4294967294 4096 Nov  1 20:50 hristov
    drwxr-xr-x 3 ubuntu  ubuntu     4096 Nov  1 16:38 ubuntu
    drwxr-xr-x 5 vagrant vagrant    4096 Nov  1 19:46 vagrant
    ```
    If issues are encoutered during the mount, make sure that execute `systemctl restart rpc-gssd && systemctl restart rpc-svcgssd`
---

### Useful links and articles used in this project:
- [Kerberos admin guide](https://web.mit.edu/kerberos/krb5-1.9/krb5-1.9.2/doc/krb5-admin.html)
- [Kerberos: The Definitive Guide: The Definitive Guide](https://www.amazon.com/Kerberos-Definitive-Guide-Jason-Garman/dp/0596004036)
- [How to Setup Kerberos Server and Client on Ubuntu 18.04 LTS](https://www.howtoforge.com/how-to-setup-kerberos-server-and-client-on-ubuntu-1804-lts/)
- [Ubuntu Documentaiton](https://help.ubuntu.com/community/Kerberos)
- [SSH the secure shell](https://docstore.mik.ua/orelly/networking_2ndEd/ssh/ch11_04.htm)
- [Create a host principal using MIT Kerberos](http://www.microhowto.info/howto/create_a_host_principal_using_mit_kerberos.html)
- [Using SSH Keys with Kerberos](https://serverfault.com/questions/702923/using-ssh-keys-with-kerberos)
- [NFSv4 (nfs4) + Kerberos in Debian](https://wiki.debian.org/NFS/Kerberos)
- [Kerberos with NFS4](https://bbs.archlinux.org/viewtopic.php?id=220379)
- [Administering Keytab Files](https://docs.oracle.com/cd/E19683-01/806-4078/6jd6cjs1l/index.html)
- [Containerized Testing with Kerberos and SSH](https://www.confluent.io/blog/containerized-testing-with-kerberos-and-ssh/)

---

### TO DO:
- Intregrate KDC with OpenLDAP
- Kerberize another service of choice