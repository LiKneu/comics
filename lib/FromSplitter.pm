package lib::FromSplitter;

#-------------------------------------------------------------------------------
# package: FromSplitter
#
# Function:
#   
#-------------------------------------------------------------------------------

use strict;
use warnings;
use 5.18.0;
use Data::Dumper;
use utf8;

use utf8;

use File::Copy;
use XML::LibXML;

# Gets the comic book details from a Splitter DOM structure
#
sub get_details_Splitter {
	my $dom = shift;

	my $details = {};   # will hold the found comic details

	#---------------- T I T L E --------------

	# Finds all <h1> nodes with attribute 'class="product-info-title-desktop hidden-xs hidden-sm"'
	# If there are more than one hit no unambiguous title could be found
	my @hits = $dom->findnodes( '//h1[@class="product-info-title-desktop hidden-xs hidden-sm"]');

	if ( scalar @hits > 1 || scalar @hits == 0 ) {
		warn "No or too many hits to determine title unambiguously!";
	}
	else {
		my $string = $hits[0]->to_literal;

		if ( $string =~ /^(.+)\sBd\.\s+?(\d{1,2}):\s+?([\w\s]+)$/ ) {
			# Format of the string is like:
			# 'Series Bd. 1: Title of series'
			# '<series> Bd. <number>: <title of series>'
			$1 ? $details->{'Heft-Titel'} = $1 : warn "No 'Heft-Titel' found.";
			$2 ? $details->{'Serien-Nr.'} = $2 : warn "No 'Serien-Nr.' found.";
			$3 ? $details->{'Heft-Untertitel'} = $3 : warn "No 'Heft-Untertitel' found.";
		}
		else {
			# Most propably not a series but a single book/issue
			$details->{'Heft-Titel'} = $string;
			$details->{'Heft-Untertitel'} = $string;
		}
	}

	#----------------- C O N T E N T --------------

	@hits = $dom->findnodes( '//div[@class="tab-body active"]');

	if ( scalar @hits > 1 || scalar @hits == 0 ) {
		warn "No or too many hits to determine comic book content unambiguously!";
	}
	else {
		my @strings;    # contains descriptions

		foreach ( @hits ) {
			my $string = $_->to_literal;
			$string =~ s/\t+/ /g;
			$string =~ s/ +/ /g;
			$string =~ s/^\s+//;
			$string =~ s/\s+$//;
			push @strings, $string;
		}

		my $result = join "\n", @strings;

		$details->{'Inhalt/Geschichte'} = $result;
	}


	#-------------- P R I C E -------------------

	@hits = $dom->findnodes( '//div[@class="current-price-container"]' );

	if ( scalar @hits > 1 || scalar @hits == 0 ) {
		warn "No or too many hits to determine comic book price unambiguously!";
	}
	else {
		my $string = $hits[0]->to_literal;
		$string =~ /(\d{1,3},\d{2}) ([A-Z]{2,3})/;
		$1 ? $details->{price} = $1 : warn "Price not found!";
		$2 ? $details->{currency} = $2 : warn "Currency not found!";
	}


	#-------------------- I S B N ------------------

	#@hits = $dom->findnodes( '//span[@itemprop="model"]' );
	@hits = $dom->findnodes( '//dt[text()[contains(.,"ISBN:")]]/following-sibling::dd[1]' );

	if ( scalar @hits > 1 || scalar @hits == 0 ) {
		warn "No or too many hits to determine comic book ISBN-no. unambiguously!";
	}
	else {
		my $string = $hits[0]->to_literal;
		$string =~ /([\d-]{10,})/;
		$1 ? $details->{'ISBN/Barcode-Nr.'} = $1 : warn "'ISBN/Barcode-Nr.' not found!";
	}


	#------------------- A U T H O R ----------------------

	@hits = $dom->findnodes( '//dt[text()="Autor"]/following-sibling::dd[1]');
	if ( scalar @hits > 1 || scalar @hits == 0 ) {
		warn "No or too many hits to determine comic book author unambiguously!";
	}
	else {
		my $string = $hits[0]->to_literal;
		$string ? $details->{author} = $string : warn "Author not found!";
	}


	#------------------- A R T I S T ----------------------

	@hits = $dom->findnodes( '//dt[text()="Zeichner"]/following-sibling::dd[1]');
	if ( scalar @hits > 1 || scalar @hits == 0 ) {
		warn "No or too many hits to determine comic book artist unambiguously!";
	}
	else {
		my $string = $hits[0]->to_literal;
		$string ? $details->{artist} = $string : warn "Artist not found!";
	}


	#------------------- T R A N S L A T O R ----------------------

	@hits = $dom->findnodes( '//dt[text()="Übersetzer"]/following-sibling::dd[1]');
	if ( scalar @hits > 1 || scalar @hits == 0 ) {
		warn "No or too many hits to determine comic book translator unambiguously!";
	}
	else {
		my $string = $hits[0]->to_literal;
		$string ? $details->{translator} = $string : warn "Translator not found!";
	}


	#------------------- C O V E R  T Y P E ----------------------

	@hits = $dom->findnodes( '//dt[text()="Einband"]/following-sibling::dd[1]');
	if ( scalar @hits > 1 || scalar @hits == 0 ) {
		warn "No or too many hits to determine comic book cover type unambiguously!";
	}
	else {
		my $string = $hits[0]->to_literal;
		$string ? $details->{'cover tpye'} = $string : warn "Cover type not found!";
	}


	#------------------- N U M B E R  of  P A G E S ----------------------

	@hits = $dom->findnodes( '//dt[text()="Seitenzahl"]/following-sibling::dd[1]');
	if ( scalar @hits > 1 || scalar @hits == 0 ) {
		warn "No or too many hits to determine comic book number of 'Seiten' unambiguously!";
	}
	else {
		my $string = $hits[0]->to_literal;
		if ( $string ) {
			# In case there is more than just the page numbers extract the
			# number only
			$string =~ /(\d{1,3})/;
			$1 ? $details->{'Seiten'} = $1 : warn "Number of 'Seiten' not found!";
		}
	}


	#------------------- N U M B E R  of  I S S U E S ----------------------

	@hits = $dom->findnodes( '//dt[text()="Band"]/following-sibling::dd[1]');
	if ( scalar @hits > 1 || scalar @hits == 0 ) {
		warn "No or too many hits to determine comic book number of issues unambiguously!";
	}
	else {
		my $string = $hits[0]->to_literal;

		if ( $string ) {
			$string =~ /(\d{1,2}) von (\d{1,2})/; # pattern: '<issue no.> von <issue numbers>'
			$2 ? $details->{'Serie von'} = $2 : warn "'Serie von' not found!";

			# If no issue number was given in the title then try to get it
			# from this field
			$1 && !$details->{'Serien-Nr.'} ? $details->{'Serien-Nr.'} = $1 : warn "Issue number not found!";
		}
	}

	return $details;
}

