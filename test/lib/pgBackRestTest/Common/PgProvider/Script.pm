####################################################################################################################################
# PgProvider/Script.pm - PostgreSQL provider that delegates to an external shell script
####################################################################################################################################
package pgBackRestTest::Common::PgProvider::Script;

####################################################################################################################################
# Perl includes
####################################################################################################################################
use strict;
use warnings FATAL => qw(all);
use Carp qw(confess);

####################################################################################################################################
# new
####################################################################################################################################
sub new
{
    my ($class, $hCfg) = @_;
    return bless {cfg => defined($hCfg) ? $hCfg : {}}, $class;
}

####################################################################################################################################
# repoSetup
####################################################################################################################################
sub repoSetup
{
    return '';
}

####################################################################################################################################
# installPg
####################################################################################################################################
sub installPg
{
    my ($self, $strOS, $strArch, $raVersions) = @_;

    my $hCfg = $self->{cfg};

    defined($hCfg->{repo})        or confess "pg-provider-config: 'repo' is required for Script provider";
    defined($hCfg->{'ref'})       or confess "pg-provider-config: 'ref' is required for Script provider";
    defined($hCfg->{buildScript}) or confess "pg-provider-config: 'buildScript' is required for Script provider";

    my $strRepo        = $hCfg->{repo};
    my $strRef         = $hCfg->{'ref'};
    my $strBuildScript = $hCfg->{buildScript};

    return
        "# Build custom PostgreSQL from source\n" .
        "    git clone --depth 1 --branch ${strRef} ${strRepo} /tmp/pg-provider-src && \\\n" .
        "    bash /tmp/pg-provider-src/${strBuildScript} && \\\n" .
        "    rm -rf /tmp/pg-provider-src";
}

1;
