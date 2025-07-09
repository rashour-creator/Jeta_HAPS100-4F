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
           'log=s'      => \$opt_log,  # CPU Time (CPU Duration)
           'json=s'     => \$opt_json, # where to write the json file
           'help|h'     => \$help,     # ask for help
         ) or pod2usage(2);
pod2usage(1) if $help;

# check for mandatory arguments
die("No --log option found.") unless ( defined $opt_log );

#####################################################
# main body
# NOTE: $sCpuTime + 0 converts the CLI string to a number
#####################################################
my $sCpuTime = $opt_log;
&logCpuTime(
  jsonfile => $opt_json,
  CpuTime  => $sCpuTime + 0
);


# we're done
exit 0;


__END__

=head1 NAME

logtime.pl

=head1 SYNOPSIS

logtime.pl --log <cpu time> [--json <path to json file>]

command line utility to log cpu time in a test.json file

this command is typically invoked from run.grd or similar

 Options:
   --log  <cputime>   : mandatory argument ; CPU Time (integer)
   --json <..>        : path to json file. Default: ./test.json
   --help             : print this message

=cut

