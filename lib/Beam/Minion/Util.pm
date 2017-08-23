package Beam::Minion::Util;
our $VERSION = '0.007';
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

use strict;
use warnings;
use Exporter qw( import );
use Minion;

our @EXPORT_OK = qw( minion_init_args minion );

our %BACKEND = (
    sqlite => 'SQLite',
    postgres => 'Pg',
    mongodb => 'MongoDB',
    mysql => 'mysql',
);

=sub minion_init_args

    my %args = minion_init_args();

Get the arguments needed to initialize a new Minion instance by parsing
the C<BEAM_MINION> environment variable.

This environment variable can take a few forms:

=over

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
    die "You must set the BEAM_MINION environment variable to the Minion database URL.\n"
        . "See `perldoc Beam::Minion` for getting started instructions.\n"
        unless $ENV{BEAM_MINION};
    my ( $backend, $url );
    if ( $ENV{BEAM_MINION} =~ /^[^+:]+\+/ ) {
        my @args = split /\+/, $ENV{BEAM_MINION};
        return @args;
    }
    my ( $schema ) = $ENV{BEAM_MINION} =~ /^([^:]+)/;
    return $BACKEND{ $schema }, $ENV{BEAM_MINION};
}

=sub minion

    my $minion = minion();

Get a L<Minion> instance as configured by the C<BEAM_MINION> environment
variable (parsed by L</minion_init_args>).

=cut

sub minion {
    return Minion->new( minion_init_args );
}


1;
