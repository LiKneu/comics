#!C:\strawberry\perl\bin\perl

#-------------------------------------------------------------------------------------------------------------
# Dieses Skript kopiert einen Datensatz d.h. ein Heft aus der CSV-Datei hefte.txt und hängt diesen als
# letzte Zeile die Datei an.
# Beim Kopieren besteht die Möglichkeit gezielt Felder aus dem Datensatz nicht zu kopieren.
# Welche Felder kopiert werden und welche nicht wird über die Konfigurationsdatei vorgaben_fuer_db-felder.txt
# bestimmt.
#-------------------------------------------------------------------------------------------------------------

# Aufbau der Comic Keeper CSV-Datei:
# [0]	Heft-Titel
# [1]	Heft-Untertitel
# [2]	Sprache
# [3]	Serien-Nr.
# [4]	Serie von
# [5]	ISBN/Barcode-Nr.
# [6]	Verlag
# [7]	Erstauflage
# [8]	Kaufdatum
# [9]	Originalpreis
# [10]	Einkaufspreis
# [11]	Akt. Handelspreis
# [12]	Händler
# [13]	Bemerkung 1
# [14]	URL
# [15]	Autor(en)
# [16]	Zustand
# [17]	Eigenschaft(en)
# [18]	Bewertung
# [19]	Status
# [20]	Darsteller
# [21]	Einbandart
# [22]	Format
# [23]	Genre
# [24]	Bemerkung 2
# [25]	Exemplare
# [26]	Lagerort
# [27]	Statushinweis
# [28]	Heft-Verweise
# [29]	Seiten
# [30]	Inhalt/Geschichte
# [31]	Rezensionen
# [32]	Inhaltsbewertung
# [33]	Handelspreise
# [34]	Comic-Typ
# [35]	Autor(en) + Job
# [36]	Enthalten in
# [37]	Link zum Cover

use strict;
use warnings;
use Text::CSV;
use File::Copy;
use CGI::Carp qw(fatalsToBrowser);	# Umleitung von Fehlermeldungen in den Browser

$| = 1;

my %FORM = ();

# Formulareingabe parsen
ParseForm();

my $verzeichnis = $FORM{'Verzeichnis'};	# Name der Sammlung bzw. der Name des Verzeichnisses in dem die Sammlung abgelegt ist

my $datensatz = $FORM{'Datensatz'};		# Nr. des Datensatzes der kopiert werden soll

InsertHeader("Heft kopieren $verzeichnis");		# Beginn des HTML-Dokuments
print "<H2>Heft kopieren</H2>";
print "<h1>Verzeichnis: <I>$verzeichnis</I>, Datensatz: <I>$datensatz</I></h1>\n";

my $csvdatei = '../data/' . $verzeichnis . '/hefte.txt';	# CSV-Datei der Comics

my %felder = LeseConfig();	# Konfigurationsdaten einlesen d.h. u.a. auswerten welche Felder aus dem Datensatz kopiert werden sollen
my @kopieren = @{$felder{'Kopiervorgaben'}};	# Kopiervorgaben aus dem Hash an das Array übertragen

# Ein neues CSV-Objekt erzeugen
my $csv = Text::CSV->new(
	{ binary 			=> 1,	# alle Codes erlaubt
	  eol    			=> $\,	# Newline betriebssystemspezifisch setzen
	  allow_whitespace 	=> 1,	# Leerzeichen zwischen den Feldern erlauben
	  quote_char		=> '"',	# Anführungszeichen definieren
	  sep_char			=> ',',	# Feldtrenner definieren
	});

# Einlesen der CSV-Datei mit den Datensätzen der in der Sammlung enthaltenen Hefte
open (SAMMLUNG, "<", $csvdatei) or die "Fehler beim Öffnen von $csvdatei: $?\n";
my @hefte = <SAMMLUNG>;
close(SAMMLUNG);

my @felder = split_string($hefte[$datensatz]);	# ausgewählten Datensatz in sein Bestandteile zerlegen um
												# einzelne gezielt vom Kopieren ausblenden zu können
												
my $i;
for $i (0 .. $#felder)
{
	if($kopieren[$i] eq 0)	# Felder die mit (0) markiert sind werden nicht kopiert ...
	{
		$felder[$i] = "";	# d.h. der Wert wird auf "leeren String gesetzt"
	}
}

# Zeile wieder mit den ggf. gelöschten Werten durch Komma getrennt zusammen setzen
my $zeile = "";
my $j;
for $j (0..$#felder)
{
	if ($j == 0)	# beim ersten Feld darf kein vorangestelltes Komma ausgegeben werden
	{
		$zeile = $zeile . "\"" . $felder[$j] . "\"";
	}
	else			# bei allen nachfolgenden Feldern ist ein Komma gewünscht
	{
		$zeile = $zeile . ",\"" . $felder[$j] . "\"";
	}	
}

# alte CSV-Datei sichern und für die Benennung des Backups die Zeit ermitteln
my ($sec, $min, $std, $tt, $mm, $jjjj, $dow, $doy, $sumtime) = localtime(time);
$mm++;
$doy++;
$jjjj += 1900;

# für alle Zeitangaben, die kleiner als 10 sind eine 0 vor dem Wert einfügen
# ("Der Perl programmierer" Seite 79 unten)
$sec = $sec < 10 ? "0".$sec : $sec;
$min = $min < 10 ? "0".$min : $min;
$std = $std < 10 ? "0".$std : $std;
$tt = $tt < 10 ? "0".$tt : $tt;
$mm = $mm < 10 ? "0".$mm : $mm;

# zur Datensicherung wird die Kopie der original CSV-Datei mit einem vorangestellten Zeitstempel versehen
my $kopie_datei = "../data/$verzeichnis/$jjjj-$mm-$tt\_$std$min$sec\_hefte.txt";
copy ($csvdatei, $kopie_datei) || die "Kopieren von $csvdatei ging schief: $!\n";


# Die zu kopierende und um einige Werte bereinigte Zeile an die existierende Sammlungsdatei anhängen.
open(SAMMLUNG, ">>", $csvdatei) or die "Fehler beim Öffnen von $csvdatei: $?\n";
print SAMMLUNG $zeile . "\n";
close(SAMMLUNG);

# Log-Datei schreiben
my $log_string = "$jjjj-$mm-$tt\_$std$min$sec; HEFT KOPIERT; Verzeichnis: $verzeichnis; Datensatz: $datensatz";
SchreibeLog($log_string);

print "<P>Datensatz: $datensatz aus Verzeichnis: $verzeichnis kopiert.</P>\n";

InsertTrailer();

sub split_string
{
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

# Vorgabewerte für Felder aus Datei einlesen
sub LeseConfig
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
	return %hash;
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

sub InsertHeader
{
	# HTTP-Header und HTML-Vorspann ausgeben
	my ($htmltitle) = @_;
	print "Content-type: text/html\n\n";
	print "<HTML>\n<HEAD>\n";
	print "<TITLE> $htmltitle </TITLE>\n</HEAD>\n";
	print "<BODY>";
}

sub InsertTrailer
{
	# HTML-Nachspann ausgeben
	print "</FORM>\n";
	print "</BODY>\n</HTML>\n";
}

sub SchreibeLog
{
	my ($log_meldung) = @_;
	my $logdatei = "../logs/edit_log.txt";
	open (LOGDATEI, ">>", $logdatei) or die "Fehler beim Schreiben von $logdatei: $?\n";
	print LOGDATEI "$log_meldung\n";
	close (LOGDATEI);
}

exit;