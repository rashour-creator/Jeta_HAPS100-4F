# ===========================================================================
# -------------------------------------------------------------------------------
# 
# Copyright 2012 - 2023 Synopsys, INC.
# 
# This Synopsys IP and all associated documentation are proprietary to
# Synopsys, Inc. and may only be used pursuant to the terms and conditions of a
# written license agreement with Synopsys, Inc. All other use, reproduction,
# modification, or distribution of the Synopsys IP or the associated
# documentation is strictly prohibited.
# Inclusivity & Diversity - Visit SolvNetPlus to read the "Synopsys Statement on
#            Inclusivity and Diversity" (Refer to article 000036315 at
#                        https://solvnetplus.synopsys.com)
# 
# Component Name   : DW_axi_a2x
# Component Version: 2.06a
# Release Type     : GA
# Build ID         : 15.22.13.5
# -------------------------------------------------------------------------------

# 
# File Version     :        $Revision: #8 $ 
# Revision: $Id: //dwh/DW_ocb/bin/axi_dev_br/pkg/perl_uvm_axi/runtest.pm#8 $ 
# ---------------------------------------------------------------------------
# File:         runtest.pm
# Abstract:     Common Perl functions used by runtest script
# ===========================================================================

package runtest;

$^W=1;                # Turn warnings on
use 5.004;            # -- Insist on Perl version 5.004 or newer for safety
use strict;           # -- Follow rigid variable/subroutine declarations
use File::Basename;   # -- Compute the containing directory of this script
use Exporter();
use vars qw(@ISA @EXPORT @ExportedSubs);
@ISA = qw(Exporter);
use lib "/remote/sdgedt/tools/reem/SNPS_FABRIC/Subsystem1/components/i_axi_a2x/scratch/rce/perl/testJSONLib/lib";
use testjson;

my $PATH_TO_JSON_PL_SCRIPTS="/remote/sdgedt/tools/reem/SNPS_FABRIC/Subsystem1/components/i_axi_a2x/scratch/rce/perl/testJSONLib/lib";

my $file_prefix="";

my $design_prefix="i_axi_a2x_";

my $macro_prefix="i_axi_a2x_";

my $compile_src_files_with_y_option = 0;

if ("$design_prefix" eq "$file_prefix") {
  $compile_src_files_with_y_option = 1;
}

#Read cc_constant parameters
my $a2x_has_extd_memtype="0";

my $a2x_pp_endian="0";

my $a2x_a_ubw="0";

my $a2x_w_ubw="0";

my $a2x_r_ubw="0";

my $a2x_ahb_scalar_hresp="0";

my $a2x_ahb_interface_type="0";

my $a2x_has_excl_xfer="0";

my $a2x_user_signal_xfer_mode="0";

my $a2x_wsbw="0";

my $a2x_rsbw="0";

my $a2x_arsbw="0";

my $a2x_awsbw="0";

my $a2x_pp_mode="1";


@ExportedSubs = qw(&fetchModuleName &runtestPreparation &parseCcConstants);
push(@ExportedSubs, qw(&generate_SimCmd_Dmac &commonVerilogDefines &commonVerilogIncludes));

push (@ExportedSubs, qw(&runSim &runRalSim &postProcess));
@EXPORT = @ExportedSubs;


use subs qw(&fetchModuleName &runtestPreparation &convertPath &parseCcConstants &generate_SimCmd_Dmac &commonVerilogDefines &commonVerilogIncludes &runSim &runRalSim &my_system &postProcess &check_errors &check_illegal_prog &check_timeouts &act_cert_requested &act_certified &act_recert_requested &act_recertified);


sub fetchModuleName() {

  # -/ --------------------------------------------------------------
  # -/ This function grabs the name of the top level design module.
  # -/ Since there is more than one file here now we elimate the shell
  # -/ h2h has named files as _input.v and _strings.v eliminate these
  # -/ --------------------------------------------------------------

  my $waste;
  my $ModName;
  $ModName = `echo ../src/*.lst`;
  chomp $ModName;
  $ModName = (basename $ModName);
  ($ModName, $waste) = split ('.lst', $ModName);
  

  return $ModName;
}

sub runtestPreparation() {

  @runtest::inputArray = @_;


  print STDERR "\n\n+------------------------+\n| Testbench Preparation  |".
               "\n+------------------------+\n\n";
  print STDERR "(this section of runtest.log supplied by runtest script)\n\n";

  # -- Keep a safe copy of the Invoke command line for a summary later,
  # -- delete some less useful parts of it
  $main::Summary = $main::Invoke." ...";
  $main::Summary =~ s/--rtl-dir\s+\S+\s*//g;
  $main::Summary =~ s/--timeout\s+\S+\s*//g;
  $main::Summary =~ s/(--test\s+\S+)\s*/sprintf("%-24s",$1) /ge;


  $main::Invoke =~ s/ --/\\\n            --/g;
  print STDERR "$main::Pgm: To recreate the run from this point for debug, do the following\n";
  print STDERR "$main::Pgm:    % cd ".`pwd`;
  print STDERR "${main::Pgm}:    % ${main::Invoke} \n\n";

  chdir "./$main::Test" or die "$main::Pgm: ERROR - Cannot cd to test subdirectory ./$main::Test";
  print STDERR "$main::Pgm: Changed Directory to ./$main::Test - look here for detailed logfiles/waves/results\n";

  # -- If it's midnight, wait a moment to avoid licensing problems
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  sleep 120 if ($hour == 23 and $min == 59);
  sleep 60 if ($hour == 0 and $min == 0);

  # -- Set $Cwd now and we will use that as a reference point
  $main::Cwd = `pwd`; chomp $main::Cwd;
  $main::coreKit = (dirname (dirname $main::Cwd));

  $main::RtlDir = convertPath($main::RtlDir);
  $main::Netlist = convertPath($main::Netlist);
  $main::SdfFile = convertPath($main::SdfFile);
  $main::DumpFile = convertPath($main::DumpFile);
  $main::TestbenchDir = convertPath($main::TestbenchDir);
  $main::Test = convertPath($main::Test);

  $main::configDirName = (basename $main::coreKit);
  $main::ccparams_file = "${main::coreKit}/src/${main::DesignName}_cc_constants.vh";
  print STDERR "\n$main::Pgm: coreKit in file:".(dirname (dirname $main::Cwd))."\n";
  print STDERR "$main::Pgm: runtest in file:".(dirname $main::Cwd)."\n";
  print STDERR "$main::Pgm: test is in file:$main::Cwd\n";

  # -- Simulator option should be case-insensitive - force to lower-case
  $main::Simulator = lc($main::Simulator);

  # jid folder creation and dumping JOB_ID of every test in it for the compatTest
  # If compatTest doesn't find jid in sim folder, it doesn't wait for a tests to finsih
  # and returns simVCS_default as failed
  my $job_id = $ENV{JOB_ID};
  if(! -d "../jid") {
    system( "mkdir ../jid" );
  }
  `touch $main::Cwd/../jid/$job_id`;
  # -- Simulation Source
 if ($main::DesignName eq "DW_axi_dmac") {
  $main::testbench = "$main::TestbenchDir/dmac_top.sv";
} else {
  $main::testbench = "$main::TestbenchDir/test_top.sv";
}

}

sub convertPath($) {

  # -/ --------------------------------------------------------------
  # -/ ConvertPath(path) determine the absolute root of the current
  # -/ and converts the supplied dirpath/filepath to relative to the
  # -/ test directory where the simulation is being run.
  # -/ All default file locations are calculated relative to the
  # -/ test directory, so we need to adjust those provided from the
  # -/ invoking directory and migrate any absolute ones to relative
  # -/ if possible.
  # -/
  # -/ This script is assumed to be located in $coreKit/sim and we
  # -/ have now chdir'ed one level further down into a Test
  # -/ subdirectory so to find the coreKit we go two levels up using
  # -/ (dirname(dirname $Cwd))
  # -/
  # -/ The routine also removes duplicate or trailing slashes to keep
  # -/ VCS happy Note - the routine also promises to convert <undef>
  # -/ to <undef>
  # -/ --------------------------------------------------------------
  my $path = shift;
  return undef unless defined($path);
  $path =~ s|^<coreKit>/|$main::coreKit/|;
  $path =~ s|^$main::coreKit/sim/|../|;
  $path =~ s|^$main::coreKit/|../../|;
  $path =~ s|//|/|g;
  $path =~ s|/$||;
  return $path;
}


sub parseCcConstants($) {

  my $ccparams_file = shift;
  my %ccparams;

  open (CCPARAMS, "< $ccparams_file") || die "ERROR - Can't open $ccparams_file ($!)\n";


  while (<CCPARAMS>) {
    if (/^\`define\s+(\S+)\s+(.+)/) {
      my ($param,$value) = ($1,$2);
      # -- Got param - convert it from verilog `define format number to a string
      # -- containing a vera-format number of the same radix e.g. NN`bXXXX -> 0xXXXX
      $value =~ s/^([0-9]*)\'h([0-9a-fA-F]+)$/0x$2/;
      $value =~ s/^([0-9]*)\'d[0]*([0-9]+)$/$2/;
      $value =~ s/^([0-9]*)\'o([0-7]+)$/0$2/;
      $value =~ s/^([0-9]*)\'b([0-1]+)$/0b$2/;
      $ccparams{$param} = $value;
    }
  }
  close CCPARAMS || die "ERROR - Failed to close $ccparams_file after read ($!)\n";

  return(%ccparams);
}