sub hash_to_array {
	my $details = shift;

	my $comic_info = [];        # Array to be printed into a cvs file
	@$comic_info = ("") x 37;   # Initiate array with all possible but empty fields

	# [0] Heft-Titel            $details->{'Heft-Titel'}
	$details->{'Heft-Titel'} ? $comic_info->[0] = $details->{'Heft-Titel'} : warn "No 'Heft-Titel'";

	# [1] Heft-Untertitel       $details->{'Heft-Untertitel'}
	$details->{'Heft-Untertitel'} ? $comic_info->[1] = $details->{'Heft-Untertitel'} : warn "No 'Heft-Untertitel'";

	# [2] Sprache               'deutsch'
	$comic_info->[2] = 'deutsch';

	# [3] Serien-Nr.            $details->{'Serien-Nr.'}
	$details->{'Serien-Nr.'} ? $comic_info->[3] = $details->{'Serien-Nr.'} : warn "No 'Serien-Nr.'";

	# [4] Serie von
	#$details->{'Serie von'} ? $comic_info->[4] = $details->{'Serie von'} : warn "No 'Serie von'";
	$comic_info->[4] = '10';

	# [5] ISBN/Barcode-Nr.      $details->{'ISBN/Barcode-Nr.'}
	$details->{'ISBN/Barcode-Nr.'} ? $comic_info->[5] = $details->{'ISBN/Barcode-Nr.'} : warn "No 'ISBN/Barcode-Nr.'";

	# [6] Verlag                'Splitter-Verlag GmbH'
	$comic_info->[6] = 'Splitter-Verlag GmbH';

	# [7] Erstauflage

	# [8] Kaufdatum

	# [9] Originalpreis         $details->{price} . 'EUR'
	$details->{price} ? $comic_info->[9] = $details->{price} . ' EUR' : warn "No original price";

	# [10] Einkaufspreis        $details->{price} . 'EUR'
	$details->{price} ? $comic_info->[10] = $details->{price} . ' EUR' : warn "No purchase price";

	# [11] Akt. Handelspreis

	# [12] Händler              'Buchhandlung VielSeitig Rohe und Pütz oHG'
	$comic_info->[12] = 'Buchhandlung VielSeitig Rohe und Pütz oHG';

	# [13] Bemerkung 1
	$comic_info->[13] = 'Auf 1111 Exemplare limitierte Sonderedition zum 10 jährigen Jubiläum des Splitter Verlag.';

	# [14] URL

	# [15] Autor(en)            $details->{author}, $details->{artist}
	if ( $details->{author} && $details->{artist} ) {
		if ( $details->{author} eq $details->{artist} ) {
			$comic_info->[15] = $details->{author};
		}
		else {
			$comic_info->[15] = $details->{author} . ', ' . $details->{artist};
		}
	}
	else {
		$comic_info->[15] = $details->{author} if  $details->{author};
		$comic_info->[15] = $details->{artist} if $details->{artist};
	}

	# [16] Zustand              'Keine Mängel, makellos'
	$comic_info->[16] = 'Keine Mängel, makellos';

	# [17] Eigenschaft(en)      '1. Deutsch - Auflage, Vollfarbig'
	$comic_info->[17] = '1. Deutsch - Auflage, Vollfarbig';

	# [18] Bewertung            '0 makellos'
	$comic_info->[18] = '0 makellos';

	# [19] Status               'Vorhanden'
	$comic_info->[19] = 'Vorhanden';

	# [20] Darsteller

	# [21] Einbandart           'Hardcover'
	$comic_info->[21] = 'Hardcover';

	# [22] Format
	$comic_info->[22] = 'Großband';

	# [23] Genre
	$comic_info->[23] = 'Science Fiction';

	# [24] Bemerkung 2
	#$comic_info->[24] = '';

	# [25] Exemplare            '1'
	$comic_info->[25] = '1';

	# [26] Lagerort
	$comic_info->[26] = 'Kiste #024 (Alben)';

	# [27] Statushinweis
	# [28] Heft-Verweise
	# [29] Seiten               $details->{'Seiten'}
	$details->{'Seiten'} ? $comic_info->[29] = $details->{'Seiten'} : warn "No 'Seiten'";

	# [30] Inhalt/Geschichte    $details->{'Inhalt/Geschichte'}
	$details->{'Inhalt/Geschichte'} ? $comic_info->[30] = $details->{'Inhalt/Geschichte'} : warn "No 'Inhalt/Geschichte'";

	# [31] Rezensionen
	# [32] Inhaltsbewertung
	$comic_info->[32] = 'gut/sehr gut';

	# [33] Handelspreise

	# [34] Comic-Typ            'HEFT'
	$comic_info->[34] = 'HEFT';

	# [35] Autor(en) + Job      $details->{author} . '(Autor)', $details->{artist} . '(Zeichner)'

	# Format string in case both, author and artist are given...
	if ( $details->{author} && $details->{artist} ) {
		#...author and artist are the same...
		if ( $details->{author} eq $details->{artist} ) {
			$comic_info->[35] = $details->{author} . ' (Autor, Zeichner)';
		}
		# ...or author and artist are two different persons.
		else {
			$comic_info->[35] = $details->{author} . ' (Autor), ' . $details->{artist} . ' (Zeichner)';
		}
	}
	# Only author or only artist are mentioned.
	else {
		$comic_info->[35] = $details->{author} . ' (Autor)' if  $details->{author};
		$comic_info->[35] = $details->{artist} . ' (Zeichner)' if $details->{artist};
	}

	# [36] Enthalten in         $details->{'Heft-Titel'}
	#$details->{'Heft-Titel'} ? $comic_info->[36] = $details->{'Heft-Titel'} : warn "No 'Heft-Titel'";
	$comic_info->[36] = '10 Jahre Splitter';

	# [37] Link zum Cover
	my $filename = $details->{'Heft-Titel'};
	say "Filename: $filename";
	$filename =~ s/ +/_/g;
	$filename = sprintf ( '%s_%03d.jpg', $filename, $details->{'Serien-Nr.'} );
	$comic_info->[37] = $filename;

	return $comic_info;
}

