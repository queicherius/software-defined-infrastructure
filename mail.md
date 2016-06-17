# Mail

## Install and send to local Users

### Installing and testing postfix

To send email an email server is needed, so we are going to install `postfix` as a first step. We also add a user that we are going to use for testing email delivery.

```bash
apt-get install postfix
adduser mailuser # we use "123" as a password here
```

Now that we have a email server, let's check if it is up and running using telnet to connect to it:

```bash
telnet localhost 25
```

> **Note:** To exit postfix, you have to enter the "escape character" it shows at the start. In the default case that is `^]`, which means `CTRL + ]`. After that type `quit` to exit telnet.

Connected to the postfix server we can send an email to our test user:

1. `mail from:<email@domain.com>`
2. `rcpt to:mailuser`
3. `data`
4. `subject:Some email subject`
5. `Text for email body` (end the body with a `.` on an empty line)

If everything is configured and working correctly, the mail should show up for the user:

```bash
cat /var/mail/mailuser
```

### Using an alias

We can also setup an alias for our mail user to which we can send mail as well:

```bash
nano /etc/aliases
# myalias:mailuser
newaliases

# -> rcpt to:myalias
```

### Setting up MX records

We want to use the server as the mailserver for our local machine, so first we have to specify an `MX` record in the DNS settings of the server (`/etc/bind/zones/db.mi.hdm-stuttgart.de`):

```
        IN      MX      ns5.mi.hdm-stuttgart.de.
sdi5a   IN      A       ns5.mi.hdm-stuttgart.de.
sdi5b   IN      A       141.62.75.112
```

This `MX` record has to point to a valid `A` record previously defined. In our case we are using the same `A` record as for the nameserver settings. Also the "subdomain" we are using for emails has to be a correct `A` record as well.

> **Note:** The bottom `A` record is not neccessary for local testing, since the record for the local hostname is already defined in the `/etc/hosts`, but we need it later.

We also have to configure postfix to accept to allow for remote connections from any host (`/etc/postfix/main.cf`):

```aconf
# remove "mynetworks"
inet_interfaces = all
myhostname = sid5b.mi.hdm-stuttgart.de
mydestination # add "mi.hdm-stuttgart.de"
```

After restarting postfix (`service postfix restart`), we can connect from our local machine to the server using telnet:

```bash
telnet serverip 25
```

> **Note**: When trying to send email from one server to another a `relay access denied` error pops up. This is because we are trying to send a mail from outside the network to a domain that our server is not authoriative for, thus the recieve connector does not grant us the permission for sending/relaying.

## Authentication Setup and Virtual Users

### Add authentication to postfix

To authenticate users for sending emails, we need a [sasl](https://en.wikipedia.org/wiki/Simple_Authentication_and_Security_Layer) implementation, in our case we chose [dovecot](http://www.dovecot.org/):

```bash
apt-get install dovecot-imapd dovecot-pop3
```

Now, we have to configure dovecot to listen on the correct protocols (`/etc/dovecot/dovecot.conf`):

```aconf
# uncomment "listen"
protocol = pop3 imap
```

However, remote login via telnet with password is disabled by default, so we enable plaintext authentication in the `/etc/dovcot/conf.d/10-auth.conf`:

```aconf
disable_plaintext_auth = no
```

After restarting dovecot (`service dovecot restart`) we can connect authenticated:

```bash
telnet localhost 142
a login "mailuser" "123" # -> a OK
```

To connect dovecot with postfix, we setup the unix listener in `/etc/dovecot/conf.d/10-master.conf`:

```aconf
unix_listener /var/spool/postfix/private/auth {
  mode = 0666
  user = postfix
}
```

We also connect postfix with dovecot using the configuration in `/etc/postfix/main.cf`:

```
smtpd_recipient_restrictions = permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination, permit
smtpd_sasl_type = dovecot
smtpd_sasl_auth_enable = yes
smtpd_sasl_path = private/auth
```

Now we can use our server in a email client (we used Thunderbird) and as a proof that everything is configured correctly send and recieve emails (also from one server to another)!

### Virtual users and our own domain

// TODO