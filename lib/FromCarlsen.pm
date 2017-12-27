package lib::FromCarlsen;

#-------------------------------------------------------------------------------
# package: FromCarlsen
#
# Function:
#   
#-------------------------------------------------------------------------------

use strict;
use warnings;
use 5.18.0;
use utf8;

use File::Copy;
use XML::LibXML;

use Data::Dumper;

# Gets the comic book details from a Carlsen DOM structure
#
sub get_details_Carlsen {
	my $dom = shift;
	my $details = shift;

#	my $details = {};   # will hold the found comic details

	#---------------- P U B L I S H E R ------------------
	$details->{Verlag} = 'Carlsen Verlag GmbH';

	#---------------- TITLE, SUBTITLE, NO, COVERTYPE --------------

	my @hits = $dom->findnodes( '//h1[@class="buchdetail_title"]');

	if ( scalar @hits > 1 || scalar @hits == 0 ) {
		warn "No or too many hits to determine title unambiguously!";
	}
	else {
		my $string = $hits[0]->to_literal;
		say $string;

		if ( $string =~ /^(.*)(?=\s+\d+)\s+(\d{1,3}):\s+(.+)(?=\s+?[(]\w+[)])\s+?[(](.*)[)]$/) {
			# Format of the string is like:
			# 'Series 1: Title of series (Covertype)'
			# '<series> <number>: <title of series> (<covertype>)'
			$1 ? $details->{'Heft-Titel'} = $1 : warn "No 'Heft-Titel' found.";
			$2 ? $details->{'Serien-Nr.'} = $2 : warn "No 'Serien-Nr.' found.";
			$3 ? $details->{'Heft-Untertitel'} = $3 : warn "No 'Heft-Untertitel' found.";
			$4 ? $details->{'Einbandart'} = $4 : warn "No 'Einbandart' found.";
		}
	}

	#------------------ I S B N -----------------------
	# TODO: get ISBN

	#------------------ D A T E  P U B L I S H E D ----------------

	@hits = $dom->findnodes( '//div[@class="buchdetail_state hidden"]/span[@itemprop="datePublished"]');

	if ( scalar @hits > 1 || scalar @hits == 0 ) {
		warn "No or too many hits to determine date published unambiguously!";
	}
	else {
		my ( $date, undef ) = split 'T', $hits[0]->to_literal;

		if ( $date =~ /\d{4}-\d{1,2}-\d{1,2}/) {
			my ( $year, $month, $day ) = split '-', $date;

			$details->{'Erstauflage'} = join '.', $day, $month, $year;
		}
		else {
			warn "No valid 'Erstauflage' found";
		}
	}

	#---------------- C U R R E N C Y ------------

	@hits = $dom->findnodes( '//span[@itemprop="priceCurrency"]');
	if ( scalar @hits > 1 || scalar @hits == 0 ) {
		warn "No or too many hits to determine currency unambiguously!";
	}
	else {
		$details->{currency} = $hits[0]->to_literal;
	}


	#---------------- P R I C E -----------------

	@hits = $dom->findnodes( '//span[@itemprop="price"]');

	if ( scalar @hits > 1 || scalar @hits == 0 ) {
		warn "No or too many hits to determine price unambiguously!";
	}
	else {
		my $price = $hits[0]->to_literal;
		$price =~ s/\./,/;
		$details->{'Einkaufspreis'} = $price . ' ' . $details->{currency};
		$details->{'Originalpreis'} = $details->{'Einkaufspreis'};
	}


	#---------------- N O  O F  P A G E S ------------

	@hits = $dom->findnodes( '//span[@itemprop="numberOfPages"]');
	if ( scalar @hits > 1 || scalar @hits == 0 ) {
		warn "No or too many hits to determine 'Seiten' unambiguously!";
	}
	else {
		$details->{Seiten} = $hits[0]->to_literal;
	}


	#------------------------ C O N T E N T --------------------

	# unfortunately not all text of the content is stored in 'og:description'
	#	@hits = $dom->findnodes( '//meta[@property="og:description"]');
	@hits = $dom->findnodes( '//div[@class="txt_box"]/p');

	if ( scalar @hits > 1 || scalar @hits == 0 ) {
		warn "No or too many hits to determine content unambiguously!";
	}
	else {
#		$details->{'Inhalt/Geschichte'} = $hits[0]->getAttribute('content');
		$details->{'Inhalt/Geschichte'} = $hits[0]->to_literal;
	}

	#---------------- A U T H O R -----------------

	# Selects the first element with the attribute classt='buchdetail_autor'
	# XPath found on
	# http://stackoverflow.com/questions/1006283/xpath-select-first-element-with-a-specific-attribute
	@hits = $dom->findnodes( '(//div[@class="buchdetail_autor"])[1]/ul/li/a');

	if ( scalar scalar @hits == 0 ) {
		warn "No author(s) found!";
	}
	else {

		$details->{'Autor(en)'} = join ', ', map ($_->to_literal, @hits);
		$details->{'Autor(en) + Job'} = $details->{'Autor(en)'};
	}

	#------------------ C O V E R --------------------
	$details->{'Link zum Cover'} =
		sprintf ( "%s_%03d.jpg", $details->{'Heft-Titel'}, $details->{'Serien-Nr.'} )
		if $details->{'Heft-Titel'} && $details->{'Serien-Nr.'} ;
	$details->{'Link zum Cover'} =~ s/ +/_/g;

	return $details;
}

# Gets the cover image of a comic book from the Carlsen DOM structure and
# stores them on hard disk
# TODO: Even though there are sometimes previews of the comic book available,
#       I haven't found a way to download them
#
sub get_images_Carlsen {
	my $dom = shift;
	my $covername = shift;

	my @hits = $dom->findnodes( '//meta[@property="og:image"]');

	my $cover_url;

	if ( scalar @hits > 1 || scalar @hits == 0 ) {
		warn "No or too many hits to determine cover unambiguously!";
	}
	else {
		$cover_url = $hits[0]->getAttribute('content');
	}

	my $file = './tmp/' . $covername;

	# download cover and store it on hard drive
	my $lwp_return = LWP::Simple::getstore( $cover_url, $file );
	die "Error while downloading images" if $lwp_return != 200;
}

1;