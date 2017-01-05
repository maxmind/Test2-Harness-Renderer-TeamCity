#!/usr/bin/perl

use Test2::Bundle::Extended;

use FindBin;
use IPC::Run3 qw( run3 );
use Path::Iterator::Rule;
use Path::Tiny qw( path );

# find all the test files

my $test_data_dir = path($FindBin::Bin)->child('test-data');

my $rule = Path::Iterator::Rule->new; # match anything
$rule->dir->and(sub {
    -e path($_)->child('input.st')
});

my @files = map { path($_) } sort { $a cmp $b } $rule->all( $test_data_dir );

# work o
my $lib = path($FindBin::Bin)->parent->child('lib');
my @yath = ( 'yath', "-I$lib", '-R', 'TeamCityProgress', '-q');

for my $testdir (@files) {

    my ( @stdout, $stderr );
    run3(
        [ @yath, $testdir->child('input.st') ],
        \undef,
        \@stdout,
        \$stderr,
    );

    { ############################# Temporary Data::Dumper Debug Block ######
      my $mubtr = q^
    
      \@stdout, $stderr
    
      ^; $mubtr=~s/^\s+//; $mubtr=~s/\s+$//; my @mubtr=eval$mubtr or die $@;
      use Term::ANSIColor(); use Data::Dumper();my $str = __FILE__." line "
      .(__LINE__-1)." "; $str .= Term::ANSIColor::color('red')."#"x(72 - 8 -
      length $str) if length$str < 72; local ($Data::Dumper::Useqq,
      $Data::Dumper::Pad)=(1,Term::ANSIColor::color('red')."# ".
      Term::ANSIColor::color('cyan')); print STDERR Term::ANSIColor::color(
      'red')."#### ".Term::ANSIColor::color('yellow')."at ".$str,"\n",
      Data::Dumper->Dump(\@mubtr,[split /,/, $mubtr]),Term::ANSIColor::color(
      'red'),"#"x72,Term::ANSIColor::color('reset'),"\n";
    } #######################################################################
}

