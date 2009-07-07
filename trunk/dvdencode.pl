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
my $encoder;
my $quality;
my $hcli;
my $two_pass;
my $cpu;
my $file_format;
my $pause;
my $resume;
my $help;

my $optstatus = GetOptions(
  'f=s'			=> \$file_format,
  'format=s'	=> \$file_format,
  'i=s'			=> \$source,
  'input=s'		=> \$source,
  'o=s'			=> \$output,
  'output=s'	=> \$output,
  'e=s'			=> \$encoder,
  'encoder=s'	=> \$encoder,
  'q=s'			=> \$quality,
  'quality=s'	=> \$quality,
  '2'			=> \$two_pass,
  'two-pass'	=> \$two_pass,
  'C=i'			=> \$cpu,
  'cpu=i'		=> \$cpu,
  'hcli=s'		=> \$hcli,
  'R'			=> \$recursive,
  'D'			=> \$delete_dvd,
  'pause=s'		=> \$pause,
  'resume=s'	=> \$resume,
  'help'		=> \$help,
  'h'			=> \$help
);

$quality = "1.0" unless $quality;

my $dvd_extensions = "bup|ifo|vob";


#----------------------------------------------------------------------
# Script
#----------------------------------------------------------------------

Usage() if ($help);

# Check for required parameters.
unless( $source and $file_format ) {
	print "\nMissing Required Parameter.";
	Usage();
}

# Check that $file_format contains valid value
if( $file_format !~ /avi|mp4|ogm|mkv/i ) {
	print "\nInvalid value for -f or --format: '$file_format'";
	Usage();
}

# Check that $encoding contains valid value
if( $encoder and $encoder !~ /ffmpeg|xvid|x264|theora/i ) {
	print "\nInvalid value for -e or --encoder: '$encoder'";
	Usage();
}

# Format output directory
if( $output and $output !~ /\/$/ ) {
	$output .= '/' 
}

# If no alternate location for handbrake, use the defaults.
unless( $hcli ) {
	my $os = $^O;
	if( $os =~ /linux/ ) {
		$hcli = '';
	} else {
		$hcli = 'C:\Program Files\Handbrake\HandBrakeCLI.exe';
	}
}

# Check existence of CLI
unless( -e $hcli ) {
	print "\nHandbrake CLI not found at '$hcli'\n";
}

print GenerateCLICommand($source, 'M:\test.avi');
exit;

TraverseDirectory($source);


#----------------------------------------------------------------------
# Subroutines
#----------------------------------------------------------------------

sub Usage {
	print "\n\nUSAGE: dvdencode.exe -i SOURCE -f FORMAT [OPTIONS]

  -i, --input PATH\tThe directory to search for DVD files.
  -f, --format TYPE\tThe format of the output files. (avi,mp4,ogm,mkv)
	
Handbrake CLI Options-------------------------------------------------

  -e, --encoder TYPE\t\tThe encoding type to use.
	  (ffmpeg,xvid,x264,theora) (Default: ffmpeg).
  -q, --quality <decimal>\tThe quality (0.0 to 1.0). (Default 1.0).
  -2, --two-pass\t\tEnable two-pass mode.
  -C, --cpu\t\t\tThe number of CPUs to use (Default: autodetect).

Wrapper Options-------------------------------------------------------

  -o, --output PATH\tThe directory to save output files to 
			(Default: Location of DVD Files).
  --pause TIME\t\tThe time to pause encoding (HHMM).
  --resume TIME\t\tThe time to resume encoding (HHMM).
  --hcli <string>\tThe location of Handbrake CLI 
			(Default: C:\\Program Files\\Handbrake\\HandBrakeCLI.exe).
  -R\t\t\tRecursively go through each folder looking for DVDs.
  -D\t\t\tDelete the original DVD files upon successful encoding.
  -h\t\t\tPrints this usage information.\n";
	exit;
}

# Generates the CLI Command for encoding.
sub GenerateCLICommand {
	my ($in, $out) = @_;

	my $handbrake = "$hcli -i $in -o $out -q $quality";
	$handbrake .= " -e $encoder" if ($encoder);
	$handbrake .= " -2" if ($two_pass);
	$handbrake .= " --cpu $cpu" if ($cpu);

	return $handbrake;
}

# Goes through each directory looking for files.
sub TraverseDirectory {
  my $path = shift;

  # append a trailing / if it's not there
  $path .= '/' if($path !~ /\/$/);

  print "Checking '$path' for DVD files...\n";

  Encode($path) if( ContainsDVD($path) );

  # loop through the files contained in the directory
  if( $recursive ) {
	  for my $eachFile (glob($path.'*')) {
		  recurse($eachFile) if( -d $eachFile);
	  }
  }
  
  return 1;
}

# Checks if a directory contains DVD files.
sub ContainsDVD {
	my $dir = shift;

	opendir my($dh), $dir or die "Couldn't open dir '$dir': $!";
	my @files = readdir $dh;
	closedir $dh;

	my @matches = grep( /$dvd_extensions/i, @files );
	if( @matches >= 1 ) {
		return 1;
	} else {
		return 0;
	}
}

# Encodes the DVD files within the specified folder.
sub Encode {
	my $dir = shift;

	# TODO: Check the time and pause if necessary

	# Get current directory name (use for file name)
	my $cur_dir;
	if( $dir =~ m/[\/\\](.*)[\/\\]$/i ) {
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

	my $handbrake = GenerateCLICommand($dir, $out_file);

	# Execute Handbrake CLI command
	print "Encoding '$dir'\n\t$handbrake...";
	`$handbrake`;
	print "OK\n";

	# If delete flag is set, delete original files
	if( $delete_dvd ) {
		print "Deleting Original DVD Files...";
		# Delete all DVD files
		opendir my($dh), $dir or die "Couldn't open dir '$dir': $!";
		my @dvd_files = readdir $dh;
		closedir $dh;

		foreach my $dvd_file (@dvd_files) {
			unlink $dvd_file if ($dvd_file =~ /\.$dvd_extensions$/i);
		}
		print "OK\n";
	}

	return 1;
}