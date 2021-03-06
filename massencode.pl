#!c:/perl/bin/perl.exe
#
# Recursively goes through directories and encodes media files.
#
# Uses HandBrake <http://handbrake.fr> under the terms of the GNU General Public License.
#
# Version 0.1.06 BETA
# Copyright (C) 2009. Kirk Morales, Invisoft, LLC (kirk@invisoft.com)
#
# Open-source project hosted at: http://code.google.com/p/handbrakecli-massencode/
#
# This program is free software; you can redistribute it and/or modify it under the terms 
# of the GNU General Public License as published by the Free Software Foundation; 
# either version 3 of the License, or any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; 
# if not, write to the Free Software Foundation, Inc., 59 Temple Place, 
# Suite 330, Boston, MA 02111-1307 USA
#
# TODO: (kmorales) Get rid of double slashes in file paths.
#		(kmorales) Add option for media search type (other than DVD).
# 

use Getopt::Long;
use Time::Local;
use File::Path;

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
my $params;
my $verbose;
my $log_file;
my $help;
my $test;
my $force_overwrite;
my $log_buffer = 256000;

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
  'p=s'			=> \$pause,
  'pause=s'		=> \$pause,
  'params=s'	=> \$params,
  'test'		=> \$test,
  'verbose'		=> \$verbose,
  'v'			=> \$verbose,
  'log=s'		=> \$log_file,
  'l=s'			=> \$log_file,
  'force'		=> \$force_overwrite,
  'logbuffer=i'	=> \$log_buffer,
  'help'		=> \$help,
  'h'			=> \$help
);

my $dvd_extensions = "(bup)|(ifo)|(vob)";
my $dir_sep = '/';
my $out_text;
my $encode_count = 0;


#----------------------------------------------------------------------
# Script
#----------------------------------------------------------------------

Usage() if ($help);

# Check for required parameters.
unless( $source and $file_format ) {
	print "\nMissing Required Parameter: ";
	Usage();
}

# Remove trailing slash for source
while( $source =~ /[\\\/]$/ ) {
	$source = substr $source, 0, length($source)-1;
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
	if( $os =~ /linux/i ) {
		$hcli = './';
	} elsif( $os =~ /win/i ) {
		$hcli = 'C:\Program Files\HandBrake\HandBrakeCLI.exe';
		$dir_sep = "\\\\";
	}
}

# Format output directory
if( $output and $output !~ /($dir_sep)$/ ) {
	$output .= $dir_sep; 
}

# Check existence of CLI
unless( -e $hcli or $test ) {
	print "\nHandbrake CLI not found at '$hcli'\n";
}

# Clear out output file if it exists
if( $log_file and -e $log_file ) {
	open(LOG, ">$log_file");
	print LOG '';
	close(LOG);
}

# Parse pause times
my @pause_times;
if( $pause ) {
	Log("\nPause times specified.\n");
	@pause_times = split( /\,/, $pause );
}

# Show start time
my ($sec,$min,$hour) = (localtime(time))[0,1,2];
Log("\nMass Encode started at " . sprintf("%02d:%02d:%02d",$hour,$min,$sec) . "\n\n");

# Start looking for media
TraverseDirectory($source);

# Print end time
($sec,$min,$hour) = (localtime(time))[0,1,2];
Log("Mass Encode ended at " . sprintf("%02d:%02d:%02d",$hour,$min,$sec) . "\n\n");

# Save log file
AppendLog() if( $log_file );

#----------------------------------------------------------------------
# Subroutines
#----------------------------------------------------------------------

sub Usage {
	print "\n\nUSAGE: massencode -i SOURCE -f FORMAT --params PARAMS [options]

Required-----------------------------------------------------------------

  -i, --input PATH\tThe directory to search for media files. NO TRAILING \
  -f, --format TYPE\tThe format of the output files. enum(avi,mp4,ogm,mkv)
  --params \"PARAMS\"\tHandbrake CLI command parameter/values to use 
			EXCLUDING -i, -o, -f. (Surround in quotes).

Optional-----------------------------------------------------------------

  -o, --output PATH\tThe directory to save output files to. Will be overwritten 
			if exists. (Default: Location of media file/DVD found).

  --hcli FILE\t\tThe location of Handbrake CLI. Defaults:
			Windows: C:\\Program Files\\Handbrake\\HandBrakeCLI.exe
			Linux: Current working directory.

  -R\t\t\tRecursively go through each folder looking for media.
  -D\t\t\tDelete the original media file(s) upon successful encoding.
  -v, --verbose\t\tEnables verbose logging.
  -l, --log\t\tLogs all output to the specified file.
  -p, --pause HHMM:HHMM\tThe time to pause encoding on a 24-hour scale. Separate ranges by a comma.
  --force\t\tIf the output file already exists, overwrite it.

  --logbuffer BYTES\tThe number of bytes to keep in memory before writing to the log. 
			Default: 256000. Exception: Log will always be written after encoding a file.

  --test\t\tFunctions the same without actually encoding anything. Shows what 
			all output and Handbrake CLI commands would look like.

  -h, --help\t\tPrints this usage information.\n";
	exit;
}