sub generate_SimCmd_Dmac($) {

 my $busType = shift;

if ($main::Simulator eq "vcs") {

  print STDERR "$main::Pgm: Creating simulation command file: \n$main::Pgm:   file:$main::Cwd/$main::simcommand\n";
  open(SCF,">$main::simcommand") or
    die "$main::Pgm: ERROR -  couldn't open simulation command file $main::simcommand for write\n";

  # -- print header to file
  printf SCF "// -----------------------------------------------------------------------\n";
  printf SCF "// Simulation Control file produced by %s - do not edit\n",$main::Pgm;
  printf SCF "// -----------------------------------------------------------------------\n";
  printf SCF "\n";

  # -- VCS command
  if($main::Simulator eq "vcs") {
    printf SCF "+vcs+lic+wait\n";
    printf SCF "-notice\n";
    # -- Timescale
    printf SCF "-timescale=1ns/1ps\n";

  }

  if ($main::DesignName eq "DW_axi_dmac" and $main::Test eq "test_003_reg_rw") {
    printf SCF "+define+DMAX_CLK_CTRL\n";
  }  

  # -- Misc commands
  printf SCF "+libext+.v+.V+.sv+.sva\n";
  printf SCF "+plusarg_save\n";
 
  if ($main::Period) {
      printf SCF "+define+PERIOD=$main::Period\n";
  }
  if ($main::Period2) {
      printf SCF "+define+PERIOD2=$main::Period2\n";
  }

  if ($main::Timeout) {
    printf SCF "+define+TIMEOUT=".($main::Period * $main::Timeout)."\n";
  }
  if ($main::Coverage) {
    printf SCF "+define+CODE_COVERAGE\n";
  }
  
  #Control AutoreadEnabled from gui
  if (defined $main::AutoreadEnabled) {
    #$compile_src_files_with_y_option = 1; #set by default if file & design prefix are same
  } else {
    $compile_src_files_with_y_option = 0;
  }
    
  if ($main::FCoverage) {
    printf SCF "+define+FUNC_COVERAGE\n";
  }
   if($main::SVCoverage) {
     printf SCF "+define+ASSERT_ON_CB=1\n";
  }
 
  if ($main::MisSamples) {
    printf SCF "+define+DW_MODEL_MISSAMPLES=1\n";
  }

  if ($main::BCM_coverage) {
    printf SCF "+define+DWC_BCM_SNPS_ASSERT_ON=1\n";
    printf SCF "+define+DWC_BCM_CDC_COVERAGE_REPORT=1\n";
  }
  if($main::RAL_coverage){
    printf SCF "+define+RAL_COV_ON=1\n";
  }

  # -- RTL or Netlist simulation
  if ($main::RtlSim eq "RTL") {
    printf SCF "+define+RTL\n";
    printf SCF "+delay_mode_zero\n";
    printf SCF ("+v2k\n");
  } else {
    printf SCF "+define+NETLIST\n";
  }

  
  # Pass a plus define denoting chosen simulator.
  if(($main::Simulator eq "vcs") or ($main::Simulator eq "vcsi")) {
    printf SCF "+define+VCS\n";
  }
    printf SCF "+define+SYNOPSYS_SV\n"; 
    printf SCF "+define+SVT_AXI_INCLUDE_USER_DEFINES\n"; 
    printf SCF "+define+SVT_AHB_INCLUDE_USER_DEFINES\n"; 
    printf SCF "+define+SVT_APB_INCLUDE_USER_DEFINES\n"; 
    printf SCF "+define+UVM_PACKER_MAX_BYTES=1500000\n"; 
    printf SCF "+define+UVM_DISABLE_AUTO_ITEM_RECORDING\n";   

  # We always require SV for the A"X simulation
  if (($main::Simulator eq "vcs") or ($main::Simulator eq "vcsi")) {
    printf SCF "-sverilog\n";
  }

  

  if($main::Simulator eq "vcs") {
    printf SCF "+incdir+.\n";
    printf SCF "+incdir+../testbench\n";
    printf SCF "+incdir+../testbench/env\n";
    printf SCF "+incdir+../testbench/env/dmac_hold_agent\n";
    printf SCF "+incdir+../models/vip/src/sverilog/vcs\n";
    printf SCF "+incdir+../models/vip/include/sverilog\n";
    printf SCF "-y $ENV{SYNOPSYS}/dw/sim_ver\n"; 
    if(exists $main::ccparams{'ASSERT_ON_CB'}) {
      printf SCF "-assert enable_diag\n"
    }
    printf SCF "-q\n"; 
  }
    
  printf SCF "-y .\n"; 
  printf SCF "-y ../testbench\n"; 
  printf SCF "-y ../testbench/env\n"; 
  printf SCF "-y ../../src\n"; 
  printf SCF "-y ../models/vip/include/sverilog\n"; 
  printf SCF "+incdir+../models/vip/include/sverilog\n"; 

  if(($main::Simulator eq "vcs") or ($main::Simulator eq "vcsi")) {
    printf SCF "-assert enable_diag\n";
  }
   
 # -- SDF annotation
  if ($main::SdfFile) {
    if(($main::Simulator eq "vcs") or ($main::Simulator eq "vcsi")) {
      printf SCF "+csdf+precompile\n";
      printf SCF "+define+SDF_FILE=\"\"$main::SdfFile\"\"\n";
      if($main::SdfLevel eq 'max') {
        printf SCF "+define+SDF_LEVEL=\"\"MAXIMUM\"\"\n";
      } elsif($main::SdfLevel eq 'typ') {
        printf SCF "+define+SDF_LEVEL=\"\"TYPICAL\"\"\n";
      } else {
        printf SCF "+define+SDF_LEVEL=\"\"MINIMUM\"\"\n";
      }
    } else {
      printf SCF "+define+SDF_FILE=\\\"$main::SdfFile\\\"\n";
    }
  }

  # -- Dump file control
  if ($main::DumpEnabled == 2) {
    printf SCF "\n// What waves to record\n\n";
    printf SCF "+define+A2X_PTPX\n";
    printf SCF "+define+DUMP_DEPTH=0\n";
    printf SCF "+define+DUMP_FILE=\"\"test.vcd\"\"\n";
  } else {
    if ($main::DumpEnabled) {
    if ($main::DumpFileFormat eq "FSDB") {
      #fsdb dump 
      printf SCF "\n// fsdb dump enable\n";
      printf SCF "\n// open fsdb using cmd\n";
      printf SCF "\n// verdi -simflow -dbdir simv.daidir -ssf test.fsdb &\n\n";
      printf SCF "+define+FSDB_DUMP\n";
      if (defined $main::DumpDepth) {
        printf SCF "+define+DUMP_DEPTH=$main::DumpDepth\n";
      } else {
        printf SCF "+define+DUMP_DEPTH=0\n";
      }
      printf SCF "-kdb \n";
    } else {
      if (defined $main::DumpDepth) {
        printf SCF "\n// What waves to record\n\n";
        if ((($main::Simulator eq "vcs") or ($main::Simulator eq "vcsi")) and ($main::DumpFile =~ /\.vpd$/)) {
          printf SCF "-debug_acc+all+dmptf -debug_region=cell+encrypt\n";
          printf SCF "+vpdfile+$main::DumpFile\n";
        } else {
          printf SCF "+define+DUMP_FILE=\\\"$main::DumpFile\\\"\n";
        }
        printf SCF "+define+DUMP_DEPTH=$main::DumpDepth\n";
      } else { 
        printf SCF "\n// Waves recording not enabled - no --dump-depth N specified\n\n";
        printf SCF "//+define+DUMP_DEPTH=0\n";
        printf SCF "//+vpdfile+$main::DumpFile\n";
        printf SCF "//-debug_acc+all+dmptf -debug_region=cell+encrypt\n";
      }
    }
 }else {
      printf SCF "\n// Waves recording not selected\n";
      printf SCF "//+define+DUMP_DEPTH=0\n";
      printf SCF "//+vpdfile+$main::DumpFile\n";
      printf SCF "//-debug_acc+all+dmptf -debug_region=cell+encrypt\n";

      #vpd dump
      printf SCF "\n//vpd dump not selected\n";
      printf SCF "//+vpdfile+$main::DumpFile\n";

      #fsdb dump 
      printf SCF "\n//fsdb dump not selected\n";
      printf SCF "//+define+FSDB_DUMP\n";
      printf SCF "//-kdb \n";
    }
  }
  # -- define a macro if it is a netlist
  if (!($main::RtlSim eq "RTL")) {
    printf SCF "\n// Tell the testbench that we have a netlist\n\n";
    printf SCF "+define+GATE_LEVEL_NETLIST\n";
    printf SCF "+define+DISABLE_X_DRIVE\n";
  }

  # -- Construct the library switches from $LibDir and $LibFile
  # -- $LibDir, obtained from --lib-dir, is a space-separated list of directories.
  # -- We'll make a $libswitches by prepending "-y " to each of the directories.
  my $file_missing=0;

  my @libdirs = split(",",$main::LibDir);
  if (exists $ENV{SYNOPSYS} && ($main::RtlSim eq "GTECH")) {
    if ($ENV{SYNOPSYS} ne "") {
      if ( -d "$ENV{SYNOPSYS}/packages/gtech/src_ver" ) {
        push @libdirs,"$ENV{SYNOPSYS}/packages/gtech/src_ver";
      } else {
        print STDERR "\n$main::Pgm: ERROR - Env variable \$SYNOPSYS is not correctly set - ($ENV{SYNOPSYS})";
        print STDERR "\n                    Unable to find required directory - \$SYNOPSYS/packages/gtech/src_ver";
        print STDERR "\n                    If using SYNOPSYS Synthesis Tools, set Env variable \$SYNOPSYS to a valid location.";
        print STDERR "\n                    If NOT using SYNOPSYS Synthesis Tools, unset Env variable \$SYNOPSYS.\n";
        die "\n$main::Pgm: FATAL - $file_missing required files/directories missing. $main::Pgm terminating\n";
      }
    }
  }

  if (exists $main::ccparams{'USE_FOUNDATION'}) {
    if ($main::ccparams{'USE_FOUNDATION'} eq 1) {
      if (exists $ENV{SYNOPSYS}) {
        if ($ENV{SYNOPSYS} ne "") {
          if ( -d "$ENV{SYNOPSYS}/dw/sim_ver" ) {
            push @libdirs,"$ENV{SYNOPSYS}/dw/sim_ver";
          } else {
            print STDERR "\n$main::Pgm: ERROR - Env variable \$SYNOPSYS is not correctly set - ($ENV{SYNOPSYS})";
            print STDERR "\n                    Unable to find required directory - \$SYNOPSYS/dw/sim_ver";
            print STDERR "\n                    Set Env variable \$SYNOPSYS to a valid location.";
            die "\n$main::Pgm: FATAL - $file_missing required files/directories missing. $main::Pgm terminating\n";
          }
        }
      }
    }
  }


  my $libswitch= "";
  foreach (@libdirs) {
    $_ = convertPath($_);
    printf SCF "-y $_\n";
    unless (-d "$_") {
      $file_missing++;
      print STDERR "\n$main::Pgm: ERROR - directory $_ is required but missing.\n";
    }
  }


  # -- $LibFile, obtained from --lib-file, is a space-separated list of files.
  # -- We'll add to $libswitches by appending "-v " to each of the files
  if ($main::LibFile) {
    my @libfiles = split(",",$main::LibFile);
    foreach(@libfiles) {
      $_ = $main::LibDir."/".$_;
      $_ = convertPath($_);
      printf SCF "-v $_\n";
    }
  }

  close SCF or die "$main::Pgm: ERROR - failed to close command file $main::simcommand after write\n";
  die "$main::Pgm: FATAL - $file_missing required files/directories missing. $main::Pgm terminating\n" if $file_missing;
 } else {
  die "$main::Pgm: FATAL - $main::Simulator is unsupported\n";
 }

 my $vcs_home = "";

  if(defined $ENV{'VCS_HOME'} ) {
    $vcs_home = $ENV{'VCS_HOME'};
  }    
  my $busType = shift;
  if (-e ${main::simcommand}) {
    open(RCB,">>${main::simcommand}") or
    die "$main::Pgm: ERROR -  couldn't open simulation command file $main::simcommand for write\n"
  } else {
    open(RCB,">${main::simcommand}") or
    die "$main::Pgm: ERROR -  couldn't open simulation command file $main::simcommand for write\n"
  }


  printf RCB "\n// -----------------------------------------------------------------------\n";
  printf RCB "// Simulation Source files and include directories\n";
  printf RCB "// -----------------------------------------------\n\n";


  printf RCB "$main::testbench\n";

  printf RCB "// Memory models\n";
  if (exists $main::ccparams{'DMAX_HAS_RUID_PARAM'}) {
    if (($main::ccparams{'DMAX_HAS_RUID_PARAM'} eq 0) and ($main::ccparams{'DMAX_CH_MEM_EXT'} eq 1)) {
      printf RCB "$main::TestbenchDir/env/dmac_memory_model/DW_axi_dmac_bcm58.v\n";
    }
  }  
  printf RCB "$main::TestbenchDir/env/dmac_memory_model/ram2p.v\n";
  printf RCB "$main::TestbenchDir/env/dmac_memory_model/sadrlsih4m2p32x32m1b1w0c0p0d0t0s10.v\n";
  printf RCB "$main::TestbenchDir/env/dmac_memory_model/sadrlsih4m2p64x32m2b1w0c0p0d0t0s10.v\n";
  printf RCB "$main::TestbenchDir/env/dmac_memory_model/sadslsih4m2p32x32m4b1w0c0p0d0t0s10.v\n";
  printf RCB "$main::TestbenchDir/env/dmac_memory_model/sadslsih4m2p64x32m4b1w0c0p0d0t0s10.v\n";

  if ($main::RtlSim eq "RTL") {
    if ($compile_src_files_with_y_option == 0) {
      printf RCB "-f ${main::RtlDir}/${main::DesignName}.lst\n";
    } else {
      printf RCB "-y ${main::RtlDir} \n";
    }
  } else {
    printf RCB "$main::Netlist\n\n";
  }  

  if ($macro_prefix ne "") {
    #Get Design_unprefix file
    printf RCB "+define+MACRO_UNPREFIX_INCLUDE\n";
    printf RCB "+incdir+../../scratch\n";
  }

  printf RCB "+incdir+.\n";
  printf RCB "-y .\n\n";
  printf RCB "+incdir+$main::RtlDir\n";
  printf RCB "-y $main::RtlDir\n\n";
  printf RCB "+incdir+$main::TestbenchDir\n";
  printf RCB "+incdir+$main::TestbenchDir/env\n";
  printf RCB "-y $main::TestbenchDir\n\n";
  printf RCB "-y $main::TestbenchDir/env\n\n";

  close RCB or die "$main::Pgm: ERROR - failed to close command file $main::simcommand after write\n";

}


