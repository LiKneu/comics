package lib::Basics;

#-------------------------------------------------------------------------------
# package: Basics
#
# Function:
#   
#-------------------------------------------------------------------------------

use strict;
use warnings;
use 5.18.0;

use Text::CSV;
use Data::Dumper;

# This array gives the field names as well as the position in the CSV file
my @FIELD_NAMES = (
	'Heft-Titel',       # [0]
	'Heft-Untertitel',  # [1]
	'Sprache',          # [2]
	'Serien-Nr.',       # [3]
	'Serie von',        # [4]
	'ISBN/Barcode-Nr.', # [5]
	'Verlag',           # [6]
	'Erstauflage',      # [7]
	'Kaufdatum',        # [8]
	'Originalpreis',    # [9]
	'Einkaufspreis',    # [10]
	'Akt. Handelspreis',# [11]
	'Händler',          # [12]
	'Bemerkung 1',      # [13]
	'URL',              # [14]
	'Autor(en)',        # [15]
	'Zustand',          # [16]
	'Eigenschaft(en)',  # [17]
	'Bewertung',        # [18]
	'Status',           # [19]
	'Darsteller',       # [20]
	'Einbandart',       # [21]
	'Format',           # [22]
	'Genre',            # [23]
	'Bemerkung 2',      # [24]
	'Exemplare',        # [25]
	'Lagerort',         # [26]
	'Statushinweis',    # [27]
	'Heft-Verweise',    # [28]
	'Seiten',           # [29]
	'Inhalt/Geschichte',# [30]
	'Rezensionen',      # [31]
	'Inhaltsbewertung', # [32]
	'Handelspreise',    # [33]
	'Comic-Typ',        # [34]
	'Autor(en) + Job',  # [35]
	'Enthalten in',     # [36]
	'Link zum Cover',   # [37]
);

sub write_CSV {
	my $comic_info = shift; # hash with comic book info record
	my $file = shift;

	my $data = [];  # array to be printed into the CSV file
	# TODO: script getSplitter presently delivers AoA and not an AoH so we
	# get an error 'Not a HASH reference at lib/Basics.pm line 66.' during
	# execution.
	foreach my $key ( @FIELD_NAMES ) {
		push @$data, $comic_info->{$key};
	}

	say Dumper $data;

	# Create a new CSV-object
	my $csv = Text::CSV->new(
		{
			binary 			    => 1,	# alle Codes erlaubt
			eol    			    => $\,	# Newline betriebssystemspezifisch setzen
			allow_whitespace 	=> 1,	# Leerzeichen zwischen den Feldern erlauben
			quote_char		    => '"',	# Anführungszeichen definieren
			sep_char			=> ',',	# Feldtrenner definieren
			always_quote        => 1,
		}
	);

	open my $fh, '>', $file;
#	$csv->column_names ( \@FIELD_NAMES );
	my $status = $csv->print ($fh, $data);
	close $fh;
}

