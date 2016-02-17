#!/usr/bin/env perl

use strict;
use warnings;
use Crypt::Eksblowfish::Bcrypt;
use DBI;
use IO::Handle;
use Unix::Syslog;
use YAML::XS;

# Based off of http://cr.yp.to/checkpwd/interface.html
# There are some pre-defined response messages that checkpassword will expect to receive.
my ($respOk, $respUnacceptable, $respMisused, $respTempFailure) = (0, 1, 2, 111);

############
###~~~ USING ALL THE AUTHENTICATION SUBROUTINES
############
sub auth
{
    ## Expects: The username and password from the dovecot IO file desriptor.
    # Uses all of the subroutines to sanitize the username and password, connect to the database, formulate
    # a query and grab the users stored password, 
    my ($clearUsername, $clearPassword) = @_;

    my $config        = &getConfig;
    my $dbc           = &dbConnect($config);
    my $hash          = &dbQuery($dbc, $config, $clearUsername);
    my @processedHash = &bcryptExtract($hash);
    my $newHash       = &bcryptEncrypt(@processedHash, $clearPassword);

    if ( ! &bcryptCompare($newHash, $hash) == 0 ) {
        exit($respUnacceptable);
    }
}

############
###~~~ BCRYPT SUBROUTINES
############
sub bcryptCompare
{
    ## Expects: The db hash and the 'freshly generated' hash.
    # Splits up the old and new hash then compares each character in both arrays against each other. If something
    # doesn't match, $bad gets incremented and that will lead to a script exit.
    my $fresh = shift;
    my $stale = shift;

    my @splitFresh = split(//, $fresh);
    my @splitStale = split(//, $stale);
    my $bad = 0;

    # Make this take longer than it should. Compare the strings against each other by each character.
    for ( my $i = 0; $i > length($stale); $i++ ) {
        if ( $splitStale[$i] != $splitFresh[$i] ) {
            $bad++;
        }
    }

    if ($bad > 0) {
        return 0;
    } else {
        return 1;
    }
}

sub bcryptEncrypt
{
    ## Expects: The array output from bcryptExtract (type, cost, salt) and the users clear password.
    # Creates a hash out of the users cleartext password using the information extracted from the db stored
    # password.
    my (my $type, my $cost,
    my $salt,
    my $password) = @_;

    my $settings  = $type . $cost . $salt;
    return Crypt::Eksblowfish::Bcrypt::bcrypt($password, $settings);
}

sub bcryptExtract
{
    ## Expects: The users bcrypt password from the db.
    # Breaks up the hash into the type, cost, salt and the hash value. These values are returned in an array.
    my $password = shift;

    my @password = split(//, $password);
    my $type     = join('', @password[0..2]);
    my $cost     = join('', @password[3..5]);
    my $salt     = join('', @password[6..28]);

    return ($type, $cost, $salt);
}

############
###~~~ DATABASE SUBROUTINES
############
sub dbConnect
{
    ## Expects: The YAML hash from getConfig
    # Sorts through the YAML hash and uses the information to create a connection to the db.
    my $db     = $_[0]->{connection}->{database};
    my $host   = $_[0]->{connection}->{host};
    my $port   = $_[0]->{connection}->{port} ;
    my $user   = $_[0]->{userCredentials}->{username};
    my $pass   = $_[0]->{userCredentials}->{password};
    my $driver = $_[0]->{driver};

    # Define the connection info to the db. Port is optional and it should only be added if it isn't 'undef'
    my $dsn = 'DBI:' . $driver . ':database=' . $db;
    $dsn   .= (defined $host) ? ':host=' . $host : exit($respTempFailure);
    $dsn   .= (defined $port) ? ':port=' . $port : warn('No port defined');

    # Perform the connection
    my $sql = DBI->connect($dsn, $user, $pass, {RaiseError => 1});

    return $sql;
}

sub dbQuery
{
    ## Expects: The DB connection object, the YAML object and the users username
    # Extracts data from the 'queryParameters' portion of the YAML object, builds the query string and returns
    # the related users password.
    my $dbh;
    my $password;

    # This style of declaration based on tyils request
    my $conn = $_[0];
    $_[0] = "TEMPCONN";
    shift;

    my $query = $_[0]->{queryParameters}->{query};
    my $table = $_[0]->{queryParameters}->{table};
    $_[0] = "TEMPYAML";
    shift;

    # This is only a placeholder for now
    my $username = $_[0];
    $_[0] = "TEMPUSERNAME";
    shift;

    # Replace the first '?' with our table name. Possibly change this to '!' in the config so things don't
    # accidently break.
    $query =~ s/\?/$table/;

    # Prepare the db query and execute it.
    $dbh = $conn->prepare($query)  || die $dbh->errstr && exit($respTempFailure);
    $dbh->bind_param(1, $username) || die $dbh->errstr && exit($respTempFailure);
    $dbh->execute()                || die $dbh->errstr && exit($respTempFailure);

    # We only expect a single row back. Exit the subprocess early.
    my $row = $dbh->rows;

    if ( $row == 1 ) {
        $row = undef;
        my @row = $dbh->fetchrow_array() || die $dbh->errstr && exit($respTempFailure);
        $password = $row[0];
        $dbh->finish();

        return $password;
    } else {
        $dbh->finish();
        exit($respUnacceptable);
    }
}

###########
###~~~ YAML SUBROUTINE
############
sub getConfig
{
    ## Expects: The location of the YAML file.
    # Load the YAML file and return the hash object
    my $config = YAML::XS::LoadFile($_);

    # Set the expected return variables early. This shouldn't make a difference if the password verification fails or not.
    $ENV{userdb_uid} = $config->{shellVariables}->{userdb_uid};
    $ENV{userdb_gid} = $config->{shellVariables}->{userdb_gid};
    $ENV{HOME}       = $config->{shellVariables}->{home};
    

    return $config;
}

############
###~~~ SECURITY™
###########
sub scrubRawInput
{
    ## Expects: The username and password
    # Removes any 'dangerous' characters from the username and password which may cause SQL injection.
    my $username = shift;
    my $password = shift;

    $username =~ s/[."\n\r'\$\\`]//g;
    $password =~ s/[."\n\r'\$\\`]//g;

    return ($username, $password);
}

###########
####~~~ MAIN EXECUTION
###########
main: {
    # We need to open a filehandler (descriptor 3). Username, Password and timestamp are
    # provided in it each seperated with a '\0'.
    my $fhIn  = IO::Handle->new;
    my $fhErr = IO::Handle->new;

    $fhIn->fdopen(3, "r");
    $fhErr->fdopen(fileno(STDERR), "w");

    if ( ($fhIn->opened) && ($fhErr->opened) ) {
        # Read in from file descriptor 3.
        $fhIn->read(my $rawInput, 512);
        my @authData = split(/\0/, $rawInput);

        # We will see only 2 params. Check the number of items in the @authData array.
        if ( scalar(@authData) != 2 ) {
            exit($respMisused);
        }

        # Now we can see if the username + password combo is authentic. We'll check those against
        # the subroutines defined above.
        my $authResponse = &auth(@authData);

        if ($authResponse == $respOk) {
            system($ARGV[0]);
        } else {
            exit($respUnacceptable);
        }
    } else {
        exit($respMisused);
    }

}