sub commonVerilogDefines($) {
  my $busType = shift;

if ($main::Simulator eq "vcs") {

  print STDERR "$main::Pgm: Creating simulation command file: \n$main::Pgm:   file:$main::Cwd/$main::simcommand\n";
  open(SCF,">$main::simcommand") or
    die "$main::Pgm: ERROR -  couldn't open simulation command file $main::simcommand for write\n";

  # -- print header to file
  printf SCF "// -----------------------------------------------------------------------\n";
  printf SCF "// Simulation Control file produced by %s - do not edit\n",$main::Pgm;
  printf SCF "// -----------------------------------------------------------------------\n";
  printf SCF "\n";

  # -- VCS commanm
  if($main::Simulator eq "vcs") {
    printf SCF "+vcs+lic+wait\n";
    printf SCF "-notice\n";
    printf SCF "-sverilog\n";
  if ($main::DesignName eq "DW_axi_hmx") {  
    printf SCF "-timescale=100ps/100ps\n";
  } else {
    printf SCF "-timescale=1ns/1ps\n";
  }
 }
  # -- Misc commands
  
  if ($main::DesignName eq "DW_axi_a2x") {  
  printf SCF "-q\n"; #quite mode
  }
  printf SCF "+nowarnTFNPC\n";
  printf SCF "+warn=noZONMCM\n";
  printf SCF "+warn=noPCWM\n";
  printf SCF "+libext+.v+.V+.sv+.sva+.svi\n";
  printf SCF "+sdfverbose\n";
  printf SCF "+neg_tchk\n";
  printf SCF "+plusarg_save\n";
  printf SCF "+warn=noTMR\n";
  printf SCF "+nowarnTFMPC\n";
  printf SCF "+nowarnTMREN\n";
  printf SCF "+nowarnLDSNN\n";
  printf SCF "+nowarnOPTCHK\n";
  printf SCF "+define+SYNOPSYS_SV\n";
  if ($main::DesignName eq "DW_axi_hmx") {  
  printf SCF "+define+SVT_AHB_DISABLE_IMPLICIT_BUS_CONNECTION\n";
  }
  printf SCF "+define+SVT_AXI_INCLUDE_USER_DEFINES\n";
  printf SCF "+define+SVT_AHB_INCLUDE_USER_DEFINES\n";
  printf SCF "+define+UVM_PACKER_MAX_BYTES=1500000\n";
  printf SCF "+define+UVM_DISABLE_AUTO_ITEM_RECORDING\n";
   if (($main::DesignName eq "DW_axi_x2p") or ($main::DesignName eq "DW_axi_x2h") or ($main::DesignName eq "DW_axi_x2x") or ($main::DesignName eq "DW_axi_a2x") or ($main::DesignName eq "DW_axi_hmx") or ($main::DesignName eq "DW_axi_rs")) {
  printf SCF "+define+DEBUG_LEVEL=$main::VeraDebugLevel\n";
   }
  if (($main::DesignName eq "DW_axi_gm") or ($main::DesignName eq "DW_axi_gs")) { 
  printf SCF "+define+SVT_AXI_RESP_WIDTH=2\n";
  }
  if ($main::DesignName eq "DW_axi_x2p") {
  printf SCF "+define+SVT_APB_INCLUDE_USER_DEFINES\n";
  }
  if ($main::DesignName eq "DW_axi_a2x") {  
  printf SCF "+define+SVT_UVM_TECHNOLOGY\n";
  }

  if ($main::DesignName eq "DW_axi_rs") {
  printf SCF "+define+SVT_SPI_MAX_DATA_TRANSFER=1032\n";
  printf SCF "+define+SVT_SPI_IO_WIDTH=8\n";
  }

  
  if ($main::FunCovVipEn) {
       printf SCF "+define+VIP_COV_EN\n";
     }
  
  
  if ($main::FunCovEn) {
     printf SCF "+define+FUNC_COV_EN\n";
     }
 
  


  #-------------------------------------------------------------------------------------------------
  #AHB5 enh. vip macros
  #-------------------------------------------------------------------------------------------------
 
  if ($main::DesignName eq "DW_axi_a2x") {
  my $address_user_width = 0;
  my $data_user_width = 0;
  my $axi_address_user_width = 0;
  my $axi_data_user_width = 0;

  #Read user signals params of DUT
  if ($a2x_r_ubw != 0 || $a2x_w_ubw != 0) {
    if ($a2x_r_ubw > $a2x_w_ubw) {
      $data_user_width = $a2x_r_ubw;
    } else {
      $data_user_width = $a2x_w_ubw;
    }
  }

  if ($a2x_a_ubw != 0) {
    $address_user_width = $a2x_a_ubw;
  }

  #for axi
  $axi_address_user_width = $address_user_width;
  $axi_data_user_width = $data_user_width;

  #MSB of user signals used for hexcl, hexokay
  if ($a2x_has_excl_xfer == 1) {
    $address_user_width = $address_user_width + 1;
    $data_user_width = $data_user_width + 1;
  }

  if ( ($a2x_has_extd_memtype == 1) and ($a2x_pp_endian == 2) ) {
    $address_user_width = $address_user_width + 3;
  }

  if ($address_user_width != 0 ) {
    printf SCF "+define+SVT_AHB_MAX_USER_WIDTH=$address_user_width\n";
  }

  if ($data_user_width != 0 ) {
    printf SCF "+define+SVT_AHB_MAX_DATA_USER_WIDTH=$data_user_width\n";
  }

  #AXI Vip macros when PP- AHB
  if ( $axi_address_user_width != 0 ) {
    printf SCF "+define+SVT_AXI_MAX_ADDR_USER_WIDTH=$axi_address_user_width\n";
  }

  if ( $a2x_user_signal_xfer_mode == 0 ) {
    if ( $axi_data_user_width != 0 ) {
      printf SCF "+define+SVT_AXI_MAX_DATA_USER_WIDTH=$axi_data_user_width\n";
    }
  } else {
    if ( $a2x_wsbw != 0 or $a2x_rsbw !=0 ) {
      if ($a2x_wsbw > $a2x_rsbw) {
        printf SCF "+define+SVT_AXI_MAX_DATA_USER_WIDTH=$a2x_wsbw\n";
      } else {
        printf SCF "+define+SVT_AXI_MAX_DATA_USER_WIDTH=$a2x_rsbw\n";
      }
    }
  }


  if ($a2x_ahb_scalar_hresp == 1) {
    printf SCF "+define+SVT_AHB_HRESP_PORT_WIDTH=1\n";
  }

  if (defined $main::en_incr_xfers) {
    if ($main::en_incr_xfers == 1) {
      printf SCF "+define+A2X_ENABLE_INCR_XFERS\n";
    }
  }
  if (defined $main::disable_incr_xfers) {
    if ($main::disable_incr_xfers == 1) {
      printf SCF "+define+A2X_DISABLE_INCR_XFERS\n";
    }
  }
  if (defined $main::no_busy_cycles) {
    if ($main::no_busy_cycles == 1) {
      printf SCF "+define+AHB_BUSY_CYCLES_EQ_0\n";
    }
  }
  #-------------------------------------------------------------------------------------------------

  #-------------------------------------------------------------------------------------------------
  #AXI configuration changes
  #-------------------------------------------------------------------------------------------------
  if ($a2x_pp_mode == 1) {

    if ( $a2x_arsbw != 0 or $a2x_awsbw != 0) {
      if ( $a2x_arsbw > $a2x_awsbw != 0) {
        printf SCF "+define+SVT_AXI_MAX_ADDR_USER_WIDTH=$a2x_arsbw\n";
      } else {
        printf SCF "+define+SVT_AXI_MAX_ADDR_USER_WIDTH=$a2x_awsbw\n";
      }
    }

    if ( $a2x_rsbw != 0 or $a2x_wsbw != 0) {
      if ( $a2x_rsbw > $a2x_wsbw != 0) {
        printf SCF "+define+SVT_AXI_MAX_DATA_USER_WIDTH=$a2x_rsbw\n";
      } else {
        printf SCF "+define+SVT_AXI_MAX_DATA_USER_WIDTH=$a2x_wsbw\n";
      }
    }
  }
  }
  #-------------------------------------------------------------------------------------------------

  if ($main::Period) {
      printf SCF "+define+PERIOD=$main::Period\n";
  }
  if ($main::Period2) {
      printf SCF "+define+PERIOD2=$main::Period2\n";
  }

  if ($main::Timeout) {
    printf SCF "+define+TIMEOUT=".($main::Period * $main::Timeout)."\n";
  }
  if ($main::Coverage) {
    printf SCF "+define+CODE_COVERAGE\n";
  }

  # AARAUJO, 06/05/2010, v2k switched on by default for all sims.
  printf SCF ("+v2k\n");

  #Control AutoreadEnabled from gui
  if (defined $main::AutoreadEnabled) {
    #$compile_src_files_with_y_option = 1; #set by default if file & design prefix are same
  } else {
    $compile_src_files_with_y_option = 0;
  }

  # -- RTL or Netlist simulation
  if ($main::RtlSim eq "RTL") {
    printf SCF "+define+RTL\n";
    printf SCF "+delay_mode_zero\n";
  } else {
    printf SCF "+define+NETLIST\n";
  }

  if ($main::MisSamples) {
    printf SCF "+define+DW_MODEL_MISSAMPLES=1\n";
  }

  if ($main::BCM_coverage) {
    printf SCF "+define+DWC_BCM_SNPS_ASSERT_ON=1\n";
    printf SCF "+define+DWC_BCM_CDC_COVERAGE_REPORT=1\n";
    printf SCF "+define+DWC_BCM_CDC_CHKLIST_ON=1\n";
  }
  

  # Pass a plus define denoting chosen simulator.
  if(($main::Simulator eq "vcs") or ($main::Simulator eq "vcsi")) {
    printf SCF "+define+VCS\n";
  }
  


 # -- SDF annotation
  if ($main::SdfFile) {
    if(($main::Simulator eq "vcs") or ($main::Simulator eq "vcsi")) {
      printf SCF "+csdf+precompile\n";
      printf SCF "+define+SDF_FILE=\"\"$main::SdfFile\"\"\n";
      if($main::SdfLevel eq 'max') {
        printf SCF "+define+SDF_LEVEL=\"\"MAXIMUM\"\"\n";
      } elsif($main::SdfLevel eq 'typ') {
        printf SCF "+define+SDF_LEVEL=\"\"TYPICAL\"\"\n";
      } else {
        printf SCF "+define+SDF_LEVEL=\"\"MINIMUM\"\"\n";
      }
    } else {
      printf SCF "+define+SDF_FILE=\\\"$main::SdfFile\\\"\n";
    }
  }
  
  
  #-----------------------------------------------------------------------------
  # Dump file control
  # 2019.03: Verdi FSDB support
  # - In the test_DW_apb_timers.v it has verilog code to dump to vpd and
  # dump to fsdb. The verilog code uses `DUMP_DEPTH and `DUMP_FILE
  # - There seems to be a requirement that -debug_access is early in the call
  # to VCS. It is directly after the vcs -debug_access.
  # Adding -debug_access+all is not strictly needed here.
  # - added -kdb. requires -lca aswell.
  #   - apparently this is the recommended future as they use Verdi as the
  #   front end for debugging simualtions.
  # - you can open design with just this
  # > verdi -simflow -dbdir simv.daidir
  # - you can open the the design and waveform with this
  # > verdi -ssf <fsdb file>
  #-----------------------------------------------------------------------------

  if ($main::DumpEnabled) {
    # -- Dump file control
    if ($main::DumpFileFormat eq "FSDB") {
      #fsdb dump 
      printf SCF "\n// fsdb dump enable\n";
      printf SCF "\n// open fsdb using cmd\n";
      printf SCF "\n// verdi -simflow -dbdir simv.daidir -ssf test.fsdb &\n\n";
      printf SCF "+define+FSDB_DUMP\n";
      if (defined $main::DumpDepth) {
        printf SCF "+define+DUMP_DEPTH=$main::DumpDepth\n";
      } else {
        printf SCF "+define+DUMP_DEPTH=0\n";
      }
      printf SCF "-kdb \n";
    } else {
    if (defined $main::DumpDepth) {
      printf SCF "\n// What waves to record\n\n";
      if ((($main::Simulator eq "vcs") or ($main::Simulator eq "vcsi")) and ($main::DumpFile =~ /\.vpd$/)) {
        printf SCF "+vpdfile+$main::DumpFile\n";
      } else {
        printf SCF "+define+DUMP_FILE=\\\"$main::DumpFile\\\"\n";
      }
      printf SCF "+define+DUMP_DEPTH=$main::DumpDepth\n";
    } else {
      printf SCF "\n// Waves recording not enabled - no --dump-depth N specified\n\n";
      printf SCF "//+define+DUMP_DEPTH=0\n";
    }
  }
  }
  else {
    printf SCF "\n// Waves recording not selected\n";
    printf SCF "//+define+DUMP_DEPTH=0\n";

    #vpd dump
    printf SCF "\n//vpd dump not selected\n";
    printf SCF "//+vpdfile+$main::DumpFile\n";

    #fsdb dump 
    printf SCF "\n//fsdb dump not selected\n";
    printf SCF "//+define+FSDB_DUMP\n";
    printf SCF "//-kdb \n"; 

  }
  # -- define a macro if it is a netlist
  if (!($main::RtlSim eq "RTL")) {
    printf SCF "\n// Tell the testbench that we have a netlist\n\n";
    printf SCF "+define+GATE_LEVEL_NETLIST\n";
  }

  # -- Construct the library switches from $LibDir and $LibFile
  # -- $LibDir, obtained from --lib-dir, is a space-separated list of directories.
  # -- We'll make a $libswitches by prepending "-y " to each of the directories.
  my $file_missing=0;

  my @libdirs = split(",",$main::LibDir);
  if ($main::RtlSim eq "GTECH") {
    if (exists $ENV{SYNOPSYS}) {
      if ($ENV{SYNOPSYS} ne "" && (-d "$ENV{SYNOPSYS}/packages/gtech/src_ver")) {
          push @libdirs,"$ENV{SYNOPSYS}/packages/gtech/src_ver";
      } else {
        print STDERR "\n$main::Pgm: ERROR - Env variable \$SYNOPSYS is not correctly set - ($ENV{SYNOPSYS})";
        print STDERR "\n                    Unable to find required directory - \$SYNOPSYS/packages/gtech/src_ver";
        print STDERR "\n                    If using SYNOPSYS Synthesis Tools, set Env variable \$SYNOPSYS to a valid location.";
        print STDERR "\n                    If NOT using SYNOPSYS Synthesis Tools, unset Env variable \$SYNOPSYS.\n";
        die "\n$main::Pgm: FATAL - $file_missing required files/directories missing. $main::Pgm terminating\n";
      }
    } else {
      print STDERR "\n$main::Pgm: WARNING - Env variable \$SYNOPSYS is not set for this GTECH simulation";
      print STDERR "\n                      Unable to auto set path to GTECH libs.";
      print STDERR "\n                      If using SYNOPSYS Synthesis Tools, set Env variable \$SYNOPSYS to a valid location.";
      print STDERR "\n                      If NOT using SYNOPSYS Synthesis Tools, pass valid gtech lib path on runtest command line\n";
    }
  }

if (exists $main::ccparams{'i_axi_a2x_USE_FOUNDATION'}) 
   {
if ($main::ccparams{'i_axi_a2x_USE_FOUNDATION'} eq 1) 
     {
      if (exists $ENV{SYNOPSYS}) {
        if ( $ENV{SYNOPSYS} ne "" && (-d "$ENV{SYNOPSYS}/dw/sim_ver")) {
          push @libdirs,"$ENV{SYNOPSYS}/dw/sim_ver";
        } else {
          print STDERR "\n$main::Pgm: ERROR - Design parameter USE_FOUNDATION==1 and Env variable \$SYNOPSYS is not correctly set - ($ENV{SYNOPSYS})";
          print STDERR "\n                    Unable to find required directory - \$SYNOPSYS/dw/sim_ver";
          print STDERR "\n                    Set Env variable \$SYNOPSYS to a valid location.";
          die "\n$main::Pgm: FATAL - $file_missing required files/directories missing. $main::Pgm terminating\n";
        }
      } else {
        print STDERR "\n$main::Pgm: ERROR - Design parameter USE_FOUNDATION==1 and Env variable \$SYNOPSYS is not set";
        print STDERR "\n                    Unable to find required directory - \$SYNOPSYS/dw/sim_ver";
        print STDERR "\n                    Set Env variable \$SYNOPSYS to a valid location.";
        die "\n$main::Pgm: FATAL - $file_missing required files/directories missing. $main::Pgm terminating\n";
      }
    }
  }
  
if ($main::DesignName eq "DW_axi_a2x") {
  if ($main::ScoreBoardDisable) {
    printf SCF "+define+A2X_SCOREBOARD_DISABLE\n";
  }

  if ($main::LowPowerDisable) {
    printf SCF "+define+A2X_LOW_POWER_DISABLE\n";
  }
  }
  my $libswitch= "";
  foreach (@libdirs) {
    $_ = convertPath($_);
    printf SCF "-y $_\n";
    unless (-d "$_") {
      $file_missing++;
      print STDERR "\n$main::Pgm: ERROR - directory $_ is required but missing.\n";
    }
  }


  # -- $LibFile, obtained from --lib-file, is a space-separated list of files.
  # -- We'll add to $libswitches by appending "-v " to each of the files
  if ($main::LibFile) {
    my @libfiles = split(",",$main::LibFile);
    foreach(@libfiles) {
      $_ = $main::LibDir."/".$_;
      $_ = convertPath($_);
      printf SCF "-v $_\n";
    }
  }

  close SCF or die "$main::Pgm: ERROR - failed to close command file $main::simcommand after write\n";
  die "$main::Pgm: FATAL - $file_missing required files/directories missing. $main::Pgm terminating\n" if $file_missing;
 } else {
  die "$main::Pgm: FATAL - $main::Simulator is unsupported\n";
 }

}

