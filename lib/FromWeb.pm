package lib::FromWeb;

#-------------------------------------------------------------------------------
# package: FromWeb.pm
#
# Function:
#   This module holds all functions which are necessary to fetch comic data
#   from the web.
#-------------------------------------------------------------------------------

use strict;
use warnings;
use 5.18.0;
use utf8;

use LWP::Simple;
use XML::LibXML;

use Data::Dumper;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);


# Load HTML document of a comic book into a perl DOM structure for further
# processing
#
sub get_dom {
	my $url = shift;

	my $dom;

	if ($url !~ /^http/i) {
		# not a URL but most propably a file which has to be read
		open my $fh, '<', $url or die "Couldn't open http file $url: $!";
		$dom = XML::LibXML->load_html (
			IO => $fh,
			recover         => 1,
			suppress_errors => 1,
			no_blanks       => 1,
		) or warn "Couldn't parse website with LibXML:\n$!";

		close $fh;
	}
	else {
		# Since XML::LibXML cant load https URLs the download of the webpage has
		# to be done with LWP
		my $content = get ( $url );
		die "Couldn't get URL: $url" until $content;

		$dom = XML::LibXML->load_html(
			string          => $content,
			recover         => 1,
			suppress_errors => 1,
			no_blanks       => 1,
		) or warn "Couldn't parse website with LibXML:\n$!";
	}

	return $dom;
}

sub pack_excerpt {
	my $files = shift;  # Arrayref of files to be packed
	my $series = shift; # Name of the series the ZIP file shall belong to
	my $number = shift; # Number of the issue of the series

	my $zip = Archive::Zip->new();

	foreach my $page ( @$files ) {
		$zip->addFile ( $page ) or warn "Couldn't add $page to ZIP: $!";
	}

	$series =~ s/ +/_/g;
	my $zip_name = sprintf( '%s%s_%03d%s', './tmp/', $series, $number, '_Leseprobe.cbz');

	my $status = $zip->writeToFileNamed($zip_name);  # Write archive to disc
	warn "Error while writing $zip_name to file: $!" if $status;
}

1;