package Beam::Minion::Command::worker;
our $VERSION = '0.001';
# ABSTRACT: Command to run a Beam::Minion worker

=head1 SYNOPSIS

    beam minion worker <container>

=head1 DESCRIPTION

This command takes a L<Beam::Wire> container (optionally searching
C<BEAM_PATH> a la L<Beam::Runner>) and starts a L<Minion::Worker> worker that
will run any service inside.

Service jobs are added to the queue using the L<beam minion run
command|Beam::Minion::Command::run>.

=head1 SEE ALSO

L<Beam::Minion>, L<Minion>

=cut

use strict;
use warnings;
use Beam::Wire;
use Beam::Runner::Util qw( find_container_path );
use Minion;
use Minion::Command::minion::worker;

sub run {
    my ( $class, $container ) = @_;
    my $minion = Minion->new( split /\+/, $ENV{BEAM_MINION} );
    my $path = find_container_path( $container );
    my $wire = Beam::Wire->new( file => $path );
    my $config = $wire->config;
    for my $name ( keys %$config ) {
        next unless $wire->is_meta( $config->{ $name }, 1 );
        $minion->add_task( $name => sub {
            my ( $job, @args ) = @_;
            my $obj = $wire->get( $name );
            my $exit = $obj->run( @args );
            my $method = $exit ? 'fail' : 'finish';
            $job->$method( { exit => $exit } );
        } );
    }
    my $cmd = Minion::Command::minion::worker->new( app => $minion );
    $cmd->run;
}

1;
