#!C:\strawberry\perl\bin\perl

#------------------------------------------------------------------------------
# Skript:			seriezeigen.pl
# Aufruf durch: 	sammlungsliste.pl
#
# Dieses Skript liest die durch den Comic Keeper erzeugten CSV Datei ein und
# speichert die Informationen in einem Array.
# Anschließend werden ausgewählte Informationen zu den vorhandenen Heften
# tabellarisch ausgegeben und zu Detailinformationen des Einzelheftes verlinkt.
# Die Information welche Serie anzuzeigen ist erhalt dieses Skript durch das
# aufrufende Programm
#------------------------------------------------------------------------------


# Aufbau der Comic Keeper CSV-Datei:
# [0]	Heft-Titel			[10]	Einkaufspreis		[20]	Darsteller			[30]	Inhalt/Geschichte
# [1]	Heft-Untertitel		[11]	Akt. Handelspreis	[21]	Einbandart			[31]	Rezensionen
# [2]	Sprache				[12]	Händler				[22]	Format				[32]	Inhaltsbewertung
# [3]	Serien-Nr.			[13]	Bemerkung 1			[23]	Genre				[33]	Handelspreise
# [4]	Serie von			[14]	URL					[24]	Bemerkung 2			[34]	Comic-Typ
# [5]	ISBN/Barcode-Nr.	[15]	Autor(en)			[25]	Exemplare			[35]	Autor(en) + Job
# [6]	Verlag				[16]	Zustand				[26]	Lagerort			[36]	Enthalten in
# [7]	Erstauflage			[17]	Eigenschaft(en)		[27]	Statushinweis		[37]	Link zum Cover
# [8]	Kaufdatum			[18]	Bewertung			[28]	Heft-Verweise
# [9]	Originalpreis		[19]	Status				[29]	Seiten

use strict;
use warnings;
use Text::CSV;
use HTML::Template::Compiled;
use Time::Piece;
use Data::Dumper;

my $version = '2014-12-31';

my $einstellungen = lese_konfig();

$| = 1;

my %FORM = ();

# Formulareingabe parsen
ParseForm();

my $verzeichnis = $FORM{'Verzeichnis'};

my $csvdatei = "../data/" . $verzeichnis ."/hefte.txt";	# CSV-Datei der Comics

my $hefte = lese_reihe();	# Datenbank der Reihe einlesen

my ($felder_anzeigen, $sondertitel) = hole_tabellenvorgaben($einstellungen);

my $anz_dbeintraege = $#$hefte;	# Anzahl der Datensätze im Array ermitteln

my $ueberschriften = hole_ueberschriften ( $hefte, $felder_anzeigen, $sondertitel );

my $hefte_gefiltert = spalten_filtern ( $hefte, $felder_anzeigen );

my $reihe = hole_reihe( $hefte );

my $anz_hefte = hole_anzahl_hefte( $hefte );

my $reihe_encoded = escape ( $reihe );

my ($reihe_vollstaendig, $meldung_vollstaendig) = ist_reihe_vollstaendig();

my $letzter_eintrag = ermittle_letzte_aenderung();

my ($ursprungswert, $uw_meldung) = ermittle_wert($hefte, 9);

my ($ek_wert, $ek_meldung) = ermittle_wert($hefte, 10);


# - - - -  Start HTML-Ausgabe  - - - -

print "Content-type: text/html\n\n";

my $template = HTML::Template::Compiled->new(
		filename				=> '../templates/serie_zeigen.tmpl',
		case_sensitive			=> 1,
		search_path_on_include	=> 1,
		loop_context_vars 		=> 1,
		use_query				=> 0,
		default_escape			=> 'HTML',
		default_escape			=> 0,
		);

$template->param(
		REIHE				=> $reihe,
		REIHEENCODED		=> $reihe_encoded,
		UEBERSCHRIFTEN		=> $ueberschriften,
		HEFTE				=> $hefte_gefiltert,
		VERSION				=> $version,
		VERZEICHNIS			=> $verzeichnis,
		ANZAHLDBEINTRAEGE	=> $anz_dbeintraege,
		ANZAHLHEFTE			=> $anz_hefte,
		VOLLSTAENDIG		=> $reihe_vollstaendig,
		MELDUNGVOLLSTG		=> $meldung_vollstaendig,
		LETZTEREINTRAG		=> $letzter_eintrag,
		URSPRUNGSSWERT		=> $ursprungswert,
		UWMELDUNG			=> $uw_meldung,
		EINKAUFSWERT		=> $ek_wert,
		EKMELDUNG			=> $ek_meldung,
		);

print $template->output();

