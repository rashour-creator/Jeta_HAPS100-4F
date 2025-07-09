#!/usr/bin/perl
#===============================================================================
# Copyright Synopsys, INC. All rights reserved. You need to read the file
# auxiliary/copyright.txt for full copyright protection details.
#===============================================================================

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

use FindBin;
use lib "$FindBin::Bin";
use testjson;


#####################################################
# define & parse command line options
#####################################################
my $opt_log;
my $opt_json = "./test.json";
my $help     = 0;

&Getopt::Long::Configure('no_autoabbrev', 'ignore_case');

GetOptions(
           'log=s'      => \$opt_log,  # decide whether to log Start or End time
           'json=s'     => \$opt_json, # where to write the json file
           'help|h'     => \$help,     # ask for help
         ) or pod2usage(2);
pod2usage(1) if $help;

# check for mandatory arguments
die("No --log option found.") unless ( defined $opt_log );
die("Invalid log mode $opt_log. Valid modes are 'start' or 'end'")
  unless ( $opt_log =~ /start|end/ );


#####################################################
# main body
#####################################################
# log the time
if ( $opt_log eq "start" ) {
  &logStartTime( jsonfile  => $opt_json );
}

if ( $opt_log eq "end" ) {
  &logEndTime( jsonfile  => $opt_json );
}

# we're done
exit 0;


__END__

=head1 NAME

logtime.pl

=head1 SYNOPSIS

logtime.pl --log <start|end> [--json <path to json file>]

command line utility to log start/end time in a test.json file

this command is typically invoked from run.grd or similar

 Options:
   --log  <start|end> : mandatory argument ; decide what time to log
   --json <..>        : path to json file. Default: ./test.json
   --help             : print this message

=cut