sub commonVerilogIncludes($) {

  my $busType = shift;
  if (-e ${main::simcommand}) {
    open(RCB,">>${main::simcommand}") or
    die "$main::Pgm: ERROR -  couldn't open simulation command file $main::simcommand for write\n"
  } else {
    open(RCB,">${main::simcommand}") or
    die "$main::Pgm: ERROR -  couldn't open simulation command file $main::simcommand for write\n"
  }


  printf RCB "\n// -----------------------------------------------------------------------\n";
  printf RCB "// Simulation Source files and include directories\n";
  printf RCB "// -----------------------------------------------\n\n";

  if ($main::RtlSim eq "RTL") {
    if ($compile_src_files_with_y_option == 0) {
      printf RCB "-f ${main::RtlDir}/${main::DesignName}.lst\n";
    } else {
      printf RCB "-y ${main::RtlDir} \n";
       }
  } else {
    printf RCB "$main::Netlist\n\n";
  }

  if ($main::DesignName eq "DW_axi_gs"){
  printf RCB "-f ../tb.lst\n";
  } 

  printf RCB "+incdir+$main::RtlDir\n";
  printf RCB "+incdir+.\n";
  printf RCB "-y .\n\n";
  printf RCB "+incdir+../.\n";
  printf RCB "+incdir+$main::TestbenchDir\n";
  printf RCB "-y $main::TestbenchDir\n\n";

  if ($main::DesignName eq "DW_axi_gs"){
  printf RCB "+incdir+$main::TestbenchDir/prcm_vip\n";
  printf RCB "-y $main::TestbenchDir/prcm_vip\n\n";
  printf RCB "+incdir+$main::TestbenchDir/prcm_vip/include\n";
  printf RCB "-y $main::TestbenchDir/prcm_vip/include\n\n";
  printf RCB "+incdir+$main::TestbenchDir/prcm_vip/env\n";
  printf RCB "-y $main::TestbenchDir/prcm_vip/env\n\n";
  printf RCB "+incdir+$main::TestbenchDir/include\n";
  printf RCB "-y $main::TestbenchDir/include\n\n";
  }

  printf RCB "+incdir+$main::TestbenchDir/env\n";
  printf RCB "-y $main::TestbenchDir/env\n\n";

  if (($main::DesignName eq "DW_axi_hmx") or ($main::DesignName eq "DW_axi_rs") or ($main::DesignName eq "DW_axi_gm") or ($main::DesignName eq "DW_axi_gs") or ($main::DesignName eq "DW_axi_x2h") or ($main::DesignName eq "DW_axi_x2x") or ($main::DesignName eq "DW_axi_x2p")){
  if ($main::ccparams{USE_BACK2BACK_DUT}) {
    printf RCB "+incdir+$main::TestbenchDir/master_dut\n";
    printf RCB "+incdir+$main::TestbenchDir/slave_dut\n";
  }
  }

  printf RCB "+incdir+../models/vip/src/sverilog/vcs\n";
  printf RCB "+incdir+../models/vip/src/verilog/vcs\n";
  printf RCB "+incdir+../models/vip/include/verilog\n";
  printf RCB "+incdir+../models/vip/include/svtb\n";
  printf RCB "+incdir+../models/vip/include/sverilog\n";
  if (($main::DesignName eq "DW_axi_a2x") or ($main::DesignName eq "DW_axi_x2h")){
  printf RCB "-y $ENV{SYNOPSYS}/dw/sim_ver\n"; 
  }
  printf RCB "$main::testbench\n\n";

  if ($main::ccparams{USE_BACK2BACK_DUT}) {
    printf RCB "+incdir+$main::TestbenchDir/master_dut\n";
    printf RCB "+incdir+$main::TestbenchDir/slave_dut\n";
  }
  
  if (($main::DesignName eq "DW_axi_hmx") or ($main::DesignName eq "DW_axi_a2x") or ($main::DesignName eq "DW_axi_gm") or ($main::DesignName eq "DW_axi_gs") or ($main::DesignName eq "DW_axi_x2h") or ($main::DesignName eq "DW_axi_x2x") or ($main::DesignName eq "DW_axi_x2p")){ 
  if ($macro_prefix ne "") {
    #Get Design_unprefix file
    printf RCB "+define+MACRO_UNPREFIX_INCLUDE\n";
    printf RCB "+incdir+../../scratch\n";
  }
  }

  if (($main::DesignName eq "DW_axi_hmx") or ($main::DesignName eq "DW_axi_rs") or ($main::DesignName eq "DW_axi_gm") or ($main::DesignName eq "DW_axi_gs") or ($main::DesignName eq "DW_axi_x2h") or ($main::DesignName eq "DW_axi_x2x") or ($main::DesignName eq "DW_axi_x2p")){
  if ($main::ccparams{USE_BACK2BACK_DUT}) {
    printf RCB "-y ${main::TestbenchDir}/master_dut\n";
    printf RCB "-y ${main::TestbenchDir}/slave_dut\n";
  }
  }

  close RCB or die "$main::Pgm: ERROR - failed to close command file $main::simcommand after write\n";
  
}

