package Beam::Minion::Command::job;
our $VERSION = '0.017';
# ABSTRACT: Command to manage minion jobs

=head1 SYNOPSIS

    beam minion job [-R] [-f] [--remove] [-S <state>] [-q <queue>]
        [-t <task>] [-w] [-l <limit>] [-o <offset>] [<id>]

=head1 DESCRIPTION

This command manages the minion queue, lists jobs, lists workers, and
allows re-running failed jobs.

=head1 ARGUMENTS

=head2 <id>

The ID of a job or worker (with the C<-w> option) to display.

=head1 OPTIONS

=head2 C<-R> C<--retry>

Retry the given job by putting it back in the queue. See C<-f> to retry
the job in the current process.

=head2 C<-f> C<--foreground>

Retry the given jobs right away in the current process (useful for
debugging). See C<-R> to retry the job in the queue.

=head2 C<--remove>

Remove the given job(s) from the database.

=head2 C<< -S <state> >> C<< --state <state> >>

Only show jobs with the given C<state>. The state can be one of: C<inactive>,
C<active>, C<finished>, or C<failed>.

=head2 C<< -q <queue> >> C<< --queue <queue> >>

Only show jobs in the given C<queue>. Defaults to showing jobs in all queues.
The default queue for new jobs is C<default>.

=head2 C<< -t <task> >> C<< --task <task> >>

Only show jobs matching the given C<task>. L<Beam::Minion> task names are
C<< <container>:<service> >>.

=head2 C<-w> C<--workers>

List workers instead of jobs.

=head2 C<< -l <limit> >> C<< --limit <limit> >>

Limit the list to C<limit> entries. Defaults to 100.

=head2 C<< -o <offset> >> C<< --offset <offset> >>

Skip C<offset> jobs when listing. Defaults to 0.

=head1 ENVIRONMENT

=head2 BEAM_MINION

This variable defines the shared database to coordinate the Minion workers. This
database is used to queue the job. This must be the same for all workers
and every job running.

See L<Beam::Minion/Getting Started> for how to set this variable.

=head1 SEE ALSO

L<Beam::Minion>, L<Minion>

=cut

use Mojo::Base -base;
use Beam::Minion::Util qw( build_mojo_app );
use Minion::Command::minion::job;

has app => sub { build_mojo_app() };
sub run {
    my ( $self, @args ) = @_;
    my $cmd = Minion::Command::minion::job->new( app => $self->app );
    $cmd->run( @args );
}

1;
