####################################################################################################################################
# PgProvider/Pgdg.pm - PostgreSQL provider using PGDG packages
####################################################################################################################################
package pgBackRestTest::Common::PgProvider::Pgdg;

####################################################################################################################################
# Perl includes
####################################################################################################################################
use strict;
use warnings FATAL => qw(all);
use Carp qw(confess);

use pgBackRestTest::Common::VmTest;

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
    my ($self, $strOS, $strArch) = @_;

    my $oVm = vmGet();
    my $strScript = '';

    if ($oVm->{$strOS}{&VM_OS_BASE} eq VM_OS_BASE_RHEL)
    {
        $strScript .=
            "# Install PostgreSQL packages\n" .
            "    rpm --import https://download.postgresql.org/pub/repos/yum/keys/RPM-GPG-KEY-PGDG && \\\n";

        if ($strOS eq VM_RH8)
        {
            $strScript .=
                "    rpm -ivh \\\n" .
                "        https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-" . hostArch() . "/" .
                    "pgdg-redhat-repo-latest.noarch.rpm && \\\n" .
                "    dnf -qy module disable postgresql && \\\n";
        }
        elsif ($strOS eq VM_F44)
        {
            $strScript .=
                "    rpm -ivh \\\n" .
                "        https://download.postgresql.org/pub/repos/yum/reporpms/F-44-" . hostArch() . "/" .
                    "pgdg-fedora-repo-latest.noarch.rpm && \\\n" .
                "    yum -y install libcurl-devel && \\\n";
        }

        $strScript .= "    yum -y install postgresql-devel";
    }
    elsif ($oVm->{$strOS}{&VM_OS_BASE} eq VM_OS_BASE_DEBIAN)
    {
        $strScript .= "# Install PostgreSQL packages\n";

        if (vmPgRepo($strOS))
        {
            $strScript .=
                "    apt-get install -y --no-install-recommends postgresql-common && \\\n" .
                "    /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y && \\\n";
        }

        $strScript .=
            "    apt-get install -y --no-install-recommends postgresql-common libpq-dev && \\\n" .
            "    sed -i 's/^\\#create\\_main\\_cluster.*\$/create\\_main\\_cluster \\= false/' " .
                "/etc/postgresql-common/createcluster.conf";
    }

    return $strScript;
}

####################################################################################################################################
# installPg
####################################################################################################################################
sub installPg
{
    my ($self, $strOS, $strArch, $raVersions) = @_;

    my $oVm = vmGet();

    if (!defined($raVersions) || @{$raVersions} == 0 ||
        !($strArch eq VM_ARCH_AARCH64 || $strArch eq VM_ARCH_X86_64 || $strArch eq VM_ARCH_I386))
    {
        return '';
    }

    my $strScript = "# Install PostgreSQL\n";

    if ($oVm->{$strOS}{&VM_OS_BASE} eq VM_OS_BASE_RHEL)
    {
        $strScript .= "    yum -y install";
    }
    elsif ($oVm->{$strOS}{&VM_OS_BASE} eq VM_OS_BASE_DEBIAN)
    {
        $strScript .= "    apt-get install -y --no-install-recommends";
    }
    elsif ($oVm->{$strOS}{&VM_OS_BASE} eq VM_OS_BASE_ALPINE)
    {
        $strScript .= "    apk add --no-cache";
    }

    foreach my $strDbVersion (@{$raVersions})
    {
        if ($oVm->{$strOS}{&VM_OS_BASE} eq VM_OS_BASE_RHEL)
        {
            my $strDbVersionNoDot = $strDbVersion;
            $strDbVersionNoDot =~ s/\.//;

            $strScript .= " postgresql${strDbVersionNoDot}-server";

            if ($strDbVersion eq $raVersions->[-1])
            {
                $strScript .= " postgresql${strDbVersionNoDot}-devel";
            }
        }
        elsif ($oVm->{$strOS}{&VM_OS_BASE} eq VM_OS_BASE_DEBIAN)
        {
            # Disable PostgreSQL 18 on architectures that do not support it yet
            next if ($strDbVersion eq '18' &&
                !($strOS eq VM_U22 && ($strArch eq VM_ARCH_AARCH64 || $strArch eq VM_ARCH_X86_64)));

            $strScript .= " postgresql-${strDbVersion}";
        }
        elsif ($oVm->{$strOS}{&VM_OS_BASE} eq VM_OS_BASE_ALPINE)
        {
            $strScript .= " postgresql${strDbVersion}";
        }
    }

    return $strScript;
}

1;
