# dovecot-bcrypt-auth
A middleware script for dovecot servers authenticating against bcrypt passwords stored in a mysql server

## Dependencies
 - Crypt::Eksblowfish
 - DBI
 - DBD::Mysql (or your driver of choice)
 - Path::Class
 - Unix::Syslog
 - Yaml::XS
 
On Gentoo systems, you can install all of the dependencies with the following:

```
sudo emerge -av dev-perl/Crypt-Eksblowfish dev-perl/DBI dev-perl/dbd-mysql dev-perl/Path-Class
                dev-perl/Unix-Syslog dev-perl/YAML-LibYAML
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
    driver = prefetch
}

userdb {
    driver = sql
    args   = /etc/dovecot/dovecot-sql.conf.ext
}
```

Then in `/etc/dovecot/dovecot-sql.conf.ext`, you'll need something like the following:

```
driver      = mysql
connect     = host=localhost dbname=database user=dbuser password=dbpassword
user_query  = SELECT 5000 as uid, 5000 as gid, email as user FROM virtual_users WHERE email='%u';
```

The `SELECT 5000 as uid, 5000 as gid` part of the query is the uid and gid of the virtual user (the user you
created for /var/mail/vhosts or similar).

## Configuration
The first thing you'll need to do after grabbing this script is edit `$configuration` in `dovecot-bcrypt-auth`.
This **must** be a full path to your configuration file.

```
my $configuration = '/etc/dovecot_bcrypt_auth.yaml';
```

Next you can edit the configuration file itself. Below I have provided an example:

```
driver: mysql
connection:
    # This is the name of the database you wish to connection to.
    database: testing
    host:     localhost

    # Feel free to leave port blank
    port:

userCredentials:
    username: dbuser
    password: dbpasswd

queryParameters:
    # Edit this as you see fit. The script however IS especting a username and password in the form of:
    #  - Username: username@domain
    #  - Password: password
    query:    'SELECT password FROM ? WHERE username = ?'

    # This will be placed into the first ? in the query field
    table:    users

shellVariables:
    # Please ensure these are the virtual users uid and gid (the owner of what you set as `home`)
    userdb_uid: 5000
    userdb_gid: 5000

    # This variable will be appended as the following at run time: /var/mail/vhosts/{domain}/{username}
    # This is extracted from the users login information
    home:       /var/mail/vhosts
