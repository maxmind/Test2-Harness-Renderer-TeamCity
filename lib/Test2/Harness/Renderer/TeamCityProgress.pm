package Test2::Harness::Renderer::TeamCityProgress;
use strict;
use warnings;

use Test2::Util::HashBase;

use TeamCity::Message qw(tc_message);

our $VERSION = '0.000001';

sub init {
    my $self = shift;
}

sub listen {
    my $self = shift;
    sub {
        my $job   = shift;
        my $event = shift;

        $self->send_progress_message($job, $event->summary);
    }
}

sub send_progress_message {
    my $self    = shift;
    my $job     = shift;
    my $message = shift;

    print tc_message(
        type => 'progressMessage',
        content => {
            text => join(':', $job->id, $job->file, ' ' .$message),
        },
    );
}

sub summary {
}

1;

# ABSTRACT: immediately render test output as teamcity progress messages

=head1 SYNOPSIS

    # triggered from a "command Script Build" in TeamCity:
    yath -j 2 -R TeamCityProgress -R TeamCityParallel *.t

=head1 DESCRIPTION

This class is a renderer for Test2::Harness that allows it to produce output
sutiable for feeding into TeamCity.

In particular, this renderer produces output that immediately logs every event
your test suite produces as a team city progress notification.  It is intended
to be used in conjunction with the buffering
L<Test2::Harness::Renderer::TeamCityParallel> renderer;  This module gives
immediate progress updates to the TeamCity log (which are ignored by TeamCity
but allow you to see what's currently going on) where as the other module
is designed to buffer up the output that TeamCity expects and play it back in
the order it expects.
