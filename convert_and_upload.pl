#!/usr/bin/perl

use strict;												# Always use strict !
use MikroTik::API;   											# Remember to install this through CPAN


my $target = @ARGV[0];											# Which directory did we download the blacklists to?


my $api = MikroTik::API->new({
	host => '10.99.4.1',
	username => 'importer',
	password => 'mysecretpassword',
	use_ssl => 1,
});

parse_dir($target, "");

$api->logout();

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

			while (my $line = <$input>) {
				chomp($line);								# Remove the linefeed from the end of the line
				$line =~ s/\r//;							# Remove any windows carriage returns (if there are any)
				if ($line =~ /[^a-zA-Z0-9\.-]/) {					# Ignore any non-ascii characters
					# unprintable characters ?
					#die("Unprintable characters: ".$line);
				} else {								# Add this entry to the RB

					eval {								# We need an eval block here because the guy that wrote MikroTik::API 
													# apparently doesn't believe in error handling and just dies on (non-fatal) errors
						my $returnvalue = $api->cmd( '/ip/firewall/address-list/add', 
								{ 'address' => $line, 'list' => $category } );
						print "ERROR: $line\n" if ($returnvalue >= 2);
					};
					if ($@) {
						print "ERROR: $@\n";
					}
				}
			}

			close($input);									# always close what we opened
		}

	}
	closedir $dh;	
}