sub runRalSim() {

  # -- Clean old log/wave/result files
  foreach (($main::DumpFile,$main::LogFile,$main::ResultFile)) {
    unlink($_) if (-e $_);
  }

  if (-f "./Makefile") {

    my $cmd_file = "test.startsim";
    print STDERR "$main::Pgm: Creating simulation start script ${main::Test}/$cmd_file\n";
    open(CMD,">$cmd_file") or die "$main::Pgm: ERROR - can't write startsim script \"$cmd_file\"\n";

    my $cmds = "make DESIGN=${main::DesignName} RAW=1";
    unless ($main::DumpEnabled and defined $main::DumpDepth) { $cmds = $cmds . " WAVES=0"; }
    unless ($main::SVCoverage) { $cmds = $cmds . " RUN_COVERAGE=0"; }
    unless ($main::RAL_coverage) { $cmds = $cmds . " RAL_COVERAGE=0"; }

    print CMD "$cmds\n\n";
    print CMD "/bin/rm -rf INCA_libs\n";
    print CMD "/bin/rm -rf csrc\n";
    unless($main::SVCoverage) { print CMD "/bin/rm -rf simv.daidir\n"; }
    print CMD "/bin/rm -rf simv\n";
    print CMD "chmod -R 777 *\n";

    close(CMD);

    # -- make command file executable
    system("chmod ugo+rx $cmd_file");

    # -- exit if you only want the scripts
    exit(0) if $main::Pretend;

    # -- print header and start time
    my $startdate = `date`; chomp $startdate;
    print STDERR "$main::Pgm: Running ${main::Test}/$cmd_file at $startdate\n";

    print STDERR "\n\n+------------------------+\n| Simulation Execution   |\n+------------------------+\n\n";
    print STDERR "(this section of runtest.log supplied by ${main::Test}/$cmd_file script)\n\n\n";

    # -- run command file
    my_system("./$cmd_file < /dev/null 2>&1 | tee $main::LogFile");

    # -- print end time and tail
    my $enddate = `date`; chomp $enddate;
    print STDERR "\n\n\n+--------------------+\n| Simulation Results |\n+--------------------+\n\n";
    print STDERR "$main::Pgm: Completed simulation at $enddate\n";
    print STDERR "$main::Pgm: The above simulation output was also saved to $main::LogFile : \n$main::Pgm:   file:${main::Cwd}/$main::LogFile\n";
  } else {
    print "ERROR: No Makefile found in the test_ral directory !";
    compile_exit( 11 );
  }
}

