package Beam::Minion;
our $VERSION = '0.003';
# ABSTRACT: A distributed task runner for Beam::Wire containers

=head1 SYNOPSIS

    beam minion worker <container>...
    beam minion run <container> <service> [<args>...]
    beam minion help

=head1 DESCRIPTION

L<Beam::Minion> is a distributed task runner. One or more workers are
created to run tasks, and then each task is sent to a worker to be run.
Tasks are configured by L<Beam::Wire> container files.

=head1 SEE ALSO

L<Beam::Wire>, L<Beam::Runner>, L<Minion>

=cut

use strict;
use warnings;



1;

