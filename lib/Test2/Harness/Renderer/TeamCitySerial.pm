package Test2::Harness::Renderer::TeamCitySerial;
use strict;
use warnings;

use Test2::Util::HashBase qw/process teststack/;

use TeamCity::Message qw(tc_message);

our $VERSION = '0.000001';

sub init {
    my $self = shift;

    # this is the process we're processing, indexed by job id.
    $self->{+PROCESS}   = {};

    # this is a stack of the tests, indexed by job id, that we're currently
    # in. There's two kinds of things on this list, a subtest and a normal test
    # while a normal test can't contain any more tests, we still need to hold
    # onto it because we need to assoicate any diagnostic output we get after
    # the test with it and not close the test until we've reached an event we
    # we can close the test (i.e. we start another test or something else
    # happens where we can't add any more to this test)
    $self->{+TESTSTACK} = {};
}

sub event_process_start {
    my $self  = shift;
    my $job   = shift;
    my $event = shift;

    $self->send_tc_message(
        'testSuiteStarted',
        name   => $event->file,
        flowId => $job->id,
    );

    $self->{+PROCESS}{ $job_id } = $event;

    return;
}

sub close_test {
    my $self = shift;
    my $job  = shift;

    my $job_id = $job->id;
    my $stack = $self->{+TESTSTACK}{ $job_id };
    return unless @{ $stack };

    my $start_event = pop @{ $stack };

    $self->send_tc_message(
        'testFinished',
        flowid => $job_id,
        name => $event->name,
    );

    return 1;
}

sub close_process {
    my $self = shift;
    my $job  = shift;

    my $job_id = $job->id;
    my $start_event = delete $self->{+PROCESS}{ $job_id }
    return unless @{ $event };

    $self->send_tc_message(
        'testSuiteFinished',
        name   => $start_event->file,
        flowId => $job_id,
    );

}

sub event_process_finish {
    my $self  = shift;
    my $job   = shift;
    my $event = shift;

    1 while $self->close_test($job);
    $self->close_process($job);

    return;
}


sub event_test {
    my $self  = shift;
    my $job   = shift;
    my $event = shift;

    my $flowid = $self->flowid($job);

    $self->send_tc_message(
        'testStarted',
        flowid => $job->id,
        name => $event->name,
    );

    if ($event->causes_fail) {
        $self->send_tc_message(
            'testFailed',
            flowid => $job->id,
        );
    }
}

sub event_diag {
    my $self  = shift;
    my $job   = shift;
    my $event = shift;

    $self->send_tc_message(
        'message',
        text   => $event->summary,
        status => 'NORMAL',  # there's no INFO, darn it
    );

    return;
}

sub listen {
    my $self = shift;
    sub {
        my $job   = shift;
        my $event = shift;

        my $type = ref $event;

        return $self->event_process_start($job,$event)
            if $type eq 'Test2::Event::ProcessStart';
        return $self->event_process_finish($job,$event)
            if $type eq 'Test2::Event::ProcessFinish';

        # don't render anything that we shouldn't show
        return if $event->no_display;

        # is this a test?
        return $self->event_test($job,$event)
            if $event->increments_count;

        # is this diagnostics?
        return $self->event_diag($job,$event)
            if $event->diagnostics;

        # don't know what to do with this message, ignore it
        return;
    }
}

# known event types, and what TeamCity events they should produce
###### Test2-Harness ##################
# Test2::Event::ParseError - Error parsing a test file's output
#  - should fail any tests
# Test2::Event::ParserSelect - A parser was select based on a test job's output
#  - ignored
# Test2::Event::ProcessFinish - A test process has finished
# Test2::Event::ProcessStart - A test process has started
#  - should emit a testSuiteStarted message
# Test2::Event::TimeoutReset - The timeout on a stalled test process was reset
# Test2::Event::UnexpectedProcessExit - A test process has finished
#  - 
# Test2::Event::UnknownStderr - Parser saw unexpected output on STDERR
# Test2::Event::UnknownStdout - Parser saw unexpected output on STDOUT
###### Test-Simple ####################
# Test2::Event::Bail
# Test2::Event::Diag
# Test2::Event::Encoding
# Test2::Event::Exception
# Test2::Event::Generic
# Test2::Event::Info
# Test2::Event::Note
# Test2::Event::Ok
# Test2::Event::Plan
# Test2::Event::Skip
# Test2::Event::Subtest
# Test2::Event::Waiting

sub send_tc_message {
    my $self = shift;
    my $type = shift;
    my $content = { @_ };

    print tc_message(
        type => $type,
        content => $content,
    );
}

sub summary {
}

1;

# ABSTRACT: immediately render test output as teamcity progress messages

=head1 SYNOPSIS

    # triggered from a "command Script Build" in TeamCity:
    yath -R TeamCityProgress -R TeamCityParallel *.t

=head1 DESCRIPTION