sub set_default_comic_data {

	my $comic_info = {};        # Hash to hold all default values of the comic book

	# [0] Heft-Titel
	#$comic_info->[0] = '';
	$comic_info->{'Heft-Titel'} = '';

	# [1] Heft-Untertitel
	#$comic_info->[1] = '';
	$comic_info->{'Heft-Untertitel'} = '';

	# [2] Sprache               'deutsch'
#	$comic_info->[2] = 'deutsch';
	$comic_info->{'Sprache'} = 'deutsch';

	# [3] Serien-Nr.
	#$comic_info->[3] = '';
	$comic_info->{'Serien-Nr.'} = '';

	# [4] Serie von
	#$comic_info->[4] = '';
	$comic_info->{'Serie von'} = '';

	# [5] ISBN/Barcode-Nr.
	#$comic_info->[5] = '';
	$comic_info->{'ISBN/Barcode-Nr.'} = '';

	# [6] Verlag
	#$comic_info->[6] = '';
	$comic_info->{'Verlag'} = '';

	# [7] Erstauflage
	#$comic_info->[7] = '';
	$comic_info->{'Erstauflage'} = '';

	# [8] Kaufdatum
	#$comic_info->[8] = '';
	$comic_info->{'Kaufdatum'} = '';

	# [9] Originalpreis         '<Preis> <Währung>'
	#$comic_info->[9] = ' EUR';
	$comic_info->{'Originalpreis'} = '';

	# [10] Einkaufspreis        '<Preis> <Währung>'
	#$comic_info->[10] = ' EUR';
	$comic_info->{'Einkaufspreis'} = '';

	# [11] Akt. Handelspreis
	#$comic_info->[11] = '';
	$comic_info->{'Akt. Handelspreis'} = '';

	# [12] Händler              'Buchhandlung VielSeitig Rohe und Pütz oHG'
#	$comic_info->[12] = 'Buchhandlung VielSeitig Rohe und Pütz oHG';
	$comic_info->{'Händler'} = 'Buchhandlung VielSeitig Rohe und Pütz oHG';

	# [13] Bemerkung 1
	#$comic_info->[13] = '';
	$comic_info->{'Bemerkung 1'} = '';

	# [14] URL
	#$comic_info->[14] = '';
	$comic_info->{'URL'} = '';

	# [15] Autor(en)            '<Autor 1>, <Autor 2>, <Autor 3>'
	#$comic_info->[15] = '';
	$comic_info->{'Autor(en)'} = '';

	# [16] Zustand              'Keine Mängel, makellos'
#	$comic_info->[16] = 'Keine Mängel, makellos';
	$comic_info->{'Zustand'} = 'Keine Mängel, makellos';

	# [17] Eigenschaft(en)      '1. Deutsch - Auflage, Vollfarbig'
#	$comic_info->[17] = '1. Deutsch - Auflage, Vollfarbig';
	$comic_info->{'Eigenschaft(en)'} = '1. Deutsch - Auflage, Vollfarbig';

	# [18] Bewertung            '0 makellos'
#	$comic_info->[18] = '0 makellos';
	$comic_info->{'Bewertung'} = '0 makellos';

	# [19] Status               'Vorhanden'
#	$comic_info->[19] = 'Vorhanden';
	$comic_info->{'Status'} = 'Vorhanden';

	# [20] Darsteller
	#$comic_info->[20] = '';
	$comic_info->{'Darsteller'} = '';

	# [21] Einbandart           'Hardcover'
	#$comic_info->[21] = '';
	$comic_info->{'Einbandart'} = '';

	# [22] Format
	#$comic_info->[22] = '';
	$comic_info->{'Format'} = 'Album';

	# [23] Genre
	#$comic_info->[23] = '';
	$comic_info->{'Genre'} = 'Abenteuer';

	# [24] Bemerkung 2
	#$comic_info->[24] = '';
	$comic_info->{'Bemerkung 2'} = '';

	# [25] Exemplare            '1'
#	$comic_info->[25] = '1';
	$comic_info->{'Exemplare'} = '1';

	# [26] Lagerort
	#$comic_info->[26] = '';
	$comic_info->{'Lagerort'} = 'Kiste #024 (Alben)';

	# [27] Statushinweis
	#$comic_info->[27] = '';
	$comic_info->{'Statushinweis'} = '';

	# [28] Heft-Verweise
	#$comic_info->[28] = '';
	$comic_info->{'Heft-Verweise'} = '';

	# [29] Seiten
	#$comic_info->[29] = '';
	$comic_info->{'Seiten'} = '';

	# [30] Inhalt/Geschichte
	#$comic_info->[30] = '';
	$comic_info->{'Inhalt/Geschichte'} = '';

	# [31] Rezensionen
	#$comic_info->[31] = '';
	$comic_info->{'Rezensionen'} = '';

	# [32] Inhaltsbewertung
	#$comic_info->[32] = '';
	$comic_info->{'Inhaltsbewertung'} = 'mittelmäßig';

	# [33] Handelspreise
	#$comic_info->[33] = '';
	$comic_info->{'Handelspreise'} = '';

	# [34] Comic-Typ            'HEFT'
#	$comic_info->[34] = 'HEFT';
	$comic_info->{'Comic-Typ'} = 'HEFT';

	# [35] Autor(en) + Job      '<Autor 1>, <Autor 2> (Autor), <Zeichner 1>, <Zeichner 2> (Zeichner)'
	#$comic_info->[35] = '';
	$comic_info->{'Autor(en) + Job'} = '';

	# [36] Enthalten in
	#$comic_info->[36] = '';
	$comic_info->{'Enthalten in'} = 'Die Adler Roms';

	# [37] Link zum Cover
	#$comic_info->[37] = '';
	$comic_info->{'Link zum Cover'} = '';

	return $comic_info;
}


