# DNS

## Installing bind

Install the server and utilities.

```bash
apt-get install bind9 bind9utils
```

Configure the server startup, for ipv4 only (`-4`) running as the user "bind" (`-u bind`) in `/etc/default/bind9`.

```bash
OPTIONS="-4 -u bind"
```

Update the global options in `/etc/bind/named.conf.options`

```
options {
  directory "/var/cache/bind";

  // Enable recursive dns queries
  recursion no;

  // Listen on the private network only (local IP)
  listen-on { 141.62.75.112; };

  // Disable zone transfers becaues we don't have a
  // redundant infrastructure (primary / secondary dns)
  allow-transfer { none; };

  // Currently we don't want to forward requests to stable nameservers
  forwarders {
  };

  // Use the default settings for validation and ipv6
  dnssec-validation auto;
  auth-nxdomain no;
  listen-on-v6 { any; };
};
```

Reload the server to apply all configuration changes.

```bash
service bind9 reload
```

## Basic configuration

Create a folder for the zones we want to set up

```bash
mkdir /etc/bind/zones
```

Setup the forward lookup zone (hostname to ip) in `/etc/bind/zones/db.mi.hdm-stuttgart.de`

```
$TTL    604800
@       IN      SOA     ns5.mi.hdm-stuttgart.de. root.mi.hdm-stuttgart.de. (
                     2016040101         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;

; name servers - NS records
        IN      NS      ns5.mi.hdm-stuttgart.de.


; name servers - A records
ns5.mi.hdm-stuttgart.de.          IN      A       141.62.75.112
www5_1.mi.hdm-stuttgart.de.       IN      CNAME   ns5.mi.hdm-stuttgart.de
www5_2.mi.hdm-stuttgart.de.       IN      CNAME   ns5.mi.hdm-stuttgart.de
```

Set up the reverse lookup zone (ip to hostname) in `/etc/bind/zones/db.141.62.75`

```
$TTL    604800
@       IN      SOA     ns5.mi.hdm-stuttgart.de. root.mi.hdm-stuttgart.de. (
                     2016040101         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;

; name servers - NS records
      IN      NS      ns5.mi.hdm-stuttgart.de.

; PTR Records
104   IN      PTR     sdi5b.mi.hdm-stuttgart.de.
```

> **Note:** "Serial" denotes a version, which helps the secondary DNS recognize new zone files. The convention for naming this is `YYYYMMDDSS` with `SS` being a incrementing version number which has to be updated for every change.

Make bind9 aware of our newly configured zones in `/etc/bind/named.conf.local`

```
zone "mi.hdm-stuttgart.de" {
  type master;
  file "/etc/bind/zones/db.mi.hdm-stuttgart.de";
};

zone "75.62.141.in-addr.arpa" {
  type master;
  file "/etc/bind/zones/db.141.62.75";
};
```

Check if all the `named.conf*` files have a correct syntax (should return to the shell without any messages).

```bash
named-checkconf /etc/bind/named.conf.local
```

Reload the server to apply all configuration changes.

```bash
service bind9 reload
```

Check if the nameserver resolves the zones that we just added.

```bash
# The added name should resolve into the IP (forward lookup)
dig @141.62.75.112 sdi5b.mi.hdm-stuttgart.de
dig @141.62.75.112 www5_1.mi.hdm-stuttgart.de

# The added IP should resolve into the IP (reverse lookup)
dig @141.62.75.112 -x 141.62.75.112

# This should not resolve, since we don't have A name
# records for it and recursive dns queries are disabled
dig @141.62.75.112 spiegel.de
```

## Forwarders

// TODO

## Mail exchange record

// TODO