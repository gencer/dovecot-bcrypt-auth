#!/usr/bin/env perl

package AccessDatabase;

use strict;
use warnings;
use DBI;
use Data::Dumper;

my ($respOk, $respUnacceptable, $respMisused, $respTempFailure) = (0, 1, 2, 111);

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

    # Define the connection info to the db. Port is optional and it should only be added if it isn't 'undef'
    my $dsn = 'DBI:' . $driver . ':database=' . $db;
    $dsn   .= (defined $host) ? ':host=' . $host : exit($respTempFailure);
#    $dsn   .= (length($port) >= 1) ? ':port=' . $port : print ('No port defined');

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
    $dbh = $conn->prepare($query) or print $dbh->errstr();

    $dbh->bind_param(1, $username) or print $dbh->errstr();
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
        exit($respUnacceptable);
    }
}

1;