#sub set_default_comic_data {
#
#	my $comic_info = [];        # Array to be printed into a cvs file
#	@$comic_info = ("") x 37;   # Initiate array with all possible but empty fields
#
#	# [0] Heft-Titel
#	#$comic_info->[0] = '';
#
#	# [1] Heft-Untertitel
#	#$comic_info->[1] = '';
#
#	# [2] Sprache               'deutsch'
#	$comic_info->[2] = 'deutsch';
#
#	# [3] Serien-Nr.
#	#$comic_info->[3] = '';
#
#	# [4] Serie von
#	#$comic_info->[4] = '';
#
#	# [5] ISBN/Barcode-Nr.
#	#$comic_info->[5] = '';
#
#	# [6] Verlag
#	#$comic_info->[6] = '';
#
#	# [7] Erstauflage
#	#$comic_info->[7] = '';
#
#	# [8] Kaufdatum
#	#$comic_info->[8] = '';
#
#	# [9] Originalpreis         '<Preis> <Währung>'
#	#$comic_info->[9] = ' EUR';
#
#	# [10] Einkaufspreis        '<Preis> <Währung>'
#	#$comic_info->[10] = ' EUR';
#
#	# [11] Akt. Handelspreis
#	#$comic_info->[11] = '';
#
#	# [12] Händler              'Buchhandlung VielSeitig Rohe und Pütz oHG'
#	$comic_info->[12] = 'Buchhandlung VielSeitig Rohe und Pütz oHG';
#
#	# [13] Bemerkung 1
#	#$comic_info->[13] = '';
#
#	# [14] URL
#	#$comic_info->[14] = '';
#
#	# [15] Autor(en)            '<Autor 1>, <Autor 2>, <Autor 3>'
#	#$comic_info->[15] = '';
#
#	# [16] Zustand              'Keine Mängel, makellos'
#	$comic_info->[16] = 'Keine Mängel, makellos';
#
#	# [17] Eigenschaft(en)      '1. Deutsch - Auflage, Vollfarbig'
#	$comic_info->[17] = '1. Deutsch - Auflage, Vollfarbig';
#
#	# [18] Bewertung            '0 makellos'
#	$comic_info->[18] = '0 makellos';
#
#	# [19] Status               'Vorhanden'
#	$comic_info->[19] = 'Vorhanden';
#
#	# [20] Darsteller
#	#$comic_info->[20] = '';
#
#	# [21] Einbandart           'Hardcover'
#	#$comic_info->[21] = '';
#
#	# [22] Format
#	#$comic_info->[22] = '';
#
#	# [23] Genre
#	#$comic_info->[23] = '';
#
#	# [24] Bemerkung 2
#	#$comic_info->[24] = '';
#
#	# [25] Exemplare            '1'
#	$comic_info->[25] = '1';
#
#	# [26] Lagerort
#	#$comic_info->[26] = '';
#
#	# [27] Statushinweis
#	#$comic_info->[27] = '';
#
#	# [28] Heft-Verweise
#	#$comic_info->[28] = '';
#
#	# [29] Seiten
#	#$comic_info->[29] = '';
#
#	# [30] Inhalt/Geschichte
#	#$comic_info->[30] = '';
#
#	# [31] Rezensionen
#	#$comic_info->[31] = '';
#
#	# [32] Inhaltsbewertung
#	#$comic_info->[32] = '';
#
#	# [33] Handelspreise
#	#$comic_info->[33] = '';
#
#	# [34] Comic-Typ            'HEFT'
#	$comic_info->[34] = 'HEFT';
#
#	# [35] Autor(en) + Job      '<Autor 1>, <Autor 2> (Autor), <Zeichner 1>, <Zeichner 2> (Zeichner)'
#	#$comic_info->[35] = '';
#
#	# [36] Enthalten in
#	#$comic_info->[36] = '';
#
#	# [37] Link zum Cover
#	#$comic_info->[37] = '';
#
#
#	return $comic_info;
#}

sub cover_filename {
	my $comic_info = shift;

	my $filename = $comic_info->{'Heft-Titel'};

	$filename =~ s/ +/_/g;
	$filename = sprintf ( '%s_%03d.jpg', $filename, $comic_info->{'Serien-Nr.'} );

	return $filename;
}

1;