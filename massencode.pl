#!c:/perl/bin/perl.exe
#
# Recursively goes through files and encodes raw DVD files.
#
# Version 0.1
# Copyright (C) 2009. Kirk Morales, Invisoft, LLC (kirk@invisoft.com)
#
# Open-source project hosted at: http://code.google.com/p/handbrakecli-massencode/
#
# This program is free software; you can redistribute it and/or modify it under the terms 
# of the GNU General Public License as published by the Free Software Foundation; 
# either version 2 of the License, or any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; 
# if not, write to the Free Software Foundation, Inc., 59 Temple Place, 
# Suite 330, Boston, MA 02111-1307 USA
#
# TODO: (kmorales) Implement pause/resume in TraverseDirectory()
# TODO: (kmorales) Add option for media search type (other than DVD)

use Getopt::Long;

use strict;
use warnings;

#----------------------------------------------------------------------
# Options
#----------------------------------------------------------------------

my $source;
my $output;
my $recursive;
my $delete_dvd;
my $hcli;
my $file_format;
my $pause;
my $resume;
my $params;
my $verbose;
my $log_file;
my $help;
my $test;

my $optstatus = GetOptions(
  'f=s'			=> \$file_format,
  'format=s'	=> \$file_format,
  'i=s'			=> \$source,
  'input=s'		=> \$source,
  'o=s'			=> \$output,
  'output=s'	=> \$output,
  'hcli=s'		=> \$hcli,
  'R'			=> \$recursive,
  'D'			=> \$delete_dvd,
  'pause=s'		=> \$pause,
  'resume=s'	=> \$resume,
  'params=s'	=> \$params,
  'test'		=> \$test,
  'verbose'		=> \$verbose,
  'v'			=> \$verbose,
  'log=s'		=> \$log_file,
  'l=s'			=> \$log_file,
  'help'		=> \$help,
  'h'			=> \$help
);

my $dvd_extensions = "(bup)|(ifo)|(vob)";
my $dir_sep = '/';
my $out_text;


#----------------------------------------------------------------------
# Script
#----------------------------------------------------------------------

Usage() if ($help);

my ($sec,$min,$hour) = (localtime(time))[0,1,2];
Log("Mass Encode started at " . sprintf("%02d:%02d:%02d",$hour,$min,$sec) . "\n\n");

# Check for required parameters.
unless( $source and $file_format ) {
	print "\nMissing Required Parameter: ";
	Usage();
}

# Check that $file_format contains valid value
if( $file_format !~ /avi|mp4|ogm|mkv/i ) {
	print "\nInvalid value for -f or --format: '$file_format'";
	Usage();
}

# Check for params
unless( $params ) {
	print "\nNo Handbrake CLI parameters specified.";
	Usage();
}

# If no alternate location for handbrake, use the defaults.
unless( $hcli ) {
	my $os = $^O;
	if( $os =~ /linux/ ) {
		$hcli = '';
	} else {
		$hcli = 'C:\Program Files\HandBrake\HandBrakeCLI.exe';
		$dir_sep = "\\";
	}
}

# Format output directory
if( $output and $output !~ /$dir_sep$/ ) {
	$output .= $dir_sep; 
}

# Check existence of CLI
unless( -e $hcli or $test ) {
	print "\nHandbrake CLI not found at '$hcli'\n";
}

TraverseDirectory($source);

($sec,$min,$hour) = (localtime(time))[0,1,2];
Log("Mass Encode ended at " . sprintf("%02d:%02d:%02d",$hour,$min,$sec) . "\n\n");

# Save log file
WriteLog() if( $log_file );



#----------------------------------------------------------------------
# Subroutines
#----------------------------------------------------------------------

sub Usage {
	print "\n\nUSAGE: massencode -i SOURCE -f FORMAT --params PARAMS [options]

Required-----------------------------------------------------------------

  -i, --input PATH\tThe directory to search for DVD files.
  -f, --format TYPE\tThe format of the output files. (avi,mp4,ogm,mkv)
  --params PARAMS\tHandbrake CLI command parameter/values to use 
			EXCLUDING -i, -o, -f. (Surround in quotes).

Optional-----------------------------------------------------------------

  -o, --output PATH\tThe directory to save output files to 
			(Default: Location of DVD Files).
  --hcli FILE\t\tThe location of Handbrake CLI 
			(Default: C:\\Program Files\\Handbrake\\HandBrakeCLI.exe).
  -R\t\t\tRecursively go through each folder looking for DVDs.
  -D\t\t\tDelete the original DVD files upon successful encoding.
  -v, --verbose\t\tEnables verbose logging.
  -l, --log\t\tLogs all output to the specified file.
  --pause TIME\t\tThe time to pause encoding (HHMM).
  --resume TIME\t\tThe time to resume encoding (HHMM).
  -h, --help\t\tPrints this usage information.\n";
	exit;
}

