# Apache

## Installing

```bash
aptitude install apache2
```

Upon visiting [http://sdi5b.mi.hdm-stuttgart.de/](http://sdi5b.mi.hdm-stuttgart.de/) we are greeted with the apache default welcome page. When changing the file `/var/www/html/index.html`, the page content changes.

## Installing documentation

```bash
aptitude install apache2-doc
```

To find out where we can access our freshly installed documentation, we run `dpkg` to list all files installed by the package.

```bash
dpkg -L apache2-doc | less
```

There we look for apache configuration files and find `/etc/apache2/conf-available/apache2-doc.conf`, which includes an `Alias` from `/manual` to the directory of the manuals. Now we know, that we can access the manuals from [http://sdi5b.mi.hdm-stuttgart.de/manual](http://sdi5b.mi.hdm-stuttgart.de/manual).

## Configuring our own alias

We want to be able to call [http://sdi5b.mi.hdm-stuttgart.de/xyz123](http://sdi5b.mi.hdm-stuttgart.de/xyz123) and access the directory `/home/sdidoc` where we uploaded our documentation.

We need to place a configuration file setting up the alias `/etc/apache2/conf-enabled/sdidoc.conf`:

```aconf
Alias /xyz123 /home/sdidoc

<Directory "/home/sdidoc">
    Options Indexes FollowSymlinks
    AllowOverride None
    Require all granted
    AddDefaultCharset off
</Directory>
```

## Virtual hosts

When we configure our client machine to use our (private) nameserver we want to be able to call [http://xyz123.mi.hdm-stuttgart.de](http://xyz123.mi.hdm-stuttgart.de) and reach our documentation.

We define two DNS aliases `xy123` and `manual` for our virtual machine in `/etc/bind/zones/db.mi.hdm-stuttgart.de`:

```
...
manual.mi.hdm-stuttgart.de.    IN    CNAME    ns5.mi.hdm-stuttgart.de.
xyz123.mi.hdm-stuttgart.de.    IN    CNAME    ns5.mi.hdm-stuttgart.de.
```

Let's define the following vhosts in `/etc/apache2/sites-enabled/vhosts.conf` to link our subdomains to the directories the files live in:

```aconf
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

To test that everything works (without ~~fun~~ VPN problems) we connect via SSH  using the `-Y` flag to our second server. On the server, we set the nameserver to our first server in the `/etc/resolv.conf`. Now we can start `iceweasel` and connect to one of our newly configured subdomains. Seeing our web pages verifies that the DNS setting is correct.

## SSL / TLS Support

First off, we make sure OpenSSL is installed and create an own certificate authority (CA).

```bash
apt-get install openssl
/usr/lib/ssl/misc/CA.pl -newca
```

Just follow the dialogue, but note that the following fields are mandatory:

- PEM pass phrase (4+ characters)
- Common Name, which has to match the URL you later want see in the browser
- Passphrase for `cakey.pem`

```bash
# Generate a key for our server
openssl genrsa -out /etc/ssl/private/apache.key 2048

# Generate a certificate for our server
openssl req -new -x509 -key /etc/ssl/private/apache.key -days 365 -sha256 -out /etc/ssl/certs/apache.crt
```

Now update the virtual hosts file `/etc/apache2/sites-enabled/vhosts.conf` to actually use the certficate.

```aconf
<VirtualHost *:443>
  ServerName manual.mi.hdm-stuttgart.de
  DocumentRoot /usr/share/doc/apache2-doc/manual

  SSLEngine On
  SSLCertificateFile /etc/ssl/certs/apache.crt
  SSLCertificateKeyFile /etc/ssl/private/apache.key
</VirtualHost>
```

## LDAP authentication

We can limit access to directories / virtual hosts using LDAP users as well. To enable this, we simply have to add the following to a virtual host in `/etc/apache2/sites-enabled/vhosts.conf`:

```aconf
<VirtualHost *:80>
  ...
  
  Require valid-user
  AuthName "Private"
  AuthType Basic
  AuthBasicProvider ldap
  AuthLDAPURL ldap://sdi5b.mi.hdm-stuttgart.de/dc=betrayer,dc=com
</VirtualHost>
```

## MySQL Database

We want to run a MySQL database to run alongside our Apache server, as well as Adminer to manage it. First, we install the MySQL server, answering "Yes" to all questions.

```bash
apt-get install mysql-server
sudo mysql_install_db
sudo /usr/bin/mysql_secure_installation
```

Since Adminer runs on PHP, we have to install an extension for PHP to speak with the MySQL database:

```bash
apt-get install php5-mysqlnd
service apache2 restart
```

Lastly, we install Adminer, which is just downloading a single PHP file into a target directory.

```bash
curl https://www.adminer.org/static/download/4.2.5/adminer-4.2.5-mysql.php > adminer/index.php
```

Now, we can visit [http://sdi5b.mi.hdm-stuttgart.de/adminer](http://sdi5b.mi.hdm-stuttgart.de/adminer) and see the Adminer interface greet us, where we can log in with the database credentials.

## Publish our documentation

Since we host our documentation on Github, we just create a HTML page linking there in the required directory:

```bash
mkdir -p /var/www/html/doc
nano /var/www/html/doc/index.html
```

This will show up under the URL [http://sdi5b.mi.hdm-stuttgart.de/doc/](http://sdi5b.mi.hdm-stuttgart.de/doc/).