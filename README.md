# dovecot-bcrypt-auth
A middleware script for dovecot servers authenticating against bcrypt passwords stored in a mysql server

## Dependencies
 - Crypt::Eksblowfish
 - DBI
 - DBD::Mysql (or your driver of choice)
 - Unix::Syslog
 - Yaml::XS
 
On Gentoo systems, you can install all of the dependencies with the following:

```
sudo emerge -av dev-perl/Crypt-Eksblowfish dev-perl/DBI dev-perl/dbd-mysql dev-perl/Unix-Syslog dev-perl/YAML-LibYAML
```
## Using this script
As this script stands, it doesn't work with the dovecot `prefetch` driver. The way this worked for me was by
configuring `/etc/dovecot/conf.d/auth-sql.conf.ext` as follows:

```
passdb {
    driver = checkpassword
    args   = /path/to/script
}

userdb {
    driver = static
    args   = uid=vmail gid=vmail home=/var/mail/vhosts/%d/%n
}

userdb {
    driver = sql
    args   = /etc/dovecot/dovecot-sql.conf.ext
}
```

Then in `/etc/dovecot/dovecot-sql.conf.ext`, you'll need something like the following:

```
driver  mysql
connect = host=localhost dbname=database user=dbuser password=dbpassword
user_query  = SELECT 5000 as uid, 5000 as gid, email as user FROM virtual_users WHERE email='%u';
```

The `SELECT 5000 as uid, 5000 as gid` part of the query is the uid and gid of the virtual user (the user you
created for /var/mail/vhosts or similar).
