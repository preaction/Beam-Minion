package Beam::Runner::Command::minion;
our $VERSION = '0.009';
# ABSTRACT: Command for L<beam> to run distributed tasks

=head1 SYNOPSIS

    exit Beam::Runner::Command::minion->run( $cmd => @args );

=head1 DESCRIPTION

This is the entry point for the L<beam> command to delegate to
the appropriate L<Beam::Minion::Command> subclass.

=head1 SEE ALSO

The L<Beam::Minion> commands: L<Beam::Minion::Command::run>,
L<Beam::Minion::Command::worker>

=cut

use strict;
use warnings;
use Module::Runtime qw( use_module compose_module_name );

sub run {
    my ( $class, $cmd, @args ) = @_;
    if ( !$cmd ) {
        die "ERROR: No 'beam minion' sub-command specified\n";
    }
    my $cmd_class = compose_module_name( 'Beam::Minion::Command', $cmd );
    eval { use_module( $cmd_class ) };
    if ( $@ ) {
        if ( $@ =~ m{^Can't locate Beam/Minion/Command/} ) {
            die "ERROR: No such sub-command: $cmd\n";
        }
        die "Error loading module '$cmd_class': $@\n";
    }
    return $cmd_class->run( @args );
}

1;

