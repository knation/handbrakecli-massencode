#!c:/perl/bin/perl.exe
#
# Recursively goes through files and encodes raw DVD files.
#
# Version 0.1
# Copyright (C) 2009. Kirk Morales, Invisoft, LLC (kirk@invisoft.com)
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
my $recursive;
my $delete_dvd;
my $encoding;
my $file_format;
my $preset;
my $hcli;
my $two_pass;
my $help;

my $optstatus = GetOptions(
  'i=s'			=> \$source,
  'input=s'		=> \$source,
  'e=s'			=> \$encoding,
  'q=s'			=> \$quality,
  'quality=s'	=> \$quality,
  'encoder=s'	=> \$encoding,
  'format=s'	=> \$file_format,
  'f=s'			=> \$file_format,
  'preset=s'	=> \$preset,
  'hcli=s'		=> \$hcli,
  'R'			=> \$recursive,
  'D'			=> \$delete_dvd,
  '2'			=> \$two_pass,
  'two-pass'	=> \$two_pass,
  'help'		=> \$help,
  'h'			=> \$help
);


#----------------------------------------------------------------------
# Script
#----------------------------------------------------------------------

Usage() if ($help);

unless( $source and $encoding ) {
	print "\nMissing Required Parameter.";
	Usage();
}

# TODO: Check the $encoding contains valid value

# If no alternate location for handbrake, use the defaults.
unless( $hcli ) {
	my $os = $^O;
	if( $os =~ /linux/ ) {
		$hcli = '';
	} else {
		$hcli = '';
	}
}

TraverseDirectory($source);


#----------------------------------------------------------------------
# Subroutines
#----------------------------------------------------------------------

sub Usage {
	print "\n\n./dvdencode -i SOURCE -F FORMAT [OPTIONS]

  -i, --input <string>\tThe directory to search for DVD files.
  -f, --format <avi/mp4/ogm/mkv>\tThe output file format.
	
  --hcli <string>\tThe location of Handbrake CLI (Default: ).
  -e, --encoder <string>\tThe encoding type to use.
  -q, --quality <decimal>\tThe quality (0.0 to 1.0). (Default 1.0).
  --preset <string>\tThe preset to use. (Default: Film)
  -2, --two-pass\tEnable two-pass mode.
  -R\t\tRecursively go through each folder looking for DVDs.
  -D\t\tDelete the original DVD files upon successful encoding.
  -h\t\tPrints this usage information.\n";
	exit;
}

# Goes through each directory looking for files.
sub TraverseDirectory {
	my $dir = shift;

	# Get a directory listing
	opendir my($dh), $dir or die "Couldn't open dir '$dir': $!";
	my @files = readdir $dh;
	closedir $dh;

	foreach my $file (@files) {
		if( $file ne "." and $file ne ".." and $file !~ /\.[a-z]+$/i ) {
			Encode("$dir/$file") if( ContainsDVD("$dir/$file") );
		}

		TraverseDirectory("$dir/$file") if ($recursive);
	}
}

# Checks if a directory contains DVD files.
sub ContainsDVD {
	my $dir = shift;

	opendir my($dh), $dir or die "Couldn't open dir '$dir': $!";
	my @files = readdir $dh;
	closedir $dh;
}

# Encodes the DVD files within the specified folder.
sub Encode {
	my $dir = shift;

	my $handbrake = ""

	print "Encoding '$dir'\n\tHandbrake CLI: $handbrake";

	if( $delete_dvd ) {
		# TODO: Get all DVD files
		my @dvd_files;

		foreach (@dvdfiles) {
			unlink;
		}
	}

	return 1;
}