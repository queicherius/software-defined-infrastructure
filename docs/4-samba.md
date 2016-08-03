# Samba

## Install

First off, we install the Samba dependencies as usual:

```sh
apt-get install samba
```

Every Samba user needs to be a system user. Nonetheless, Samba passwords are handled separately and stored in `/etc/samba/smbpasswd`, so we're going to set up one there:

```sh
adduser smbtester
smbpasswd -a smbtester
```

## Create a Samba user

As the first step, we create the directory we want to to share:

```sh
cd
mkdir smbshare
```

Now we make Samba aware of it by adding the following to the very end of `/etc/samba/smb.conf`:

```
[smbshare]
path = /home/smbtester/smbshare
valid users = smbtester
read only = no
```

Now we have to restart the service using `service smbd restart` and test can the settings via `testparm`.

## Connect and mount CIFS

First, we have to install the utilites for mouting and command line access:

```sh
apt-get install cifs-utils
apt-get install smbclient
```

Now, we can connect connect via the command line:

```sh
smbclient //sdi5a.mi.hdm-stuttgart.de/smbshare -U smbtester
```

Alternatively, we can mount the directory:

```sh
cd
mkdir mnt
mount -t cifs  //sdi4a.mi.hdm-stuttgart.de/smbtester ~/mnt/ -ouser=smbtester
```