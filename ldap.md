# LDAP

## Browse an existing LDAP server

Connecting anonymously to an exising server with Apache Directory Studio can be easily achieved by adding a new connection with:

- **Network Parameter**
	- *Hostname:* ldap1.mi.hdm-stuttgart.de
	- *Port:* 389
	- *Encryption Method:* SSL (`ldaps://`)

When connecting as a authenticated user (in this case `dr044`) the following settings have to be set too:

- **Authentication**
	- *Authentication Method:* Simple authentication
	- *Bind DN:* `uid=dr044,ou=userlist,dc=hdm-stuttgart,dc=de`
	- *Bind Password:* *****

When connecting as a authenticated user, there is the permission to read more information as when connecting anonymously. In this case, the  enrollment number can be read.

## Set up a OpenLDAP server

We start off by installing `sladp` and its prerequisite `dialog`. While installing, the administrator password gets set in a dialog box.

```bash
aptitude install dialog
aptitude install slapd
```

Now, we can configure the server directory information tree (`betrayer.com`), distinguished name (`betrayer.com`), administrator password and database type (`MDB`) with running the following command:

```bash
dpkg-reconfigure slapd
```

## Populating your DIT

// TODO

## Testing a bind operation as non-admin

// TODO

## Accessing LDAP data by a mail client

// TODO

## LDAP configuration

// TODO

## Filter based search

// TODO

## Extending an existing entry

// TODO

## Providing web-based user management

// TODO

## Backup and recovery / restore

// TODO

## Replication

// TODO