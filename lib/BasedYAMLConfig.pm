#!/usr/bin/env perl

package BasedYAMLConfig;

use strict;
use warnings;
use YAML::XS;

sub new
{
    my $class = shift;
    my $self = {
        _filename => shift,
    };

    bless($self, $class);

    return $self;
}

sub getConfig
{
    ## Expects: The location of the YAML file.
    # Load the YAML file and return the hash object
    my $self     = shift;
    my $filename = $self->{_filename};
    my $config = YAML::XS::LoadFile($filename);

    return $config;
}

sub setEnv
{
    ## Expects: The YAML object ($self), the domain name and the yaml object.
    # Prepare an array for writing to file descript 4. This will include:
    #   - userdb_uid        - userdb_gid        - userdb_home
    #   - AUTHENTICATED     - HOME              - EXTRA
    my $self         = shift;
    my $config       = shift;
    my $userString   = shift;
    my @return;

    my ($username, $domain) = split('@', $userString);
    my $userdb_uid    = $config->{shellVariables}->{userdb_uid};
    my $userdb_gid    = $config->{shellVariables}->{userdb_gid};
    my $userdb_home   = $config->{shellVariables}->{home};

    push(@return, 'userdb_uid='  . $userdb_uid);
    push(@return, 'userdb_gid='  . $userdb_gid);
    push(@return, 'userdb_home=' . $userdb_home);
    push(@return, 'HOME='        . $userdb_home);
    push(@return, 'EXTRA="userdb_uid userdb_gid userdb_home"');
    push(@return, 'AUTHENTICATED=2');

    return @return;
}

1;

