package Beam::Minion;
our $VERSION = '0.007';
# ABSTRACT: A distributed task runner for Beam::Wire containers

=head1 SYNOPSIS

    # Command-line interface
    export BEAM_MINION=sqlite://test.db
    beam minion worker
    beam minion run <container> <service> [<args>...]
    beam minion help

    # Perl interface
    local $ENV{BEAM_MINION} = 'sqlite://test.db';
    Beam::Minion->enqueue( $container, $service, @args );

=head1 DESCRIPTION

L<Beam::Minion> is a distributed task runner. One or more workers are
created to run tasks, and then each task is sent to a worker to be run.
Tasks are configured as L<Beam::Runnable> objects by L<Beam::Wire>
container files.

=head1 GETTING STARTED

=head2 Configure Minion

To start running your L<Beam::Runner> jobs, you must first start
a L<Minion> worker with the L<beam minion
worker.command|Beam::Minion::Command::worker>.  Minion requires
a database to coordinate workers, and communicates with this database
using a L<Minion::Backend>.

The supported Minion backends are:

=over

=item *

L<Minion::Backend::SQLite> - C<< sqlite:<db_path> >>

=item *

L<Minion::Backend::Pg> - C<< postgresql://<user>:<pass>@<host>/<database> >>

=item *

L<Minion::Backend::mysql> - C<< mysql://<user>:<pass>@<host>/<database> >>

=item *

L<Minion::Backend::MongoDB> - C<< mongodb://<host>:<port> >>

=back

Once you've picked a database backend, configure the C<BEAM_MINION>
environment variable with the URL. Minion will automatically deploy the
database tables it needs, so be sure to allow the right permissions (if
the database has such things).

In order to communicate with Minion workers on other machines, it will
be necessary to use a database accessible from the network (so, not
SQLite).

=head2 Start a Worker

Once the C<BEAM_MINION> environment variable is set, you can start
a worker with C<< beam minion worker >>. Each worker can run jobs from
all the containers it can find from the C<BEAM_PATH> environment
variable. Each worker will run up to 4 jobs concurrently.

=head2 Spawn a Job

Jobs are spawned with C<< beam minion run <container> <service> >>.
The C<service> must be an object that consumes the L<Beam::Runnable>
role. C<container> should be a path to a container file and can be
an absolute path, a path relative to the current directory, or a
path relative to one of the paths in the C<BEAM_PATH> environment
variable (separated by C<:>).

You can queue up jobs before you have workers running. As soon as
a worker is available, it will start running jobs from the queue.

=head1 SEE ALSO

L<Beam::Wire>, L<Beam::Runner>, L<Minion>

=cut

use strict;
use warnings;
use Beam::Minion::Util qw( minion );

=sub enqueue

    Beam::Minion->enqueue( $container_name, $task_name, @args );

Enqueue the task named C<$task_name> from the container named C<$container_name>.
The C<BEAM_MINION> environment variable must be set.

=cut

sub enqueue {
    my ( $class, $container, $task, @args ) = @_;
    my $minion = minion();
    $minion->enqueue( "$container:$task", \@args );
}

1;

