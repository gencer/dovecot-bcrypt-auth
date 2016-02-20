#!/usr/bin/env perl

package DovecotBcryptAuth::AccessDatabase;

use strict;
use warnings;
use DBI;
use Data::Dumper;

our %RESPONSE;

sub new
{
    my $class = shift;
    my $self  = {
        _config   => shift,
        _username => shift,
        _password => shift
    };

    bless($self, $class);
    return $self;
}


sub dbConnect
{

    ## Expects: The YAML hash from getConfig
    # Sorts through the YAML hash and uses the information to create a connection to the db.
    my $self   = shift;
    my $db     = $self->{_config}->{connection}->{database};
    my $host   = $self->{_config}->{connection}->{host};
    my $port   = $self->{_config}->{connection}->{port} ;
    my $user   = $self->{_config}->{userCredentials}->{username};
    my $pass   = $self->{_config}->{userCredentials}->{password};
    my $driver = $self->{_config}->{driver};

    # Define the connection info to the db. Port and Host can be left with blank, they'll contain an empty string if so.
    my $dsn = 'DBI:' . $driver . ':database=' . $db;
    $dsn   .= ':host=' . $host if (length($host) > 0);
    $dsn   .= ':port=' . $port if (length($port) > 0);

    # Perform the connection
    my $sql = DBI->connect($dsn, $user, $pass, {RaiseError => 1});

    return $sql;
}

sub dbQuery
{
    ## Expects: The DB connection object, the YAML object and the users username
    # Extracts data from the 'queryParameters' portion of the YAML object, builds the query string and returns
    # the related users password.
    my $self     = shift;
    my $conn     = shift;
    my $query    = $self->{_config}->{queryParameters}->{query};
    my $table    = $self->{_config}->{queryParameters}->{table};
    my $username = $self->{_username};
    my $dbh;
    my $password;

    # Replace the first '?' with our table name. Possibly change this to '!' in the config so things don't
    # accidently break.
    $query =~ s/\?/$table/;

    # Prepare the db query and execute it.
    $dbh = $conn->prepare($query);

    $dbh->bind_param(1, $username);
    $dbh->execute() or print $dbh->errstr();

    # We only expect a single row back. Exit the subprocess early.
    my $row = $dbh->rows;

    if ( $row == 1 ) {
        $row      = undef;
        my @row   = $dbh->fetchrow_array();
        $password = $row[0];
        $dbh->finish();

        return $password;
    } else {
        $dbh->finish();
        exit($RESPONSE{unacceptable});
    }
}

1;