sub runSim() {

  # -/ --------------------------------------------------------------
  # -/ This function generates and run the simulation command line
  # -/ for the selected simulator.
  # -/ --------------------------------------------------------------

  # -- Clean old log/wave/result files
  foreach (($main::DumpFile,$main::LogFile,$main::ResultFile)) {
    unlink($_) if (-e $_);
  }

  # -- Generate command script
  my @Commands;

  my $cm_cflags;
  my $cm_rflags;
  my $sixtyfourbitswitch;

  # Code Coverage Switches
  if ($main::DesignName eq "DW_axi_a2x") {
  $cm_cflags = ($main::Coverage) ? " -cm line+cond+fsm+tgl+branch+assert -cm_tgl portsonly -cm_report unencrypted_hierarchies  -cm_noconst -cm_hier ../cm_hier_config" : "";
  $cm_rflags = ($main::Coverage) ? " -cm line+cond+fsm+tgl+branch+assert -cm_report unencrypted_hierarchies -cm_noconst -cm_hier ../cm_hier_config" : "";
  } else {
  $cm_cflags = ($main::Coverage) ? "-cm line+cond+fsm+tgl -cm_noconst -cm_seqnoconst  -cm_tgl portsonly -cm_hier ../cm_hier_config" : "";
  $cm_rflags = ($main::Coverage) ? "-cm line+cond+fsm+tgl -cm_hier ../cm_hier_config" : "";
  }

  if ($main::BCM_coverage) {
    $cm_cflags = ($main::Coverage) ? " -cm assert" : "";
    $cm_rflags = ($main::Coverage) ? " -cm assert" : "";
  }

  if (($main::Simulator eq "vcs") || ($main::Simulator eq "vcsi")) {
    if ($main::use64bitSimulator) {
      $sixtyfourbitswitch = "-full64";
    } else {
      $sixtyfourbitswitch = "";
    }
  }
  

  if (($compile_src_files_with_y_option == 1) and ($main::Coverage == 1)) {
    $cm_cflags = "$cm_cflags -cm_libs yv "
  }

  # Xprop switches
  my $cm_xprop_cfags = ($main::XpropEn) ? "-xprop=./../testbench/xprop.cfg" : "";
  my $cm_xprop_cfags_rpt = ($main::XpropEn) ? "-report=xprop" : "";

  # compile time system verilog options
  # -assert nopostproc: don't generate summary report at the end of sim for cover
  # statements, needed at runtime when -sverilog is used at compile time
  my $seed;

  if ($main::DesignName eq "DW_axi_a2x") {
    $seed = `grep A2X_SIM_SEED $main::ccparams_file `;
  } else {
    $seed = `grep SIM_RAND_SEED $main::ccparams_file `;   
  }
  my @seed_val = split(/\s+/,$seed);
   
   my $vcs_rca_compiler_options = "" ; 
  if (defined $main::vcs_compile_options_file) {
     if ($main::vcs_compile_options_file ne "nothing" ) {
       my @vcs_comp_options_file_a = ();
       my $vcs_comp_options_file = $main::vcs_compile_options_file;

       open(VCS_COMPILER_FILE,"<${vcs_comp_options_file}");
       @vcs_comp_options_file_a = <VCS_COMPILER_FILE>;
       close(VCS_COMPILER_FILE);

       foreach (@vcs_comp_options_file_a) {
         $vcs_rca_compiler_options = "$vcs_rca_compiler_options $_";
       }
       chomp $vcs_rca_compiler_options;
     }
  }  

  my $vcs_rca_simv_options = "" ; 
  if (defined $main::vcs_simv_options_file) {
     if ($main::vcs_simv_options_file ne "nothing" ) {
       my @vcs_simv_options_file_a = ();
       my $vcs_simv_options_file = $main::vcs_simv_options_file;

       open(VCS_SIMV_FILE,"<${vcs_simv_options_file}");
       @vcs_simv_options_file_a = <VCS_SIMV_FILE>;
       close(VCS_SIMV_FILE);

       foreach (@vcs_simv_options_file_a) {
         $vcs_rca_simv_options = "$vcs_rca_simv_options $_";
       }       
       chomp $vcs_rca_simv_options;
     }
  }   

  my $vcs_dbg_options = "" ; 
  if (defined $main::autorca_regr) {
    if (defined $main::vcs_compile_options_file) {
      if ($main::vcs_compile_options_file ne "nothing" ) {
        if (defined $main::add_dbg_access_all) {
          if ($main::add_dbg_access_all eq 1 ) {
            $vcs_dbg_options = "-debug_access+all";
          } else {
            $vcs_dbg_options = "";
          }
        } else {
          $vcs_dbg_options = "";
        }
      } else {
        $vcs_dbg_options = "-debug_access+all";
      }
    } else {
        $vcs_dbg_options = "-debug_access+all";
    }
  } else {
    $vcs_dbg_options = "-debug_access+all";
  }   

  my $uvm_verbosity_str="+UVM_VERBOSITY=UVM_LOW";
  my $uvm_stacktrace_str="+UVM_STACKTRACE=warn +UVM_STACKTRACE=error +UVM_STACKTRACE=fatal";  

  if (defined $main::incr_uvm_verbosity) {
    if ($main::incr_uvm_verbosity == 1) {
      $uvm_verbosity_str="$uvm_verbosity_str +uvm_set_verbosity=uvm_test_top.env.xact_predictor,_ALL_,UVM_DEBUG,run +uvm_set_verbosity=uvm_test_top.env.sb,_ALL_,UVM_DEBUG,run"
    }
  }  

  my $vcs_rand_seed_arg = "";
  $vcs_rand_seed_arg = "+ntb_random_seed=$seed_val[2] ";
  if (defined $main::test_seed) {
    if ($main::test_seed ne "-1") {
      my $seed_val_runtest_option;

      $seed_val_runtest_option = "$main::test_seed" ;
      $vcs_rand_seed_arg = " +ntb_random_seed=${seed_val_runtest_option} ";
    }
  } 
   
 
  my $timeout_val;
  if ($main::DesignName eq "DW_axi_x2h") {
    $timeout_val = 5000000000;
    } else {
    $timeout_val = 2000000000;
  }
   
  if ($main::Simulator eq "vcs" or $main::Simulator eq "vcsi") {
    my $PlatformFlags = "$sixtyfourbitswitch -Mupdate=1";
    if ($main::DesignName eq "DW_axi_a2x") {
    if (defined $main::autorca_regr) {
      @Commands = ("$main::Simulator -ntb_opts uvm -unit_timescale=100ps/100ps $vcs_dbg_options -k off $PlatformFlags $cm_cflags $vcs_rca_compiler_options -f $main::simcommand ",
                    "./simv $cm_rflags +UVM_TESTNAME=$main::Test +UVM_MAX_QUIT_COUNT=2 $uvm_verbosity_str $uvm_stacktrace_str $vcs_rand_seed_arg $vcs_rca_simv_options");
    } else {
      @Commands = ("$main::Simulator -ntb_opts uvm -unit_timescale=100ps/100ps -debug_access+nomemcbk+dmptf -debug_region+cell $PlatformFlags $cm_cflags -f $main::simcommand",
                   "./simv $cm_rflags +UVM_TESTNAME=$main::Test +ntb_random_seed=$seed_val[2] +UVM_TIMEOUT=$timeout_val");
    }

    } else {
          @Commands = ("$main::Simulator -q -ntb_opts uvm  -debug_access+nomemcbk+dmptf -debug_access+all -xlrm floating_pnt_constraint $PlatformFlags $cm_cflags $cm_xprop_cfags -f $main::simcommand -o ${main::Test}_simv -Mdir=${main::Test}_csrc",
                 "./${main::Test}_simv $cm_rflags +UVM_TESTNAME=$main::Test +ntb_random_seed=$seed_val[2] +UVM_VERBOSITY=UVM_LOW +UVM_TIMEOUT=$timeout_val,NO $cm_xprop_cfags_rpt");
 }
  
  
  } else {
    die "$main::Pgm: ERROR - Unknown simulator $main::Simulator not yet supported.\n";
  }
  my $cmd_file = "test.startsim";
  print STDERR "$main::Pgm: Creating simulation start script ${main::Test}/$cmd_file containing:\n";
  open(CMD,">$cmd_file") or die "$main::Pgm: ERROR - can't write startsim script \"$cmd_file\"\n";
  foreach my $cmd (@Commands) {
    print CMD "$cmd\n";
    print STDERR "$main::Pgm:    % $cmd\n";
  }

 if (defined $main::autorca_regr) {
  } else {
    print CMD "/bin/rm -rf *.o\n";
    print CMD "/bin/rm -rf INCA_libs\n";
    print CMD "/bin/rm -rf work*\n";
    print CMD "/bin/rm -rf csrc\n";
    unless($main::SVCoverage) { print CMD "/bin/rm -rf simv.daidir\n"; }
    print CMD "/bin/rm -rf simv\n";
    print CMD "/bin/rm -rf *.exe\n";
    print CMD "/bin/rm -rf *.vro\n";
    print CMD "chmod -R 777 *\n";
  }
 
  close(CMD);

  # -- make command file executable
  system("chmod ugo+rx $cmd_file");
  # -- exit if you only want the scripts
  exit(0) if $main::Pretend;

  # -- print header and start time
  my $startdate = `date`; chomp $startdate;
  print STDERR "$main::Pgm: Running ${main::Test}/$cmd_file at $startdate\n";

  print STDERR "\n\n+------------------------+\n| Simulation Execution   |\n+------------------------+\n\n";
  print STDERR "(this section of runtest.log supplied by ${main::Test}/$cmd_file script)\n\n\n";

  system ("rm -f test.json");
  my $ret_val0=`$PATH_TO_JSON_PL_SCRIPTS/logtime.pl --log start`;


  # -- run command file
  my_system("./$cmd_file < /dev/null 2>&1 | tee $main::LogFile");

  # -- print end time and tail
  my $enddate = `date`; chomp $enddate;
  my $ret_val1=`$PATH_TO_JSON_PL_SCRIPTS/logtime.pl --log end`;
  
  if (($main::DesignName ne "DW_axi_a2x")) {
  &logSeed( Seed => $seed_val[2]);
  }


  print STDERR "\n\n\n+--------------------+\n| Simulation Results |\n+--------------------+\n\n";
  print STDERR "$main::Pgm: Completed simulation at $enddate\n";
  print STDERR "$main::Pgm: The above simulation output was also saved to $main::LogFile : \n$main::Pgm:   file:${main::Cwd}/$main::LogFile\n";

}

