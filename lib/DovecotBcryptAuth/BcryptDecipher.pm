#!/usr/bin/env perl

package DovecotBcryptAuth::BcryptDecipher;

use strict;
use warnings;
use Crypt::Eksblowfish::Bcrypt;

sub new
{
    my $class = shift;
    my $self  = {
        _hash     => shift,
        _password => shift,
    };

    bless($self, $class);

    return $self;
}

sub bcryptCompare
{
    ## Expects: The db hash and the 'freshly generated' hash.
    # Splits up the old and new hash then compares each character in both arrays against each other. If something
    # doesn't match, $bad gets incremented and that will lead to a script exit.
    my $self  = shift;
    my $fresh = shift;
    my $stale = $self->{_hash};

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
    my $self     = shift;
    my $password = $self->{_password};
    my ($type, $cost, $salt) = @_;

    my $settings  = $type . $cost . $salt;

    return Crypt::Eksblowfish::Bcrypt::bcrypt($password, $settings);
}

sub bcryptExtract
{
    ## Expects: The users bcrypt password from the db.
    # Breaks up the hash into the type, cost, salt and the hash value. These values are returned in an array.
    my $self = shift;
    my $password = $self->{_hash};

    my @password = split(//, $password);
    my $type     = join('', @password[0..2]);
    my $cost     = join('', @password[3..5]);
    my $salt     = join('', @password[6..28]);

    return ($type, $cost, $salt);
}

1;

