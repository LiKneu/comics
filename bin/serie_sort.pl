#!C:\strawberry\perl\bin\perl

#------------------------------------------------------------------------------
# Skript:			serie_sort.pl
# Aufruf durch: 	seriezeigen.pl
#
# Dieses Skript liest die durch den Comic Keeper erzeugten CSV Datei ein und
# speichert die einzelnen Zeilen in einem Array.
# Anschließend wird dieses Array nach der Heft-Nr. sortiert.
# Die Ursprungsdatei wird mit Datumsangaben versehen als Backup gespeichert.
# Die sortierten Informationen überschreiben dann die Ursprungsdatei.
#------------------------------------------------------------------------------

use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser);	# Umleitung von Fehlermeldungen in den Browser
use File::Copy;

$| = 1;

my %FORM = ();

# Formulareingabe parsen
ParseForm();

my $verzeichnis = $FORM{'Verzeichnis'};
my $csvdatei = "..\\data\\" . $verzeichnis ."\\hefte.txt";	# CSV-Datei der Comics

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
my $kopie_datei = "..\\data\\" . $verzeichnis ."\\$jjjj-$mm-$tt\_$std$min$sec\_hefte.txt";

InsertHeader("Sortierte Serie");	# Start des HTML-Dokuments
print "<h1>Sortierte Serie</h1>\n";
print "<P>Quelldatei: $csvdatei<BR />\n";
print "Datensicherung: $kopie_datei</P>\n";

# Die Originaldatei vor der Manipulation sichern
if (-e $csvdatei)
{
	# die csv-Datei existiert und soll somit zur Sicherung kopiert werden
	copy ($csvdatei, $kopie_datei) || die "Kopieren von $csvdatei ging schief: $!";
}
else
{
	print "$csvdatei nicht gefunden.\n";
}

# Die Datei mit der Serie d.h. den einzelnen Heften einlesen
open (ORIGINAL, "<", $csvdatei) or die "Fehler beim Öffnen von $csvdatei: $?\n";
my @original_zeilen = <ORIGINAL>;
close(ORIGINAL);

my @ohne_ueberschr = @original_zeilen;

splice(@ohne_ueberschr, 0, 1);	# Die Überschrift für die Sortierung aus dem Array entfernen

# das Array sortieren ("Der Perl Programmierer" Seite 252 oben)
my @result = map {$_->[0]} sort {$a->[1] <=> $b->[1]} map {[$_, (/\,\"(\d{1,})\"/)[0]]} @ohne_ueberschr;

unshift (@result, $original_zeilen[0]);	# Überschrift vor die anderen Elemente des Arrays einfügen

# sortierte Daten in die neue Datei schreiben
open (NEU, ">", $csvdatei) or die "Fehler beim Öffnen von $csvdatei: $?\n";
foreach (@result)
	{
		print NEU $_;
	}
close(NEU);

my $log_string = "$jjjj-$mm-$tt\_$std$min$sec; SERIE SORTIERT; Verzeichnis: $verzeichnis";
SchreibeLog($log_string);

foreach (@result)
	{
		print $_ . "<BR />\n";
	}

InsertTrailer();					# Ende des HTML-Dokuments

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
	print "<FORM METHOD=\"GET\">";
	print "</FORM>";
}

sub InsertTrailer
{
	# HTML-Nachspann ausgeben
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