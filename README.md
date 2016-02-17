# dovecot-bcrypt-auth
A middleware script for dovecot servers authenticating against bcrypt passwords stored in a mysql server

## Dependencies
 - Crypt::Eksblowfish
 - DBI
 - DBD::Mysql (or your driver of choice)
 - Unix::Syslog
 - Yaml::XS
 
On Gentoo systems, you can install all of the dependencies with the following:

```sudo emerge -av dev-perl/Crypt-Eksblowfish dev-perl/DBI dev-perl/dbd-mysql dev-perl/Unix-Syslog dev-perl/YAML-LibYAML```