sub postProcess() {

  my $errorConditions = "";
  my $errorExceptions = "";
  my $errorFile = "../html_extraction_config_file";
  my @configFileContents = ();
  open (CF, "<${errorFile}");
  @configFileContents = <CF>;
  close(CF);
  chomp(@configFileContents);
  foreach (@configFileContents) {
    if (/errorConditions:"(.*?)"/) {
      $errorConditions = $1;
    }
    if (/errorExceptions:"(.*?)"/) {
      $errorExceptions = $1;
    }
  }
  # -/ --------------------------------------------------------------
  # -/ This function parses the simulation log files and reports a
  # -/ test pass or fail status
  # -/ --------------------------------------------------------------
  `/bin/rm -rf passed failed timeout`;
  `/bin/rm -fr ../passed/$main::Test`;
  `/bin/rm -fr ../timeout/$main::Test`;
  `/bin/rm -fr ../failed/$main::Test`;

  open (RESULT,">$main::ResultFile") || die "$main::Pgm: ERROR: can't open result file $main::ResultFile for write\n";
  my $result;
  if(! check_errors()) {
     my $ret_val2=`$PATH_TO_JSON_PL_SCRIPTS/logresult.pl --log pass`;
    
    $result = "PASSED";
    if(&check_warnings()) {
      if (&check_illegal_prog()) {
        $result .= " (WARNINGS and ILLEGAL PROGRAMMING)";
      } else {
        $result .= " (WARNINGS)";
      }
    } else {
      if (&check_illegal_prog()) {
        $result .= " (ILLEGAL PROGRAMMING)";
      }
    }
    if (act_cert_requested() && act_certified()) {
      $result .= " (ACT CERTIFIED)";
    }
    if (act_recert_requested() && act_recertified()) {
      $result .= "(ACT RECERTIFIED)";
    }

    if (defined $main::delete_passing_test_log) {
      if ($main::delete_passing_test_log == 1) {
        system ("egrep -i \"automatic random seed \" test.log >> test.sim_rand_seed");
        if (defined $main::keep_simv) {
          #giving opytion for regr. to keep simv files
          if ($main::keep_simv eq "True") {
          } else {
            `/bin/rm -rf simv simv.daidir csrc`;
            `/bin/rm -rf test.log`;
            `/bin/rm -rf novas* `;
          }
        } else {
          `/bin/rm -rf simv simv.daidir csrc`;
          `/bin/rm -rf test.log`;
          `/bin/rm -rf novas* `;
        }
      }
    }
  } else {
    my $error_signatures;
    $result = "FAILED";
    if(&check_timeouts()) {
      $result .= " (TIMEOUT)";
       $error_signatures = `egrep -i  \"$errorConditions\" $main::LogFile | egrep -iv \"$errorExceptions\" | grep TIMEOUT | grep -v "+TIMEOUT" | egrep -m2 ".*"`;
    } else {
       $error_signatures = `egrep -i  \"$errorConditions\" $main::LogFile | egrep -iv \"$errorExceptions\" | egrep -m2 ".*"`;
    }

    my $ret_val3=`$PATH_TO_JSON_PL_SCRIPTS/logresult.pl --log fail`;
    chomp($error_signatures);

    # IP specific code to extract test status
    &logTestResult( Result => $result );

    # IP specific code to extract error message
    &logTestError( Error => $error_signatures);
    

    if (act_cert_requested() && !act_certified()) {
      $result .= "(ACT CERTIFICATION FAILURE)";
    }
    if (act_recert_requested() && !act_recertified()) {
      $result .= "(ACT RECERTIFICATION FAILURE)";
    }
    
  }
  print RESULT "$result \n";

  close RESULT || die "$main::Pgm: ERROR: can't close result file $main::ResultFile after write\n";
  print STDERR "$main::Pgm: Final result in ${main::Test}/${main::ResultFile} - Result is \"$result\"\n\n";
  printf STDERR "Result:  %-19s  Test: $main::Summary\n\n","\"$result\"";

}

sub act_recertified() {
   my $act_recertified = 0;
   my @act_recertification_required = glob(".sim_was_run_with_recert*");
   my $act_recert_requests = @act_recertification_required;
   my @certificates;
   my $certificates_found;
   if ($act_recert_requests>0) {
     @certificates = glob("re_act*");
     $certificates_found = @certificates;
     if ($certificates_found>0) {
       $act_recertified = 0;
     } else {
       $act_recertified = 1;
     }
   }
   return $act_recertified;
}
sub act_recert_requested() {
  # -/ -------------------------------------------------------------
  # -/ Checks to see if ACT recertification was requested in this test
  # -/--------------------------------------------------------------
  my $recert_requested = 0;
  my @act_recert_requests = glob (".sim_was_run_with_recert*");
  my $act_recert_requests = @act_recert_requests;
  if ($act_recert_requests>0) {
    $recert_requested = 1;
  }
  return $recert_requested;
}
sub act_cert_requested() {
  # -/ -------------------------------------------------------------
  # -/ Checks to see if ACT certification was requested in this test
  # -/--------------------------------------------------------------
  my $cert_requested = 0;
  my @act_requests = glob (".sim_was_run_with_act_mon*");
  my $act_requests = @act_requests;
  if ($act_requests>0) {
    $cert_requested = 1;
  }
  return $cert_requested;
}

