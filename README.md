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
```
