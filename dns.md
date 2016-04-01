# DNS

## Setting up bind9

Install the server and utilities.

```bash
apt-get install bind9 bind9utils
```

---

Configure the server startup, for ipv4 only (`-4`) running as the user "bind" (`-u bind`).

```bash
OPTIONS="-4 -u bind"
```

---

Update the global options in `/etc/bind/named.conf.options`

```
options {
  directory "/var/cache/bind";

  // Enable recursive dns queries
  recursion yes;

  // Listen on the private network only
  listen-on { 141.62.75.104; };

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

---

Create a folder for the zones we want to set up

```bash
mkdir /etc/bind/zones
```

Set up the forward lookup zone (hostname -> ip) in `/etc/bind/zones/db.mi.hdm-stuttgart.de`

```
;
; BIND data file 
;
$TTL    604800
@       IN      SOA     ns4.mi.hdm-stuttgart.de. root.mi.hdm-stuttgart.de. (
                     2016040101         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;

; name servers - NS records
        IN      NS      ns4.mi.hdm-stuttgart.de.


; name servers - A records
ns4.mi.hdm-stuttgart.de.          IN      A       141.62.75.104
www4.mi.hdm-stuttgart.de.         IN      A       141.62.75.104
```

Set up the reverse lookup zone (ip -> hostname) in `/etc/bind/zones/db.141.62.75`

```
; BIND reverse data file 
;
$TTL    604800
@       IN      SOA     ns4.mi.hdm-stuttgart.de. root.mi.hdm-stuttgart.de. (
                     2016040101         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;

; name servers - NS records
      IN      NS      ns4.mi.hdm-stuttgart.de.

; PTR Records
104   IN      PTR     sdi4a.mi.hdm-stuttgart.de.    ; 141.62.75.104
```

**Note:** "Serial" denotes a version, which helps the secondary DNS recognize new zone files. The convention for naming this is `YYYYMMDDSS` with `SS` being a incrementing version number.

---

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

---

Reload the server to apply all configuration changes.

```bash
service bind9 reload
```
