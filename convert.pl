#!/usr/bin/perl

use strict;												# Always use strict !
use POSIX;


my $target = @ARGV[0];											# Which directory did we download the blacklists to?


my $outputdir = strftime("%Y%m%d%H%M%S", localtime(time()))."/";					# Create our output directory
mkdir($outputdir);

parse_dir($target, "");

sub parse_dir {
	my ($target, $category) = @_;

	opendir(my $dh, $target) || die "Can't open $target: $!";					# List all subdirectories and files in our target directory
	while (readdir $dh) {
		my $file = $_;										

		if ($file =~ /^\.+$/) {
			# don't do anything

		} elsif (-d $target."/".$file) {							# is this entry is a directory

			my $newcategory = $category;							# The name of the subdirectory will be appended to the category, and become the name of the address list
			if ($newcategory ne "") { 
				$newcategory .= "-";
			}
			$newcategory .= $file;
			
			parse_dir($target."/".$file, $newcategory);					# call ourself



		} elsif ($file eq "domains" && -f $target."/".$file) {					# if this target file is a file named "domains"

			print "$category\n";

			open(my $input, $target."/".$file) 						# open the file and prepare for reading its content
				|| die "Error opening input file: $!";

			open(my $output, ">".$outputdir.$category.".rsc") 				# open our output file (one per category)
				|| die "Error opening output file: $!";

			print $output "/ip firewall address-list\n";					# add the initial header to the output file

			while (my $line = <$input>) {
				chomp($line);								# Remove the linefeed from the end of the line
				$line =~ s/\r//;							# Remove any windows carriage returns (if there are any)
				if ($line =~ /[^a-zA-Z0-9\.-]/) {					# Ignore any non-ascii characters
					# unprintable characters ?
					#die("Unprintable characters: ".$line);
				} else {								# print this line to the output file
					print $output "add address=$line list=$category\n";
				}
			}

			close($input);									# always close what we opened
			close($output);
		}

	}
	closedir $dh;	
}
