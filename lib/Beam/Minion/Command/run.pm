package Beam::Minion::Command::run;
our $VERSION = '0.013';
# ABSTRACT: Command to enqueue a job on Beam::Minion job queue

=head1 SYNOPSIS

    beam minion run [-d <delay>] [-a <attempts>] [-p <priority]
        <container> <service> [<args>...]

=head1 DESCRIPTION

This command adds a job to the L<Minion> queue to execute the given
C<service> from the given C<container>.

In order for the job to run, you must run a Minion worker using the
L<beam minion worker command|Beam::Minion::Command::worker>.

=head1 ARGUMENTS

=head2 container

The container that contains the task to run. This can be an absolute
path to a container file, a relative path from the current directory, or
a relative path from one of the directories in the C<BEAM_PATH> environment
variable (separated by C<:>).

=head2 service

The service that defines the task to run. Must be an object that consumes
the L<Beam::Runner> role.

=head1 OPTIONS

=head2 delay

The amount of time, in seconds, to delay the start of the job (from now).
Defaults to C<0>.

=head2 attempts

The number of times to automatically retry the job if it fails.
Subsequent attempts will be delayed by an increasing amount of time
(calculated by C<(retries ** 4) + 15>).

=head2 priority

The job's priority. Higher priority jobs will be run first. Defaults to C<0>.

=head1 ENVIRONMENT

=head2 BEAM_MINION

This variable defines the shared database to coordinate the Minion workers. This
database is used to queue the job. This must be the same for all workers
and every job running.

See L<Beam::Minion/Getting Started> for how to set this variable.

=head2 BEAM_PATH

This variable is a colon-separated list of directories to search for
containers.

=head1 SEE ALSO

L<Beam::Minion>, L<Minion>

=cut

use strict;
use warnings;
use Beam::Minion;
use Getopt::Long qw( GetOptionsFromArray );

sub run {
    my ( $class, $container, $service_name, @args ) = @_;
    GetOptionsFromArray( \@args, \my %opt,
        'delay|d=i',
        'attempts|a=i',
        'priority|p=i',
    );
    Beam::Minion->enqueue( $container, $service_name, \@args, \%opt );
}

1;
