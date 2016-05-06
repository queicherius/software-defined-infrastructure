# Apache

## Installing

```
aptitude install apache2
```

Upon visiting [http://sdi5b.mi.hdm-stuttgart.de/]() we are greeted with the apache default welcome page. When changing the file `/var/www/html/index.html`, the page content changes.

## Installing documentation

```
aptitude install apache2-doc
```

To find out where we can access our freshly installed documentation, we run `dpkg` to list all files installed by the package.

```
dpkg -L apache2-doc | less
```

There we look for apache configuration files and find `/etc/apache2/conf-available/apache2-doc.conf`, which includes an `Alias` from `/manual` to the directory of the manuals. Now we know, that we can access the manuals from [http://sdi5b.mi.hdm-stuttgart.de/manual]().

## Configuring our own alias

We want to be able to call [http://sdi5b.mi.hdm-stuttgart.de/xyz123]() and access the directory `/home/sdidoc` where we uploaded our documentation.

We need to place a configuration file setting up the alias `/etc/apache2/conf-enabled/sdidoc.conf`:

```
Alias /xyz123 /home/sdidoc

<Directory "/home/sdidoc">
    Options Indexes FollowSymlinks
    AllowOverride None
    Require all granted
    AddDefaultCharset off
</Directory>
```

## Virtual hosts

When we configure our client machine to use our (private) nameserver we want to be able to call [xyz123.mi.hdm-stuttgart.de]() and reach our documentation.

We define two DNS aliases `xy123` and `manual` for our virtual machine in `/etc/bind/zones/db.mi.hdm-stuttgart.de`:

```
...
manual.mi.hdm-stuttgart.de.	IN	CNAME	ns5.mi.hdm-stuttgart.de.
xyz123.mi.hdm-stuttgart.de.	IN	CNAME	ns5.mi.hdm-stuttgart.de.
```

Let's define the following vhosts in `/etc/apache2/sites-enabled/vhosts.conf` to link our subdomains to the directories the files live in:

```
<VirtualHost *:80>
  ServerName xyz123.mi.hdm-stuttgart.de
  DocumentRoot /home/sdidoc
</VirtualHost>

<VirtualHost *:80>
  ServerName manual.mi.hdm-stuttgart.de
  DocumentRoot /usr/share/doc/apache2-doc/manual
</VirtualHost>
```

To apply the configuration we have to restart the services:

```bash
service bind9 reload
service apache2 reload
```

To test that everything works (without ~~fun~~ VPN problems) we connect via SSH  using the `-Y` flag to our second server. On the server, we set the nameserver to our first server in the `/etc/resolv.conf`. Now we can start `iceweasel` and connect to one of our newly configured subdomains. Seeing our webpages verifies that the DNS setting are correct.

## SSL / TLS Support

First off, we make sure openssl is installed and create an own certificate authority (CA).

```bash
apt-get install openssl
/usr/lib/ssl/misc/CA.pl -newca
```

Just follow the dialog, but note that the following fields are mandatory:

- PEM pass phrase (4+ characters)
- Common Name
- Pass phrase for `cakey.pem`

```bash
# Generate a key for our server
openssl genrsa -out /etc/ssl/private/apache.key 2048

# Generate a certificate for our server
openssl req -new -x509 -key /etc/ssl/private/apache.key -days 365 -sha256 -out /etc/ssl/certs/apache.crt

# Generate a certificate signing request (CSR)
# openssl req -new -key /etc/ssl/private/apache.key -out ~/apache.csr
# TODO do you even sign, bro?
```

Now update the virtual hosts file `/etc/apache2/sites-enabled/vhosts.conf` to actually use the certficate.

```
<VirtualHost *:443>
  ServerName manual.mi.hdm-stuttgart.de
  DocumentRoot /usr/share/doc/apache2-doc/manual

  SSLEngine On
  SSLCertificateFile /etc/ssl/certs/apache.crt
  SSLCertificateKeyFile /etc/ssl/private/apache.key
</VirtualHost>
```

## LDAP authentication

// TODO

## MySQL Database

// TODO

## Publish our documentation

// TODO