#-------------------------------------------------------------------------------
# CSV-Datei mit den Datensaetzen der Reihe in ein Array einlesen und zurueck-
# geben.
#-------------------------------------------------------------------------------
sub lese_reihe {

	# Einlesen der CSV-Datei mit den Datensätzen der in der Sammlung enthaltenen Hefte
	open (SAMMLUNG, "<", $csvdatei) or die "Fehler beim Öffnen von $csvdatei: $?\n";
	my @hefte = <SAMMLUNG>;
	close(SAMMLUNG);
	
	return \@hefte;
}

#-------------------------------------------------------------------------------
# Holt die Vorgaben fuer die anzuzeigenden Spalten aus der Konfiguration
#-------------------------------------------------------------------------------
sub hole_tabellenvorgaben {
	
	my $config = shift;
	
	my $spalte;
	my @spalten;
	my $ueberschrift;
	my $ueberschriften = {};

	my $anzeige = $$config{'Anzeige-Reihe'};
	
	foreach ( @$anzeige ) {
		($spalte, $ueberschrift) = split ( /,/, $_ );
		push @spalten, $spalte;
		if ($ueberschrift) {
			$$ueberschriften{$spalte} = $ueberschrift;
		}
	}

	return (\@spalten, $ueberschriften);
}


#-------------------------------------------------------------------------------
# Vorgaben aus der Konfigurationsdatei in ein Hash of Arrays einlesen
#-------------------------------------------------------------------------------
sub lese_konfig
{
	my $vorgabendatei = "../conf/vorgaben_fuer_db-felder.txt";

	open (VOREINST, "<", $vorgabendatei) or die "Fehler beim Öffnen von $vorgabendatei: $?\n";
	my @vorgaben = <VOREINST>;
	close(VOREINST);
	
	my %hash;
	my $ueberschrift;
	foreach(@vorgaben)
	{
		my $key;
		my $line = $_;
		chomp($line);					# Newline entfernen
		
		next if ($line =~ m/^\s*$/);	# Leerzeilen entfernen
		next if($line =~ m/^\s*#/);		# Kommentarzeile ignorieren
		
		# Die durch [] eingeschlossenen Überschriften herausfiltern
		if ($line =~ m/^\s*\[(.*)\]\s*$/)
		{
			$ueberschrift = $1;
			next;
		}
		push (@{$hash{$ueberschrift}}, $line);	# wenn es sich nicht um eine Überschrift handelt, dann die Zeile	
	}											# an das Array der zuvor gefundene Überschrift (Hash) anhängen
	return \%hash;
}

#-------------------------------------------------------------------------------
# Ermitteln der Summe aller Ursprungspreise der Hefte der Reihe und Summierung
# dieser Werte.
#-------------------------------------------------------------------------------
sub ermittle_wert {
	my ($hefte, $feld) = @_;	# feld in dem der Preis des Heftes steht z.B.
								# Originalpreis [9], Einkaufspreis [10], Handelspreis [11]
	
	my $summe = 0;
	my $meldung = '';
	my @fehlt;			# Array fuer Hefte bei denen der Einkaufspreise fehlt
	my $zaehler = 0;
	
	foreach ( @$hefte ) {
		my @tmp_arr = split_string($_);
		if ( $tmp_arr[$feld] =~ /^[1-9]/ ){
			my ( $preis, $waehrung ) = split(/ /, $tmp_arr[$feld]);
			$preis =~ s/,/\./;
			if ( $waehrung =~ 'EUR' ) {
				$summe += $preis;
			}
			if ( $waehrung =~ 'DEM' ) {
				# 1 DEM = 0,51129 EUR
				$preis *= 0.51129;
				$summe += $preis;
			}
		}
		elsif ( $tmp_arr[3] =~ /^[1-9]/ || $tmp_arr[$feld] =~ /^[0]/ ) {
			# push @fehlt, $tmp_arr[3];
			push @fehlt, $zaehler;
			# $meldung = 'Ein- oder mehrere Preise liegen nicht vor.'
		}
		$zaehler++;
	}
	
	if ( @fehlt ) {
		$meldung = join ( ', ', @fehlt );
		$meldung = 'Preise für folgende Datensätze fehlen: ' . $meldung;
	}
	
	$summe = sprintf "%.2f", $summe;
	$summe .= ' Euro';
	$summe =~ s/\./,/;
	return ($summe, $meldung);
}

#-------------------------------------------------------------------------------
# ermittelt Datum und Uhrzeit des letzten schreibenden Zugriffs auf die Datei
# hefte.txt der vorliegenden Reihe
#-------------------------------------------------------------------------------
sub ermittle_letzte_aenderung {

	my @datei_infos = stat($csvdatei);
	my $t = localtime($datei_infos[9]);
	my $datum = $t->dmy(".");
	$datum = $datum . ' ' . $t->hms;
	return $datum;
}

#-------------------------------------------------------------------------------
# Prueft ob die vorliegende Reihe vollstaendig ist.
#-------------------------------------------------------------------------------
sub ist_reihe_vollstaendig {
	my $hefte = shift;
	my $max_reihe = 0;	# Anzahl der Titel aus denen die Reihe besteht
	my @vorhanden;		# Array mit den vorhandenen Titeln der Reihe
	my @fehlt;			# Array mit den fehlenden Titeln der Reihe
	my $meldung = '';		#
	my $vollstaendig = 'k.A.';	# Meldung zur Vollstaendigkeit der Reihen

	foreach ( @$hefte ) {
		my @tmp_arr = split_string($_);
		
		# Prueft Anzahl der Exemplare [25] sowie den Status [19] 'Vorhanden'..
		if ( $tmp_arr[25] =~ /^[1-9]/ && $tmp_arr[19] =~ /Vorhanden/) {
			# ..und traegt das Heft in ein Array der vorhandenen Hefte ein
			$vorhanden[$tmp_arr[3]] = 1;
		}
		
		if ( $tmp_arr[4] =~ /^[1-9]/ && $tmp_arr[4] > $max_reihe) {
			$max_reihe = $tmp_arr[4];
		}
	}
	
	# wenn eine Zahl fuer die zu erwartenden Hefte ermittelt werden konnte..
	if ($max_reihe > 0 ) {
		# ..dann werden alle Nummern durchlaufen..
		for my $heft_nr ( 1..$max_reihe ) {
			# ..und falls eines nicht vorhanden ist..
			if ( !$vorhanden[$heft_nr] ) {
				# ..dieses in das Array der fehlenden Hefte geschrieben
				push @fehlt, $heft_nr;
			}
		}
	}
	else {
		# Falls keine Zahl für den Reihenumfang ermittelt werden konnte, dann wird
		# die folgende Meldung ausgegeben
		$meldung = 'Die Angabe der max. Reihen-Titel scheint irgendwo falsch zu sein.'
	}

	# falls ein Array mit fehlenden Heften existiert, dann..
	if ( @fehlt ) {
		# ..werden dessen Eintraege in einen String geschrieben..
		$vollstaendig = join ( ', ', @fehlt);
		$vollstaendig = 'es fehlt: ' . $vollstaendig;
	}
	elsif ( $max_reihe > 0 ) {
		# ..andernfalls sollte davon ausgegangen werden koennen, dass die Reihen
		# vollstaendig ist.
		$vollstaendig = 'ja';
	}
	
	return ($vollstaendig, $meldung);
}

#-------------------------------------------------------------------------------
# Unterteilt die zeilenweise eingelesene Textdatei in einzelne Spalten fuer
# die Darstellung in der HTML-Tabelle und liefert eine Referenz auf einzeln
# Array of Arrays dieser Daten zurueck
#-------------------------------------------------------------------------------
sub spalten_erzeugen {
	my $datensaetze = shift;
	my $spalten = [];
	my $count = 1;
	foreach ( @$datensaetze ) {
		my @tmp_arr = ($count, split_string ( $_ ));
		push @$spalten, \@tmp_arr;
		$count++;
	}
	
	return $spalten;
}

#-------------------------------------------------------------------------------
# Holt die gefilterten Ueberschriften aus der Textdatei und ueberschreibt
# Default-Titel mit den Wunsch-Titeln aus der Konfigurationsdatei
#-------------------------------------------------------------------------------
sub hole_ueberschriften {
	my ($hefte, $filter, $wunschtitel) = @_;

	my @ueberschriften_gefiltert;
	
	# Überschriften, die sich in der ersten Zeile des Array befinden auslesen
	my @ueberschriften = split_string($$hefte[0]);

	# jede Vorgabespalte durchlaufen..
	foreach (@$filter) {
		#..wenn es fuer diese Spalte einen Wunschtitel gibt,..
		if ($$wunschtitel{$_}) {
			#..dann diesen in das Array der Ueberschriften schreiben..
			push @ueberschriften_gefiltert, $$wunschtitel{$_};
		}
		else {
			#..andernfalls den Default-Titel aus der Datei hefte.txt uebernehmen
			push @ueberschriften_gefiltert, $ueberschriften[$_];
		}
	}
	
	return \@ueberschriften_gefiltert;
}

#-------------------------------------------------------------------------------
# Name der Reihe aus Feld [36] 'enthalten in' ermitteln
# TODO die Reihe sollte in der XML-Version einen eigenen Eintrag erhalten,
# so dass direkt auf den Namen zugegriffen werden kann
#-------------------------------------------------------------------------------
sub hole_reihe {
	my $hefte = shift;
	my $tmp_reihe = '';

	foreach ( @$hefte ) {
		my @tmp_arr = split_string($_);
		if ( $tmp_arr[36] ) { $tmp_reihe = $tmp_arr[36]; }
	}
	return $tmp_reihe;
}


#-------------------------------------------------------------------------------
# liefert ein Array of Array der Tabellenspalten die als Spalten-Nummer 
# an die Sub uebergeben werden
# Alle anderen Spalten werden ausgefiltert d.h. verworfen
#-------------------------------------------------------------------------------
sub spalten_filtern {

	my ($hefte, $filter) = @_;
	my @hefte_gefiltert;

	 foreach ( 1..($#$hefte) ) {
		my @tmp_arr = split_string($$hefte[$_]);
		my @satz_gefiltert;
		foreach my $spalte ( @$filter ) {
			if ( $spalte == 37 ) {
				my $text = '<A HREF="../data/' . $verzeichnis . '/cover/' . $tmp_arr[$spalte] . '"><IMG ALT="' . $tmp_arr[$spalte] . '" SRC="../data/' . $verzeichnis . '/cover/' . $tmp_arr[$spalte] . '" HEIGHT="100"></A>';
				push @satz_gefiltert, $text;
			}
			else {
				push @satz_gefiltert, $tmp_arr[$spalte];
			}
		}
		push @hefte_gefiltert, \@satz_gefiltert;
	}
	return \@hefte_gefiltert;
}


#-------------------------------------------------------------------------------
# Ermittelt die Anzahl vorhandener Hefte und liefert diese zurueck.
#-------------------------------------------------------------------------------
sub hole_anzahl_hefte {
	my $hefte = shift;
	my $anzahl_hefte = 0;
	foreach ( @$hefte ) {
		my @tmp_arr = split_string($_);
		if ( $tmp_arr[25] =~ /^[1-9]/ && $tmp_arr[19] =~ /Vorhanden/) {
			$anzahl_hefte += $tmp_arr[25];
		}
	}
	return $anzahl_hefte;
}

#-------------------------------------------------------------------------------
# Teilt einen Komma-seperierten String in seine Bestandteile auf.
# Auf diese Weise erhaelt man die Datenfelder des Comics aus der 
# Datei hefte.txt zur weiteren Bearbeitung in einem Array zurueck
#-------------------------------------------------------------------------------
sub split_string
{
	# Ein neues CSV-Objekt erzeugen
	my $csv = Text::CSV->new(
		{ binary 			=> 1,	# alle Codes erlaubt
		  eol    			=> $\,	# Newline betriebssystemspezifisch setzen
		  allow_whitespace 	=> 1,	# Leerzeichen zwischen den Feldern erlauben
		  quote_char		=> '"',	# Anführungszeichen definieren
		  sep_char			=> ',',	# Feldtrenner definieren
		});
	
	my $line = shift;
	my @new;
	if ($csv->parse($line)){
		@new = $csv->fields();
		return (@new);
	}
	else{
		# sonst die aktuelle Zeile ausgeben
		print "**** ", $csv->error_input, "\n",
		# und die Fehlerursache (Zahl am Schluss = Fehlerposition)
		      "**** ", $csv->error_diag, "\n";
		return (undef);
	}
}

sub ParseForm
{
	my ($buffer, @pairs, $pair, $name, $value);
	# Text einlesen
	if ($ENV{'REQUEST_METHOD'} eq "POST")
	{
		read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
	}
	else
	{
		$buffer = $ENV{'QUERY_STRING'};
	}
	@pairs = split(/&/, $buffer);
	foreach $pair (@pairs)
	{
		# Name-Wert-Paare trennen
		($name, $value) = split(/=/, $pair);
		# Leerzeichen wieder einsetzen
		$value =~ tr/+/ /;
		# URL-codierte Zeichen (%xx) ersetzen
		$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		# im Hash speichern
		if (defined $FORM{$name})	# vermutlich checkbox
		{
			$FORM{$name} = $FORM{$name} . ", " . $value;
		}
		else
		{
			$FORM{$name} = $value;
		}
	}
}

#-------------------------------------------------------------------------------
# Sub um einen String für die Übertagung an eine Webseite so aufzubereiten,
# dass keine Leerzeichen etc. enhalten sind (URL-encode data)
#-------------------------------------------------------------------------------
sub escape {
    shift() if ref($_[0]);
    my $toencode = shift;
    return undef unless defined($toencode);
    $toencode=~s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
    return $toencode;
}

exit;