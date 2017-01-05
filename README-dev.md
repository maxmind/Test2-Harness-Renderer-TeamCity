Hello!

This is a work in progress.  And these are my notes so far

# What is this?

It's a Test2::Harness::Renderer.  It's job is to take events captured by
Test2::Harness when you run yath like so:

    yath -q -R TeamCitySerial file.t otherfile.t athirdfile.t

And render them out in a format that TeamCity understands.

`yath` normally renders output in a human readable format on the command line
but with this module we can have it output TeamCity output format.

This means that with this module (when it's eventually written and tested)
you'll be able to use yath from a TeamCity build to run your tests.

This is a considerable improvement over MaxMind's old
[TAP::Formatter::TeamCity](https://metacpan.org/pod/TAP::Formatter::TeamCity)
module that can be used with `prove` as it is able to pass much more through to
TeamCity - most notably it's able to pass through things like stack trace
information, capture any random output sent to STDOUT or STDERR your script may
be able to produce, and is generally a heck of a lot less cobbled together
as it gets to bypass the TAP format entirely 

## How is a Test2 renderer different to a formatter

With Test2 each `.t` file creates events (see the Test2::Event::* namespace
inside the [Test-Simple](https://metacpan.org/release/Test-Simple) distribution)
when you run things like `ok` and `is` and `diag`, etc, etc.  When you run the
script from the command line then the Test2 code uses a default renderer
- [Test2::Formatter::TAP](https://metacpan.org/pod/Test2::Formatter::TAP) -
to render these events out as TAP.


## Why's that `-q` there

Because currently if you don't pass `-q` then yath still includes the default
renderer, meaning you get the same output twice (once in the TeamCity format,
once in the default format.)  That's a bug and there's
[a github issue](https://github.com/Test-More/Test2-Harness/issues/24) about it.

# What's in this distribution?

There are currently four renderers that I'm working on in this distribution:

## Test2::Harness::Renderer::Raw

I wrote this entirely for debugging.  It's very tiny, and basically just renders
all the events out (by passing them through to Test2::Formatter::EventStream)
prepended with the job id (so you can)

This should probably not be released as part of this distribution but instead
released as a stand alone renderer or part of Test2-Harness itself.

I don't like the name for this, but the Test2::Harness::Renderer::EventStream
renderer name is already taken by the default renderer, which doesn't
render event streams, but instead is named that because, to quote chad:

> The EventStream formatter was written to make the EventStream
> renderer work though (though that is no longer clear/obvious)

What you going to do?  Naming things is hard apparently.

**STATUS: This renderer is complete, but needs placing in another distribution**

## Test2::Harness::Renderer::TeamCitySerial

This renderer is able to produce output for TeamCity.  It gives you real
time output of the test state in TeamCity, but because TeamCity isn't designed
to run more than one process at a time, this renderer can't be used when
you're running multiple test scripts in parallel (because the output gets
all mixed up.)

**STATUS: We started this, but didn't complete it**

## Test2::Harness::Renderer::TeamCityParallel

This is the renderer that actually produces the output for TeamCity.

The problem we need to cope with is that TeamCity can't cope with things
running in parallel.  So we have to kind of fake it, piling up output in a stash
until we reach a state we're happy shoving it down the wire in a way it won't
interfere with other things (i.e. when an entire test file is done executing,
or maybe we need to setup for Test::Class::Moose so the `.t` file isn't
considered the test file but the TCM subclass is...

**STATUS: This renderer hasn't been written yet**

## Test2::Harness::Renderer::TeamCityProgress

This renderer gives real time output of events it sees as TeamCity progress
events (which are events that TC just stuffs in the log, essentially as
comments.)

Since the Test2::Harness::Renderer::TeamCityParallel renderer doesn't output
results immediately this is useful for getting real time process as well as
getting feedback.  You can run them both at once:

    yath -j 2 -q -R TeamCityProgress -R TeamCitySerial file.t otherfile.t athirdfile.t

**STATUS: This renderer is a work in progress**

# Explain TeamCity to me for a minute would you?

The team city output format is [documented in jetbrains](https://confluence.jetbrains.com/display/TCD9/Build+Script+Interaction+with+TeamCity#BuildScriptInteractionwithTeamCity-reportingMessagesForBuildLogReportingMessagesForBuildLog)

# What's in the `.t` directory?

These are test files copied from TAP::Formatter::TeamCity.  While there's a
.t file in there (that doesn't work) I've been running the test scripts by
hand (the `input.st` files) and seeing if I can get the expected output
`expected.txt`.)  It's slow going.
