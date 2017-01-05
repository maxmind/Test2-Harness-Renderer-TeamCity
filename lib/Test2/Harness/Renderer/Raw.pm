package Test2::Harness::Renderer::Raw;
use strict;
use warnings;

our $VERSION = '0.000001';

use Test2::Formatter::EventStream;
use Test2::Util::HashBase qw/formatter/;

sub init {
    my $self = shift;
    $self->{+FORMATTER} ||= Test2::Formatter::EventStream->new();
}

sub listen {
    my $self = shift;
    sub {
        my $job   = shift;
        my $event = shift;
        print $job->id, q{ };
        $self->{+FORMATTER}->write( $event );
    }
}

sub summary {
}

1;
