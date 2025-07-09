#!/usr/bin/perl

use warnings;
use strict;

my $comment_variable = '#';
my $my_file = './.auto_run/check.dat';

sub Read_File {
	my($file) = @_;

	open(TEMP, $file) || Fail_Open($file);
	my @lines = <TEMP>;
	close(TEMP);
	return @lines;
}

sub Chomp_Command {
	my ($command) = @_;

	my $results = `$command`;
	chomp($results);
	return $results;
}

sub CheckDat {
	my $error;
	my $suffix;
	my $number;
	my $string;
	my $cond_suffix;
	my $condition_check;
	open(FLOG,'>',"./result.log");
	foreach my $line (Read_File("$my_file")) {
		chomp($line);
		if (substr($line,0,1) =~ /$comment_variable/){
            next;
		}
		undef $cond_suffix;
		if ($line =~ /^\s*(!\s*\S+|\[.+\]|\S+)\s*->\s*(.+)$/){
			#get two parts from ->
			my $first_part = $1;
			my $second_part = $2;

			$first_part =~ s/^\s*//;
			$first_part =~ s/\s*$//;
			$second_part =~ s/^\s*//;
			$second_part =~ s/\s*$//;
			#print "--> $first_part , $second_part";
			if ($first_part =~ /^!/){
				$cond_suffix = "not_check_exist";
				$condition_check = $first_part;
				$condition_check =~ s/^!\s*//;
			}elsif ($first_part =~ /^\[.+\]$/){
				$cond_suffix = "test_expr";
				$condition_check = $first_part;
			}else{
				$cond_suffix = "check_exist";
				$condition_check = $first_part;
			}
			# Conditional format - reread line
			($suffix, $number, $string) = split(" ", $second_part, 3);
			#print "-->$suffix, $number, $string, $condition_check, $cond_suffix";
		}else{
		   ($suffix, $number, $string) = split(" ", $line, 3);
		}

		if( !defined($number)) {
			#print "Error: Bad syntax: $line \n";
			$error = 1;
			next;
		}

		if ($number !~ m!^\d+\+?$!) {
			#print "Error: Invalid count $number\n";
			$error = 1;
			next;
		}

		if (defined($cond_suffix)) {
			my $file;
			if ($cond_suffix eq "check_exist"){
				$file = $condition_check;
				if (!-e $file) {
					#print "Skipping conditional check because $file doesn't exist\n";
					next;
				}
			}
			#conditional start with !
			if ($cond_suffix eq "not_check_exist"){
				$file = $condition_check;
				if (-e $file) {
					#print "Skipping conditional check because !$file is not true\n";
					next;
				}
			}
			#conditional check with test_expr 
			if ($cond_suffix eq "test_expr"){
			    $file = $condition_check;
			    #if start with grep
			    if ($file =~ /^\[\s*"`\s*(grep\s*.+)`"\s/){
					my $grep_line = $1;
					my $result = Chomp_Command(" $grep_line 2>/dev/null");
					if (($? >> 8) > 0) {
						#print "Error: bad regular expression $file\n";
						$error = 1;
						next;
					}
			    }
			    #check even " and `
			    my $tmp_file = $file;
			    $tmp_file =~ s/\\("|')//g;
			    my @ary = split ("\"", $tmp_file);
			    my $check_quot = $#ary % 2;
			    @ary = split ("`", $file);
			    my $check_tick = $#ary % 2;
			    @ary = split ("'", $file);
			    my $check_one = $#ary % 2;

			    if ($check_quot != 0 || $check_tick != 0 || $check_one != 0) {
					#print "Error: bad syntax in string $condition_check\n";
					$error = 1;
					next;
			    }
			    $file =~ s/^\[\s*//;
			    $file =~ s/\s*\]$//;
			    my $test = system ("test $file");
			    if (($test >> 8) > 0) {
					#print "Skipping conditional check because $file is not true\n";
					next;
			    }
			}
		}

		# Get the file to check out.
		my @log_files = ("$suffix");

		my ($line_error, @matchedlines);
		foreach my $log ( @log_files) {
			if (!-e $log) {
				print FLOG "Error: $log doesn't exist\n";
				next;
			}
			$string =~ s!\s*$!!;
			if ( $string =~ m!^'.*[^']$! || $string =~ m!^[^'].*'$! || $string =~ m!^".*[^"]$! || $string =~ m!^[^"].*"$!) {
				print FLOG "Error: bad syntax in string $string\n";
				$error = 1;
				last;
			}
			my $results = Chomp_Command("grep -ic $string $log 2>/dev/null");
			@matchedlines = `grep -in $string $log 2>/dev/null`;


			my $orignumber = $number;
			my $gtflag = $number =~ s!\+$!!;
			if (!$gtflag && $results != $number || $gtflag && $results < $number) {
				print FLOG "Error: Expected $orignumber of $string in $log; actual $results\n";
				$line_error = 1;
			} else {
				print FLOG "OK: Expected $orignumber of $string in $log; actual $results\n";
				my $matchid = 1;
				foreach $line (@matchedlines) {
					print FLOG ("  " .  $matchid . ". line " . $line);
					$matchid++;
				}
				$line_error = 0;
				last;
			}
		}
		if ($line_error) {
			my $id =1;
			foreach $line (@matchedlines) {
				print FLOG ("  " .$id . ". line " . $line);
				$id++;
			}
			$error =1 ;
		}
	}
	
	if ($error) {
		print "failed\n";
	} else {
		print "passed\n";
	}
	close (FLOG);
}


CheckDat();