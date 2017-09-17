package Beam::Minion::Command::worker;
our $VERSION = '0.008';
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
use Beam::Wire;
use Beam::Runner::Util qw( find_containers );
use Beam::Minion::Util qw( minion );
use Scalar::Util qw( weaken );
use Mojolicious;
use Mojo::Log;
use Minion::Command::minion::worker;

sub run {
    my ( $class ) = @_;
    my $app = Mojolicious->new(
        log => Mojo::Log->new, # Log to STDERR
    );

    push @{$app->commands->namespaces}, 'Minion::Command';

    my $minion = minion();
    weaken $minion->app($app)->{app};
    $app->helper(minion => sub {$minion});

    my %container = find_containers();
    for my $container_name ( keys %container ) {
        my $path = $container{ $container_name };
        my $wire = Beam::Wire->new( file => $path );
        my $config = $wire->config;
        for my $service_name ( keys %$config ) {
            next unless $wire->is_meta( $config->{ $service_name }, 1 );
            $minion->add_task( "$container_name:$service_name" => sub {
                my ( $job, @args ) = @_;

                my $obj = eval { $wire->get( $service_name ) };
                if ( $@ ) {
                    return $job->fail( { error => $@ } );
                }

                my $exit = eval { $obj->run( @args ) };
                if ( $@ ) {
                    return $job->fail( { error => $@ } );
                }

                my $method = $exit ? 'fail' : 'finish';
                $job->$method( { exit => $exit } );
            } );
        }
        my $cmd = Minion::Command::minion::worker->new( app => $app );
        $cmd->run;
    }
}

1;
