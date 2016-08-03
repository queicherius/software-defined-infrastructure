# DNS

> **Note:** If you are looking for the options of `bind`, [this website](http://www.zytrax.com/books/dns/ch7/statements.html) proved to be a good source of information.

## Installing bind

First, we have to install the server and utilities to run the DNS server.

```bash
apt-get install bind9 bind9utils
```

Next, we change the configuration in `/etc/default/bind9` to run the server for ipv4 only (`-4`) and using a specific user "bind" (`-u bind`) for it:

```bash
OPTIONS="-4 -u bind"
```

As the last step, we update the global options in `/etc/bind/named.conf.options`. Every option is explained by the accompanying comment.

```aconf
options {
  directory "/var/cache/bind";

  # Disable recursive DNS queries
  recursion no;

  # Listen on the private network only (local IP)
  listen-on { 141.62.75.112; };

  # Disable zone transfers, becaues we don't have a
  # redundant infrastructure (primary / secondary dns)
  allow-transfer { none; };

  # Currently we don't want to forward requests to stable nameservers
  forwarders {};

  # Use the default settings for validation and ipv6
  dnssec-validation auto;
  auth-nxdomain no;
  listen-on-v6 { any; };
};
```

We reload the server to apply all configuration changes.

```bash
service bind9 reload
```

## Basic configuration

Now that we have a up and running DNS server, we create a folder for the zones we want to set up our nameserver for.

```bash
mkdir /etc/bind/zones
```

We setup the forward lookup zone in `/etc/bind/zones/db.mi.hdm-stuttgart.de`. This maps hostnames to IP-Adresses.

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
www5_1.mi.hdm-stuttgart.de.       IN      CNAME   ns5.mi.hdm-stuttgart.de.
www5_2.mi.hdm-stuttgart.de.       IN      CNAME   ns5.mi.hdm-stuttgart.de.
```

We also have to set up the reverse lookup zone in `/etc/bind/zones/db.141.62.75`. This is the equivalent of the lookup zone we already set up and maps IP-Addresses to hostnames.

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

> **Note:** "Serial" denotes a version, which helps the secondary DNS recognise new zone files. The convention for naming this is `YYYYMMDDSS` with `SS` being an incrementing version number which has to be updated for every change.

With our zones configured, we have to make bind9 aware of them. We add our new zones in `/etc/bind/named.conf.local`

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

To check if all the `named.conf*` files have a correct syntax (should return to the shell without any messages) we can run

```bash
named-checkconf /etc/bind/named.conf.local
```

Once again, we reload the server to apply all configuration changes.

```bash
service bind9 reload
```

Now we can check if the nameserver resolves the zones that we just added.

```bash
# The added name resolves into the IP (forward lookup)
dig @141.62.75.112 sdi5b.mi.hdm-stuttgart.de
dig @141.62.75.112 www5_1.mi.hdm-stuttgart.de

# The added IP resolves into the IP (reverse lookup)
dig @141.62.75.112 -x 141.62.75.112

# This does not resolve since we don't have A name
# records for it and recursive DNS queries are disabled
dig @141.62.75.112 spiegel.de
```

## Forwarders

Due to the `recursion no` in the configuration, currently, only queries regarding objects within the defined zones are supported. To enable forwarding to "real" DNS servers, we configure the options in `/etc/bind/named.conf.options`.

```aconf
options {
  # ...
  
  # List of IP addresses to which queries will be forwarded
  forwarders {
    141.62.64.127;
    141.62.64.128;
    141.62.64.21;
  };
  
  # Send the query the forwarders
  forward first;
  
  # Allow for recursive queries from our non-secure DNS server
  dnssec-enable no;
  
  # ...
}
```

## Mail exchange record

Since we want to be able to send emails via our domain as well, we have to set up a MX record in `/etc/bind/zones/db.mi.hdm-stuttgart.de`. We already have a mail server provided by our system administrator, so we are going to use that.

```
; name servers - NS records
      IN      NS      ns5.mi.hdm-stuttgart.de.

; mail servers - MX records
      IN      MX 10   mx1.hdm-stuttgart.de.
```

After a restart with `service bind9 reload`, we can check our configuration using `nslookup`. The lookup should result in the configured A record.

```
nslookup
> set type=mx
> sdi5b.mi.hdm-stuttgart.de
```

> **Note:** We couldn't actually check if emails could be delivered, because the Firewall was filtering out emails out as a security measure for the already existing mail servers.