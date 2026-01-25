package Beam::Minion::Util;
our $VERSION = '0.019';
# ABSTRACT: Utility functions for Beam::Minion

=head1 SYNOPSIS

    use Beam::Minion::Util qw( minion );

    my $minion = minion();
    my %attrs = minion_attrs();

=head1 DESCRIPTION

This module contains helper routines for L<Beam::Minion>.

=head1 SEE ALSO

L<Beam::Minion>

=cut

use Mojo::Base -strict, -signatures;
use Exporter qw( import );
use Minion;
use Beam::Runner::Util qw( find_containers );
use Scalar::Util qw( weaken );
use Mojolicious;
use Mojo::Log;
use Beam::Wire;
use YAML::PP qw( LoadFile );
use Log::Any qw($LOG);

our @EXPORT_OK = qw( minion_init_args minion build_mojo_app );

our %BACKEND = (
    sqlite => 'SQLite',
    postgres => 'Pg',
    mongodb => 'MongoDB',
    mysql => 'mysql',
);

# The saved init args, in case we override them with Beam::Minion->init
our @INIT_ARGS = ();

=sub minion_init_args

    my %args = minion_init_args();

Get the arguments needed to initialize a new Minion instance by parsing
the C<BEAM_MINION> environment variable.

This environment variable can take a few forms:

=over

=item file://<path>

A path to a YAML file of configuration to read. Should contain a single key and value
which are the Minion backend to use and the argument to its constructor.

=item <url>

A simple backend URL like C<postgres://postgres@/test>,
C<sqlite:/tmp/minion.db>, C<mongodb://127.0.0.1:27017>, or
C<mysql://user@127.0.0.1/minion>. The following backends are supported:
L<Minion::Backend::SQLite>, L<Minion::Backend::Pg>,
L<Minion::Backend::MongoDB>, L<Minion::Backend::mysql>.

=item <backend>+<url>

A backend name and arguments, separated by C<+>, like
C<Storable+/tmp/minion.db>. Any backend may be used this way.

If your backend requires more arguments, you can separate them with
C<+>:

    # Configure the MySQL backend with a DBI DSN
    BEAM_MINION=mysql+dsn+dbi:mysql:minion

=back

=cut

sub minion_init_args {
    if (@_) {
      @INIT_ARGS = @_;
    }
    if (@INIT_ARGS) {
        return @INIT_ARGS;
    }
    die "You must set the BEAM_MINION environment variable to the Minion database URL.\n"
        . "See `perldoc Beam::Minion` for getting started instructions.\n"
        unless $ENV{BEAM_MINION};
    my ( $backend, $url );
    # If there's a `+`, we must be doing multi-args
    if ( $ENV{BEAM_MINION} =~ /^[^+:]+\+/ ) {
        @INIT_ARGS = split /\+/, $ENV{BEAM_MINION};
        return @INIT_ARGS;
    }
    my ( $schema ) = $ENV{BEAM_MINION} =~ /^([^:]+)/;
    # Load config from a YAML file
    if ($schema eq 'file') {
      my ( undef, $path ) = split '://', $ENV{BEAM_MINION};
      @INIT_ARGS = (LoadFile($path))[0]->%*;
      return @INIT_ARGS;
    }
    @INIT_ARGS = ($BACKEND{ $schema }, $ENV{BEAM_MINION});
    return @INIT_ARGS;
}

=sub minion

    my $minion = minion();

Get a L<Minion> instance as configured by the C<BEAM_MINION> environment
variable (parsed by L</minion_init_args>).

=cut

sub minion {
    return Minion->new( minion_init_args );
}

=sub build_mojo_app

Build the L<Mojolicious> app that contains the L<Minion> plugin
(L<Mojolicious::Plugin::Minion>) and tasks. This can then be given to
one of the L<Minion::Command> classes to execute commands.

=cut

sub build_mojo_app {
    my $app = Mojolicious->new;
    # Remove Mojo::Log from STDERR so that we don't double-log
    $app->log(Mojo::Log->new(handle => undef));
    # Forward Mojo::Log logs to the Log::Any logger, so that from there
    # they will be forwarded to OpenTelemetry.
    # Modules should prefer to log with Log::Any because it supports
    # structured logging.
    $app->log->on( message => sub ( $, $level, @lines ) {
      $LOG->$level(@lines);
    });

    push @{$app->commands->namespaces}, 'Minion::Command';

    my $minion = minion();
    $app->helper(minion => sub {$minion});

    my %container = find_containers();
    for my $container_name ( keys %container ) {
        my $path = $container{ $container_name };
        my $wire = Beam::Wire->new( file => $path );
        my $config = $wire->config;
        for my $service_name ( keys %$config ) {
            next unless $wire->is_meta( $config->{ $service_name }, 1 );
            my $task_name = "$container_name:$service_name";
            $minion->add_task( $task_name => sub {
                my ( $job, @args ) = @_;
                local $LOG->context->{task} = $task_name;
                local $LOG->context->{job} = $job->id;
                $LOG->info('Running task');
                my $wire = Beam::Wire->new( file => $path );

                local $@;
                my $obj = eval { $wire->get( $service_name, lifecycle => 'factory' ) };
                if ( my $error = $@ ) {
                    $LOG->error('Error getting runnable service', { service => $service_name, error => $error });
                    return $job->fail( { error => $error } );
                }

                local $@;
                my $exit = eval { $obj->run( @args ) };
                if ( my $error = $@ ) {
                    $LOG->error('Error running task', { error => $error });
                    return $job->fail( { error => $error } );
                }

                my $method = $exit ? 'fail' : 'finish';
                $LOG->info('Task result', { exit => $exit, state => $method });
                $job->$method( { exit => $exit } );
            } );
        }
        undef $wire;
    }

    return $app;
}

1;
