#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use POE;

my @log;

{
    package Foo;
    use MooseX::POE;

    with qw(MooseX::POE::Aliased);

    event foo => sub {
        push @log, [ @_[ARG0 .. $#_ ] ];
    };
}

my $foo = Foo->new( alias => "blah" );

POE::Session->create(
    inline_states => {
        _start => sub {
            $_[KERNEL]->yield("blah");
        },
        blah => sub {
            $_[KERNEL]->post( blah => foo => "this" );
            $foo->alias("bar");
            $_[KERNEL]->post( bar => foo => "that" );
        },
    }
);

$poe_kernel->run;

is( scalar(@log), 2, "two events" );

is_deeply( $log[0], ["this"], "first event under alias 'blah'" );
is_deeply( $log[1], ["that"], "second event under alias 'bar'" );
