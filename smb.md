# Samba

## Install
```sh
apt-get install samba
```

Every Samba user needs to be a system user. Nonetheless Samba passwords are handled separately and stored in `/etc/samba/smbpasswd`.

```sh
adduser smbtester
smbpasswd -a smbtester
```


## Create a Samba user

Let's create a directory to share:

```sh
cd
mkdir smbshare
```

And make Samba aware of it by adding the following to the very end of `/etc/samba/smb.conf`:

```sh
[smbshare]
path = /home/smbtester/smbshare
valid users = smbtester
read only = no
```

Now restart it: `service smbd restart` and test the settings via `testparm` if you like.


## Connect and mount CIFS

Install the utilities:

```sh
apt-get install cifs-utils # for mounting
apt-get install smbclient # for command line access

```

To connect via the command line:

```sh
smbclient //sdi5a.mi.hdm-stuttgart.de/smbshare -U smbtester
```

To mount the directory:

```sh
cd
mkdir mnt
mount -t cifs  //sdi4a.mi.hdm-stuttgart.de/smbtester ~/mnt/ -ouser=smbtester
```

