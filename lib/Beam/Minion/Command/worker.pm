package Beam::Minion::Command::worker;
our $VERSION = '0.014';
# ABSTRACT: Command to run a Beam::Minion worker

=head1 SYNOPSIS

    beam minion worker

=head1 DESCRIPTION

This command takes all the L<Beam::Wire> containers located on the
C<BEAM_PATH> environment variable and starts a L<Minion::Worker> worker
that will run any services inside.

Service jobs are added to the queue using the L<beam minion run
command|Beam::Minion::Command::run>.

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
use Beam::Minion::Util qw( build_mojo_app );
use Minion::Command::minion::worker;

sub run {
    my ( $class, @args ) = @_;
    my $app = build_mojo_app();
    my $cmd = Minion::Command::minion::worker->new( app => $app );
    $cmd->run( @args );
}

1;
