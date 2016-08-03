# LDAP

## Browse an existing LDAP server

> Note: The following instructions assume the network of the server being public or being connected using a VPN

Connecting anonymously to an existing server with [Apache Directory Studio](https://directory.apache.org/studio/) can be easily achieved by adding a new connection with:

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

## Set up an OpenLDAP server

We start off by installing `sladp` and its prerequisite `dialog`. While installing, the administrator password gets set in a dialogue box.

```bash
aptitude install dialog
aptitude install slapd
```

Now, we can configure the server directory information tree (`betrayer.com`), distinguished name (`betrayer.com`), administrator password (`123`) and database type (`MDB`) with running the following command:

```bash
dpkg-reconfigure slapd
```

## Populating your DIT

First, we connect to our new LDAP server with Apache Directory Studio, using the "admin" credentials we created in the previous step.

- **Network Parameter**
    - *Hostname:* sdi5b.mi.hdm-stuttgart.de
    - *Port:* 389
    - *Encryption Method:* None
- **Authentication**
    - *Authentication Method:* Simple authentication
    - *Bind DN:* `cn=admin,dc=betrayer,dc=com`
    - *Bind Password:* 123

We can add new organisational units using the context menu on the `dc=betrayer,dc=com` node and choose "New" > "New Entry". We create an "Entry from Scratch" and use the `oganisationalUnit` and `uidObject` object classes. In the dialogue asking for the RDN, we choose the parent (which can be the root node OR another organisational unit) and set `ou = development`. After that, we only have to specify a uid in the following dialogue.

To add a new user, we can use the context menu on an organisational unit and choose "New" > "New Entry" as well. We choose "Entry from Scratch" and use the `inetOrgPerson` and `uidObject` object classes. We set the RDN to `uid = smith`. After that, we can add more attributes, like `mail`, `userPassowrd`, `givenName`, ... in the following dialogue.

After exporting the root node using "Export" > "LDIF Export" and specifying the search base to our root node, we get the following example structure:

```
version: 1

dn: dc=betrayer,dc=com
objectClass: organization
objectClass: dcObject
objectClass: top
dc: betrayer
o: betrayer.com

dn: cn=admin,dc=betrayer,dc=com
objectClass: organizationalRole
objectClass: simpleSecurityObject
cn: admin
userPassword:: e1NTSEF9Mkl3b29JTUhzeVJRWUpWNHVKOW9ZOFpZQndhb1EweFk=
description: LDAP administrator

dn: ou=departments,dc=betrayer,dc=com
objectClass: uidObject
objectClass: top
objectClass: organizationalUnit
ou: departments
uid: departments

dn: ou=software,ou=departments,dc=betrayer,dc=com
objectClass: uidObject
objectClass: top
objectClass: organizationalUnit
ou: software
uid: software

dn: ou=financial,ou=departments,dc=betrayer,dc=com
objectClass: uidObject
objectClass: top
objectClass: organizationalUnit
ou: financial
uid: financial

dn: ou=development,ou=departments,dc=betrayer,dc=com
objectClass: uidObject
objectClass: top
objectClass: organizationalUnit
ou: development
uid: development

dn: ou=testing,ou=departments,dc=betrayer,dc=com
objectClass: uidObject
objectClass: top
objectClass: organizationalUnit
ou: testing
uid: testing

dn: uid=smith,ou=software,ou=departments,dc=betrayer,dc=com
objectClass: uidObject
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
cn: Jim Smith
sn: Smith
uid: smith
givenName: Jim
mail: smith@betrayer.com
userPassword:: e3NoYX1RTDBBRldNSVg4TlJaVEtlb2Y5Y1hzdmJ2dTg9
``` 

## Testing a bind operation as non-admin

We can now log in with the user we created in the previous step:

- **Network Parameter**
    - *Hostname:* sdi5b.mi.hdm-stuttgart.de
    - *Port:* 389
    - *Encryption Method:* None
- **Authentication**
    - *Authentication Method:* Simple authentication
    - *Bind DN:* `uid=smith,ou=software,ou=departments,dc=betrayer,dc=com`
    - *Bind Password:* 456

That user can see the LDAP tree, but when adding a new entry the error `no write access to parent` gets thrown (as expected).

## Accessing LDAP data by a mail client

For our example, we are using Thunderbird:

1. Open the "Address Book"
2. "File" > "New" > "LDAP Directory"
3. Enter the needed options:
    - "Name" can be any arbitrary name
    - "Host" is `sdi5b.mi.hdm-stuttgart.de`
    - "Base DN" is `dc=betrayer,dc=com`
    - "Port" is the default `389`
    - "Bind DN" is `uid=smith,ou=software,ou=departments,dc=betrayer,dc=com`

Now, when searching email addresses, we get asked for the user password and can see the emails in the LDAP server. We can also right-click on the new address book, choose "Properties" > "Offline" and "Download Now" to download all available data for offline use.

## LDAP configuration

We want to change our server so that we can change the configuration using the database instead of a file based system. First off, we start by collecting the data we need:

```
ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config
```

The output shows us that the user on the configuration database we want to use, doesn't have a password and therefore limits access to `localhost`:

```
# {0}config, config
olcRootDN: cn=admin,cn=config

# {1}mdb, config
olcRootDN: cn=admin,dc=betrayer,dc=com
olcRootPW: {SSHA}2IwooIMHsyRQYJV4uJ9oY8ZYBwaoQ0xY
```

We create an `ldif` file with the changes (adding a password) we want to execute:

```
dn: olcDatabase={0}config,cn=config
add: olcRootPW
olcRootPW: {SSHA}2IwooIMHsyRQYJV4uJ9oY8ZYBwaoQ0xY
```

We can now send these changes to the database using the following command:

```
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f add_olcRootPW.ldif
```

We can now connect using the new admin user, and change the backend configuration of the LDAP database via Apache Directory Studio:

- **Network Parameter**
    - *Hostname:* sdi5b.mi.hdm-stuttgart.de
    - *Port:* 389
    - *Encryption Method:* None
- **Authentication**
    - *Authentication Method:* Simple authentication
    - *Bind DN:* `cn=admin,cn=config`
    - *Bind Password:* 123
- **Browser Options**
    - Untick "Get base DNs from Root DSE"
    - *Base DN:* `cn=config`

## Filter based search

Using the context menu, we can choose "Filter Children" and filter the entries using their properties:

- `(uid=b*)` for all entries where `uid` starts with `b`
- `(|(uid=*)(ou=d*))` for all entries where `uid` is set or `ou` starts with `d`

A full reference of the available filter options can be found [here](http://social.technet.microsoft.com/wiki/contents/articles/5392.active-directory-ldap-syntax-filters.aspx).

## Extending an existing entry

We want to add a `posixAccount` to the "smith" user and create a `ldif` file for it:

```
# DN of the entry we want to modify
dn: uid=smith,ou=software,ou=departments,dc=betrayer,dc=com

# The change type of this file: changing an entry
changetype: modify

# For every object class and attribute, we have to
# specify it first using "add" and then specifying it's value
add: objectClass
objectClass: posixAccount
-
add: gidNumber
gidNumber: 3
-
add: uidNumber
uidNumber: 7
-
add: homeDirectory
homeDirectory: /usr/smith
```

Since we didn't set up SSL on our server, we need to remove the `-Q` parameter from the previous `ldapmodify` command and instead use the following command:

```
ldapmodify -x -H ldapi:/// -D "cn=admin,dc=betrayer,dc=com" -w "123" -f changeuser.ldif
```

## Providing web-based user management

```
aptitude install ldap-account-manager
```

After installing the account manager, we have to update the configuration file located under `/var/lib/ldap-account-manager/config/lam.conf`:

```
admins: cn=admin,dc=betrayer,dc=com
treesuffix: dc=betrayer,dc=com
```

Now we can log into our web interface on `http://sdi5b.mi.hdm-stuttgart.de/lam` using the normal LDAP credentials `admin` and `123`. When we visit "Tree view", we can see and modify the same tree as in Apache Directory Studio.

## Backup and recovery / restore

We want to copy the data from one server to another. First, we export our data into a file using `slapcat`:

```
slapcat > slap-backup
```

After copying the file to another server, we delete the database on the other server and run `slapadd` to import the exported data:

```
service slapd stop
rm -rf /var/lib/ldap/*
slapadd -l slap-backup
service slapd start
```

We can now log into the other server and see our data copied over.

## Replication

[Click!](http://www.server-world.info/en/note?os=CentOS_6&p=ldap&f=8)

## Accessing LDAP by a Java™ application