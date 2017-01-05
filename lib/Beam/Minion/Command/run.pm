package Beam::Minion::Command::run;
our $VERSION = '0.001';
# ABSTRACT: Command to enqueue a job on Beam::Minion job queue

=head1 SYNOPSIS

    beam minion run <container> <service> [<args>...]

=head1 DESCRIPTION

This command adds a job to the L<Minion> queue to execute the given
C<service> from the given C<container>.

In order for the job to run, you must run a Minion worker using the
L<beam minion worker command|Beam::Minion::Command::worker>.

=head1 SEE ALSO

L<Beam::Minion>, L<Minion>

=cut

use strict;
use warnings;
use Minion;

sub run {
    my ( $class, $container, $service_name, @args ) = @_;
    my $minion = Minion->new( split /\+/, $ENV{BEAM_MINION} );
    $minion->enqueue( $service_name, \@args );
}

1;
