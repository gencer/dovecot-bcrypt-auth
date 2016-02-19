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
    ## Expects: The YAML object ($self) and the domain username.
    # Set the necessary fields to make this script compliant with the checkpassword API
    my $self         = shift;
    my $userString   = shift;
    my $config       = shift;
    my ($username, $domain) = split('@', $userString);

    # We're using virtual domains. Each virtual user should have a HOME under /var/mail/{domain}/{username}
    $ENV{HOME}       = $config->{shellVariables}->{home} .
                        '/' . $domain . '/' . $username;

    # Set the mail users uid and gid. We add these values to $ENV{EXTRA}
    my $userdb_uid   = $config->{shellVariables}->{userdb_uid};
    my $userdb_gid   = $config->{shellVariables}->{userdb_gid};
    $ENV{userdb_uid} = $userdb_uid;
    $ENV{userdb_gid} = $userdb_gid;
    $ENV{EXTRA}      = $userdb_uid . ' ' .  $userdb_gid;

    # Lastly we need to acknowledge that this script is 'authentic' by changing $ENV{AUTHORIZED} to '2'
    #$ENV{AUTHORIZED} = 2;

    return 1;
}

1;

