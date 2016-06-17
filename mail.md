# Mail

## Install and send to local Users

### Installing and testing postfix

To send email an email server is needed, so we are going to install `postfix` as a first step. We also add a user that we are going to use for testing email delivery.

```bash
apt-get install postfix
adduser mailuser
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
```