# Appends output text.
sub Log {
	my ($text, %options) = @_;

	print $text;

	if( $log_file ) {
		$out_text .= $text;

		# Get string size in bytes. If it exceeds 250Kb then append it to the output file.
		my $size;
		{
			use bytes;
			$size = length($out_text);
		}
		if( $size >= $log_buffer ) {
			AppendLog();
			$out_text = '';
		}
	}

	# Write to log if the log file exists and the force/die option is set
	AppendLog() if($log_file and ($options{Force} or $options{Kill}));
	
	# Stop execution if the die option is set
	die "\n\nErrors - Execution stopped.\n" if( $options{Kill} );
}

# Writes out the log file.
sub AppendLog {
	return unless($log_file);

	my $rpt;

	# Write to log file only if the handle's been opened
	if( open($rpt, ">>$log_file") ) {
		print $rpt $out_text;
		close($rpt);
	} else {
		print "Couldn't open file '$log_file' for writing. All attempts failed. Check permissions.\n";
	}
}

# Converts seconds to hh:mm:ss
sub convert_seconds_to_hhmmss {
	my $hourz=int($_[0]/3600);
	my $leftover=$_[0] % 3600;
	my $minz=int($leftover/60);
	my $secz=int($leftover % 60);
  
	return sprintf ("%02d:%02d:%02d", $hourz,$minz,$secz)
 }

# Checks the current time and pauses if need be.
sub CheckPause {
	my $cur_epoch = time();
	my ($sec, $min, $hour, $day, $mon, $year) = (localtime($cur_epoch))[0,1,2,3,4,5];

	my $cur_time = sprintf("%02d%02d", $hour, $min);

	# see if the current time falls within a pause range
	foreach my $timespan (@pause_times) {
		my ($pause_start, $pause_end) = split( /\:/, $timespan );
		next unless($pause_start and $pause_end);

		if( $cur_time >= $pause_start and $cur_time <= $pause_end ) {

			# We need to pause. Figure out how many seconds.
			if( $pause_end =~ m/(\d\d)(\d\d)/ ) {
				$hour = $1;
				$min = $2;
			} else {
				Log("WARNING: End pause time not in correct format: '$pause_end'. Pause range will not be applied.\n");
			}

			my $pause_end_epoch = timelocal(0,$min,$hour,$day,$mon,$year);
			my $pause_sec = $pause_end_epoch - $cur_epoch;

			Log("\nSleeping for " . convert_seconds_to_hhmmss($pause_sec) . " seconds until $hour:$min...\n\n");

			# Force a log write in case something happens during sleep
			AppendLog();
			$out_text = '';

			sleep($pause_sec);

			last;
		}
	}
}

# Goes through each directory looking for files.
sub TraverseDirectory {
  my $path = shift;
  
  # Check times. Pause if need be
  CheckPause() if($pause);

  # append a trailing / if it's not there
  $path .= $dir_sep if($path !~ /($dir_sep)$/);

  Log("\nChecking '$path' for media files...") if( $verbose );

  if( ContainsDVD($path) ) {
	  Log("\n");
	  Encode($path);
  } else {
	  Log("none.\n");
  }

  # loop through the files contained in the directory
  if( $recursive ) {
	  opendir my($dh), $path or Log("WARNING: Couldn't open dir '$path': $!");
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

	opendir my($dh), $dir or Log("Couldn't open dir '$dir': $!", Kill => 1);
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
	if( $dir =~ m/[\\\/]+([^\\\/]+)[\\\/]*$/i ) {
		$cur_dir = $1;
	} else {
		$cur_dir = "unknown_" . $encode_count;
	}

	# Check for illegal output directory
	if( $cur_dir =~ /^\$/ ) {
		Log("Illegal directory name: $cur_dir. Skipping.\n\n");
		return;
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

	# See if out_file exists
	if( -e $out_file and !$force_overwrite ) {
		Log("$out_file already exists. Skipping.\n\n");
		return;
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
	Log("\nEncoding $dir...Started at " . sprintf("%02d:%02d:%02d",$hour,$min,$sec));
	Log("\n\tCommand: $handbrake");

	my $cli_out = `$handbrake` unless($test);

	Log("\n$cli_out") if($verbose and $cli_out);

	# If delete flag is set, delete original files
	if( $delete_dvd ) {

		Log("Deleting Original File(s)...");
		$dir =~ s/\"//g; # remove quotes from directory name
		$dir .= $dir_sep; # add trailing slash back

		# Delete all DVD files
		my $dh;
		unless( opendir($dh, $dir) ) {
			Log("Couldn't open dir '$dir' to delete media file(s): $!");
			return 1;
		}
		my @dvd_files = readdir $dh;
		closedir $dh;

		foreach my $dvd_file (@dvd_files) {
			unlink "$dir$dvd_file" if ($dvd_file =~ /\.($dvd_extensions)$/i);
		}
		Log("OK\n");

		# See if folder is empty
		unless( opendir($dh, $dir) ) {
			Log("Couldn't open dir '$dir' to check empty folder: $!");
			return 1;
		}
		@dvd_files = readdir $dh;
		closedir $dh;

		# Will delete if empty
		if( rmdir($dir) ) {
			Log("$dir deleted.\n");
		} else {
			Log("$dir is not empty. Folder will not be deleted.\n");
		}
	}
	$encode_count++;
	
	($sec,$min,$hour) = (localtime(time))[0,1,2];
	Log("\n\tFinished at " . sprintf("%02d:%02d:%02d",$hour,$min,$sec) . "\n", 'Force'=>1);

	return 1;
}