# Appends output text.
sub Log {
	my ($text, $die) = @_;

	print "$text";
	$out_text .= $text;
	
	if( $die ) {
		print "\n\nExecution stopped.\n";
		WriteLog() if( $log_file );
		exit;
	}
}

# Writes out the log file.
sub WriteLog {
	open(LOG, ">$log_file");
	print LOG $out_text;
	close(LOG);
}

# Goes through each directory looking for files.
sub TraverseDirectory {
  my $path = shift;

  # append a trailing / if it's not there
  $path .= $dir_sep if($path !~ /$dir_sep$/);

  Log("\nChecking '$path' for DVD files...") if( $verbose );

  if( ContainsDVD($path) or $test ) {
	  Log("\n");
	  Encode($path);
  } else {
	  Log("none.\n");
  }

  # loop through the files contained in the directory
  if( $recursive ) {
	  opendir my($dh), $path or Log("Couldn't open dir '$path': $!", 1);
	  my @files = readdir $dh;
	  closedir $dh;
	  for my $eachFile (@files) {
		  TraverseDirectory("$path$eachFile") if( -d "$path$eachFile" and $eachFile !~ /^\./ );
	  }
  }
  
  return 1;
}

# Checks if a directory contains DVD files.
sub ContainsDVD {
	my $dir = shift;

	opendir my($dh), $dir or Log("Couldn't open dir '$dir': $!", 1);
	my @files = readdir $dh;
	closedir $dh;

	my @matches = grep( /\.($dvd_extensions)$/ig, @files );
	if( @matches >= 1 ) {
		return 1;
	} else {
		return 0;
	}
}

# Encodes the DVD files within the specified folder.
sub Encode {
	my $dir = shift;

	# Get current directory name (use for file name)
	my $cur_dir;
	if( $dir =~ m/[\\\/]([^\\\/]+)[\\\/]$/i ) {
		$cur_dir = $1;
	}

	# Create output file location
	my $out_file;
	if( $output ) {
		$out_file = $output;
	} else {
		$out_file = $dir;
	}
	$out_file .= $cur_dir . '.' . $file_format;

	# Remove trailing slash from directory or you get "Missing outfile file name" error.
	while( $dir =~ /[\\\/]$/ ) {
		$dir = substr $dir, 0, length($dir)-1;
	}

	# Add quotes around paths if they have spaces
	$dir = "\"$dir\"" if($dir =~ /\s/g);
	$out_file = "\"$out_file\"" if($out_file =~ /\s/g);
	$hcli = "\"$hcli\"" if($hcli =~ /\s/g and $hcli !~ /^\"/ and $hcli !~ /\"$/);

	# Format CLI commmand
	my $handbrake = "$hcli -i $dir -o $out_file $params";
	$handbrake .= ' -v' if($verbose);

	# Execute Handbrake CLI command
	($sec,$min,$hour) = (localtime(time))[0,1,2];
	Log("\tEncoding '$dir'...Started at " . sprintf("%02d:%02d:%02d",$hour,$min,$sec));
	Log("\n\tCommand: $handbrake") if ($verbose);
	my $cli_out = `$handbrake`;
	Log("\n$cli_out") if($verbose);
	($sec,$min,$hour) = (localtime(time))[0,1,2];
	Log("\n\tFinished at " . sprintf("%02d:%02d:%02d",$hour,$min,$sec) . "\n");

	# If delete flag is set, delete original files
	if( $delete_dvd ) {
		Log("Deleting Original DVD Files...");
		$dir .= $dir_sep; # add trailing slash back
		# Delete all DVD files
		my $dh;
		unless( opendir $dh, $dir ) {
			Log("Couldn't open dir '$dir' to delete DVD files: $!");
			return 1;
		}
		my @dvd_files = readdir $dh;
		closedir $dh;

		foreach my $dvd_file (@dvd_files) {
			unlink "$dir$dvd_file" if ($dvd_file =~ /\.($dvd_extensions)$/i);
		}
		Log("OK\n");
	}

	return 1;
}