# Gets the preview images of a comic book from the Splitter DOM structure and
# stores them on hard disk
#
sub get_images_Splitter {
	my $dom = shift;
	my $covername = shift;

	# Finds all nodes which fit to the following characteristics
	# tag:          meta
	# attribute:    content
	# attr. value:  popup_images (these images have the highest resolution)
	#
	#my @hits = $dom->findnodes ( '//meta[contains(@content,"popup_images")]' );
	my @hits = $dom->findnodes ( '//img[contains(@src,"popup_images")]' );

	my @local_files;    # array which returns the local filenames of the images

	my $cnt = 0;

	foreach ( @hits ) {
		# gets the attributes value of 'content' which is the URL to the image
		#my $hit = $_->getAttribute('content');
		my $hit = $_->getAttribute('src');
		$hit = 'https://www.splitter-verlag.de/' . $hit;
		say "URL: " . $hit;
		# TODO: make path handling more robust by using a perl module for that
		my @path = split '/', $hit;
		my ( undef, $ext ) = split '\.', $path[-1];
		my $file = sprintf ( '%03d.%s', $cnt, $ext );
		$cnt++;
		$file = './tmp/zip/' . $file;

		# download images and store them on hard drive
		my $lwp_return = LWP::Simple::getstore( $hit, $file );
		die "Error while downloading images" if $lwp_return != 200;

		push @local_files, $file;
	}

	# Copy the coverpage from the preview to a new file
	copy ( './tmp/zip/000.jpg', "./tmp/$covername" ) or die "Copy of cover failed: $!";

	# In case pictures found return the name of the downloaded files.
	# Otherwise return undef.
	@local_files ? return \@local_files : return undef;
}

1;