sub act_certified() {
 # -/ -------------------------------------------------------------
 # -/ Checks that a certificate file has been generated for each
 # -/ requested certificate
 # -/ -------------------------------------------------------------
  my $certified = 1;
  my @act_requests = glob (".sim_was_run_with_act_mon*");
  my @act_certs = glob ("act*.certificate");
  my $number_of_requests = @act_requests;
  my $number_of_certs = @act_certs;
  if ($number_of_requests != $number_of_certs) {
    $certified = 0;
  }
  return $certified;
}
sub check_errors() {

  # -/ --------------------------------------------------------------
  # -/ look through log files for for lines with the word 'error' or
  # -/ 'fatal' in their first N characters, ie chances are they are
  # -/ error messages of some form. This is a strict and safe
  # -/ catch-all and may match on completely innocent lines.
  # -/ --------------------------------------------------------------

  my $errorConditions = "";
  my $errorExceptions = "";
  my $errorFile = "../html_extraction_config_file";
  my @configFileContents = ();
  open (CF, "<${errorFile}");
  @configFileContents = <CF>;
  close(CF);
  chomp(@configFileContents);
  foreach (@configFileContents) {
    if (/errorConditions:"(.*?)"/) {
      $errorConditions = $1;
    }
    if (/errorExceptions:"(.*?)"/) {
      $errorExceptions = $1;
    }
  }
  my $rv = 0;
  my $errors = 0;
  my @errors = "";

  @errors = `egrep -i  \"$errorConditions\" $main::LogFile | egrep -iv \"$errorExceptions\"`;
  open(SCF_ERROR,">test.error") or die "$main::Pgm: ERROR -  couldn't open simulation command file test.error for write\n";
  foreach my $err_line (@errors) { $errors++; print SCF_ERROR "$err_line\n";}
  close SCF_ERROR;

  # -/ --------------------------------------------------------------
  # -/ Catch vcs warnings that should be considered failures.
  # -/ i.e. could be a failure to a third party tool.
  # -/ --------------------------------------------------------------
  my $error_warnings = 0;

 # This is a compile time warning - So code like ( in X2H )
 #         if (`X2H_AHB_ADDR_WIDTH == 64)
 #            mhaddr  =  mhaddr_reg;
 #          else
 #            mhaddr  = {{(64-`X2H_AHB_ADDR_WIDTH){1'b0}},mhaddr_reg};
 # will still give a warning when `X2H_AHB_ADDR_WIDTH == 64
 # as the compiler seems to parse both
 # branches of the if statement regardless of the X2H_AHB_ADDR_WIDTH
 # value. This may be new to VCS 2006.06! and is causing sims to fail

   my @error_warnings;

  foreach(@error_warnings) { $error_warnings++; }

  if (($errors > 0) || ($error_warnings > 0)) {
    $rv = 1;
  }

    #------------------------------------------------------------------------------------------------------------------------------------------
  #Json file updates for known issues
  #------------------------------------------------------------------------------------------------------------------------------------------
  my $enable_known_issue_reporting="0";
  if ( ($enable_known_issue_reporting eq 1) and ($rv ne 0) ) {
    my $known_issues_file="../store_regr_failures.json";
    if ( -f $known_issues_file) {
      my @input_data;
      open (INFILE,"$known_issues_file");   #opening the file in read mode only
      @input_data = <INFILE>;  #store the input file data into array
      close INFILE;
      
      
      my $count=0; 
      my $IssueID;
      my $Configs;
      my $Tests;
      my $ErrorString;
      my $IssueType;
      my $JiraID="";
      my $Date="";
      my $User="";
      my $Owner="";
      my $TbOwner="";
      my $DutOwner="";      
      
      foreach (@input_data) {
        if (/"IssueID" : "(.*?)",/) {
          $IssueID = $1;
        }
        if (/"ErrorString" : "(.*?)",/) {
          $ErrorString = $1;
        }
        if (/"Tests" : "(.*?)",/) {
          $Tests = $1;
        }
        if (/"IssueType" : "(.*?)",/) {
          $IssueType = $1;
        }
        if (/"Configs" : "(.*?)",/) {
          $Configs = $1;
        }
        if (/"Date" : "(.*?)",/) {
          $Date = $1;
        }
        if (/"User" : "(.*?)",/) {
          $User = $1;
        }
        if (/"Owner" : "(.*?)",/) {
          $Owner = $1;
        }
        if (/"TbOwner" : "(.*?)",/) {
          $TbOwner = $1;
        }
        if (/"DutOwner" : "(.*?)",/) {
          $DutOwner = $1;
        }        
        if (/"JiraId" : "(.*?)"/) {
          $JiraID = $1;
        }
        if (/^\}$/) {
           print STDERR  "IssueID - $IssueID\n";
           print STDERR  "Configs - $Configs\n";
           print STDERR  "Tests - $Tests\n";
           print STDERR  "ErrorString - $ErrorString\n";
           print STDERR  "IssueType - $IssueType\n";
           print STDERR  "JiraID - $JiraID\n";        
           print STDERR  "User - $User\n";        
           print STDERR  "Owner - $Owner\n";        
           print STDERR  "DutOwner - $DutOwner\n";        
           print STDERR  "TbOwner - $TbOwner\n";           
           print STDERR  "Date - $Date\n";        
          my @errors_str="";
          my $errors_cnt = 0;
          my $item;
          @errors_str = `egrep -i \"$ErrorString\" test.error`;
          foreach my $err_line (@errors_str) { 
            $errors_cnt++; 
            #print STDERR "$err_line\n";
          }

          #match test name in Tests string
          open(SCF_ERROR,">test.err_list") or die "$main::Pgm: ERROR -  couldn't open simulation command file test.err_list for write\n";
          print SCF_ERROR "$Tests\n";
          close SCF_ERROR;          

          my @tests_str="";
          my $tests_cnt = 0;
          my $item;
          @tests_str = `egrep -i \"$main::Test\" test.err_list `;
          foreach my $tst_line (@tests_str) { 
            $tests_cnt++; 
            #print STDERR "$tst_line\n";
          }          
          system("rm -f test.err_list");


          if ( ($errors_cnt > 0)) {
            &logKnownIssue(
              IssueId => $IssueID,
              Issue => {
                Users  => "$User",
                Date   => "$Date",
                Source => "$IssueType",
                Links  => "$JiraID"
              }
            );            
            &logOwner(
              Owner => {
                Owners => "$Owner",
                Components => {
                  "DUT" => {
                    Owners => "$DutOwner"
                  },
                  "TB" => {
                    Owners => "$TbOwner"
                  }
                },
              }
            );             
          }
          
        }
        $count = $count + 1;
      }      
    }
  }
  system("rm -f test.error");
  #------------------------------------------------------------------------------------------------------------------------------------------



  return $rv;

}

sub check_warnings() {

  # -/ --------------------------------------------------------------
  # -/ Find warnings other than:
  # -/ a. runtest warnings
  # -/ b. inout coercion
  # -/ --------------------------------------------------------------

  my %warningsSeen;
  my $warningItem;
  my @uniquifiedWarningList;
  my @warnings;
  my $key;
  my @verifiedWarnings;
  my $warningFound;
  @warnings = `grep -i warning $main::LogFile | egrep -v "Number of demoted UVM_WARNING reports" | egrep -v "Number of caught UVM_WARNING" | egrep -v "UVM_WARNING : "`;
  foreach $warningItem (@warnings) {
    chomp($warningItem);
    $_ = $warningItem;
    $warningsSeen{"$warningItem"}++;
  }
  my $value;
  @uniquifiedWarningList = keys %warningsSeen;
  if (-e "../testbench/verifiedWarnings.txt") {
    open (OK_WARNINGS, "<../testbench/verifiedWarnings.txt");
    my @verifiedWarnings = <OK_WARNINGS> ;
    close(OK_WARNINGS);
    chomp(@verifiedWarnings);
    foreach $key (@uniquifiedWarningList) {
      foreach $warningFound (@verifiedWarnings) {
        if ($key =~ /$warningFound/) {
          delete($warningsSeen{"$key"});
        }
      }
    }
  }

  foreach $warningItem (sort keys %warningsSeen) {
    print "$warningItem \n";
  }
  my $warnings = scalar(%warningsSeen);
  return $warnings;

}
sub check_illegal_prog() {

  # -/ --------------------------------------------------------------
  # -/ Finds illegal programming:
  # -/ --------------------------------------------------------------

  my $illegal_prog = 0;
  my @illegal_prog = `grep ILLEGAL_PROG $main::LogFile`;
  foreach(@illegal_prog) { $illegal_prog++; }
  return $illegal_prog;

}
sub check_timeouts() {

  # -/ --------------------------------------------------------------
  # -/ Find timeout and return N
  # -/ --------------------------------------------------------------

  my $timeouts = 0;
  my @timeouts = `grep TIMEOUT $main::LogFile | egrep -v "\+TIMEOUT|\+UVM_TIMEOUT"`;
  foreach(@timeouts) { $timeouts++; }
  return $timeouts;

}
sub my_system($) {

  # -/ --------------------------------------------------------------
  # -/ my_system() - a system call with success/fail check plus
  # -/ Pretend/Verbose support
  # -/ --------------------------------------------------------------

  my $cmd = shift;

  if($main::Pretend or $main::Verbose) {
    printf STDERR "$main::Pgm: running \"$cmd\"\n";
  }
  unless ($main::Pretend) {
    system($cmd);
    die "$main::Pgm: ERROR - command \"$cmd\" failed, exit code $?\n" if($?);
  }

}


1;
