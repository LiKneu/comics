#!/usr/bin/perl

#-------------------------------------------------------------------------------
# Script: getSplitter
#
# Function:
#   Just a script to test the modules which are stored in /lib
#-------------------------------------------------------------------------------

use strict;
use warnings;
use 5.20.2;

use Data::Dumper;
use LWP::Simple;
use utf8;

use lib::Basics;
use lib::FromWeb;
use lib::FromSplitter;

my $VERSION = '27-12-2017';


my $file = './html/Splitter_test.html'; # File to which the URL content is stored
my $url;                                # Var to hold the URL of the comic book

# Titles with several issues (series)
#$url = 'http://www.splitter-verlag.de/horacia-d-alba-bd-3-memoiren-einer-duellantin.html';
#$url = 'http://www.splitter-verlag.de/storm-bd-1-die-tiefe-welt.html';

# Titles with only one issue (no series)
#$url = 'http://www.splitter-verlag.de/in-bed.html';
#$url = 'http://www.splitter-verlag.de/charly-9.html';
#$url = 'https://www.splitter-verlag.de/horlemonde-splitter-double.html';
#$url = 'https://www.splitter-verlag.de/der-morder-den-sie-verdient-limitierte-sonderedition.html';
$url = 'https://www.splitter-verlag.de/moby-dick.html';

my $dom = lib::FromWeb::get_dom( $url );

my $details = lib::FromSplitter::get_details_Splitter( $dom );
#say Dumper $details;

my $arr = lib::FromSplitter::hash_to_array( $details );
say "\nAusgelesener Datensatz";
say Dumper $arr;

my $localfiles = lib::FromSplitter::get_images_Splitter( $dom, $arr->[37] );
say "\nDateinamen der heruntergeladenen Bilder";
say join "\n", @$localfiles;

lib::FromWeb::pack_excerpt( $localfiles, $arr->[0], $arr->[3] );

# TODO: script getSplitter presently delivers AoA to function 'write_CSV' and
# not an AoH so we get an error 'Not a HASH reference at lib/Basics.pm line 66.'
# during execution.
lib::Basics::write_CSV( $arr, './tmp/heft.txt' );

say "Finished.";

# [0] Heft-Titel            $details->{series}
# [1] Heft-Untertitel       $details->{title}
# [2] Sprache               'deutsch'
# [3] Serien-Nr.            $details->{number}
# [4] Serie von
# [5] ISBN/Barcode-Nr.      $details->{isbn}
# [6] Verlag                'Splitter-Verlag GmbH'
# [7] Erstauflage
# [8] Kaufdatum
# [9] Originalpreis         $details->{price} . 'EUR'
# [10] Einkaufspreis        $details->{price} . 'EUR'
# [11] Akt. Handelspreis
# [12] Händler              'Buchhandlung VielSeitig Rohe und Pütz oHG'
# [13] Bemerkung 1
# [14] URL
# [15] Autor(en)            $details->{author}, $details->{artist}
# [16] Zustand              'Keine Mängel, makellos'
# [17] Eigenschaft(en)      '1. Deutsch - Auflage, Vollfarbig'
# [18] Bewertung            '0 makellos'
# [19] Status               'Vorhanden'
# [20] Darsteller
# [21] Einbandart           'Hardcover'
# [22] Format
# [23] Genre
# [24] Bemerkung 2
# [25] Exemplare            '1'
# [26] Lagerort
# [27] Statushinweis
# [28] Heft-Verweise
# [29] Seiten               $details->{pages}
# [30] Inhalt/Geschichte    $details->{content}
# [31] Rezensionen
# [32] Inhaltsbewertung
# [33] Handelspreise
# [34] Comic-Typ            'HEFT'
# [35] Autor(en) + Job      $details->{author} . '(Autor)', $details->{artist} . '(Zeichner)'
# [36] Enthalten in         $details->{series}
# [37] Link zum Cover

exit;