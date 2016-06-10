# Nagios

## Installing

Our goal is to monitor the services of a application server using a different monitoring server. First, we have to install nagios on the monitoring server. This will ask for a password for the `nagiosadmin` user.

```bash
apt install nagios3 nagios-nrpe-plugin
```

You should now be able to call [http://monitoringserver.ip/nagios3]() and see the nagios dashboard, showing one host (the monitoring server itself) as running.

Then, we have to install the nrpe server on the application server. This allows the monitoring server to communicate remotely with the application server later on.

```bash
apt install nagios-nrpe-server
```

## Contact information

To get noticiations, we have to update the default user in `/etc/nagios3/conf.d/contacts_nagios2.cfg`:

```
define contact {
  contact_name            YourName
  email                   your-mail@your.provider
  # ...
}

# ...

define contactgroup{
  contactgroup_name       admins
  alias                   Nagios Administrators
  members                 YourName
}
```

You can check if your configuration is valid using `nagios3 -v /etc/nagios3/nagios.cfg`. After confirming everything looks okay, we can apply the configuration with `service nagios3 reload`.

To enable email notifications, nagios requires to add the following to `/etc/postfix/main.cf`:

```
strict_rfc821_envelopes = yes
```

## Configuring remote inspection

To add a new host, we copy the local configuration into a new configuration file for that server:

```bash
cp /etc/nagios3/conf.d/localhost_nagios2.cfg /etc/nagios3/conf.d/server02.cfg
```

Then we update the `host_name` everywhere to the hostname of the application server (in this case `sdi5b`) and update the `address` to match the ip adress of the application server (in this case `141.62.75.112`).

```
define host {
  use                     generic-host
  host_name               sdi5b
  alias                   localhost
  address                 141.62.75.112
  check_interval          1
}

# Check the available disk space
define service{
  use                     generic-service
  host_name               sdi5b
  service_description     Disk Space
  check_command           check_all_disks!20%!10%
}

# Check the number of currently logged in users
define service{
  use                     generic-service
  host_name               sdi5b
  service_description     Current Users
  check_command           check_users!20!50
}

# Check the number of currently running processes
define service{
  use                     generic-service
  host_name               sdi5b
  service_description     Total Processes
  check_command           check_procs!250!400
}

# Check the load
define service{
  use                     generic-service
  host_name               sdi5b
  service_description     Current Load
  check_command           check_load!5.0!4.0!3.0!10.0!6.0!4.0
}
```

We can apply the configuration once again with `service nagios3 reload`. After checking the tactical overview, we can see that the additional host is up. Clicking on the detail view, we can confirm the service status for load, users, disk space and processes on the application server as `OK`.

## Configuring "Apache" service

Now we want to monitor the status of the Apache service on the application server (and while we're at it, monitor SSH as well). We define new services for that in the `/etc/nagios3/conf.d/server02.cfg` configuration file:

```
# Check that Apache is running
define service {
  use                     generic-service
  host_name               sdi5b
  service_description     Apache HTTP
  check_command           check_http
}

# Check that SSH is running
define service {
  use                     generic-service
  host_name               sdi5b
  service_description     SSH
  check_command           check_ssh
}
```

We can apply the configuration once again with `service nagios3 reload`. After checking the overview, we can see the HTTP and SSH service appear as `PENDING` and then switch to `OK`. When shutting down Apache on the application server, the service status for Apache switches to `CRITICAL`.

## Configuring "ldap" service

Now we want to monitor that LDAP based https authentication as well as the LDAP server in general is functional on the application server. We define new services for that in the `/etc/nagios3/conf.d/server02.cfg` configuration file:

```
# Check if remote LDAP authentication with https works
define command {
  command_name            check_http
  command_line            check_http -u $ARG1$ -S -a $ARG2$
}

define service {
  use                     generic-service
  host_name               sdi5b
  service_description     LDAP Authentication
  check_command           check_http!/our-ldap-secured-path!username:password
}

# Check if the interally accessible LDAP server is running
define command {
  command_name            check_ldap
  command_line            check_ldap -H $HOSTADDRESS$ -b $ARG1$ -D $ARG2$ -P $ARG3$
}

define service {
  use                     generic-service
  host_name               sdi5b
  service_description     LDAP Server
  check_command           check_ldap!dc=betrayer,dc=com!cn=admin,dc=betrayer,dc=com!123
}
```

## Defining dependencies

Since LDAP authentication will not work when the monitoring server's LDAP server is down, authentication related warnings should be deferred until LDAP becomes available. We can configure that defining a Nagios dependency:

```
define servicedependency {
  host_name                      sdi5b
  service_description            LDAP Authentication
  dependent_host_name            sdi5b
  dependent_service_description  LDAP Server
}
```
