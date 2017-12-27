#!C:\strawberry\perl\bin\perl

use strict;
use warnings;
use Text::CSV;
use CGI::Carp qw(fatalsToBrowser);	# Umleitung von Fehlermeldungen in den Browser
use meinefunktionen;

$| = 1;

my %FORM = ();

# im Nachfolgenden Pfaf befinden sich die Verzeichnisse mit den
# verschiedenen Comic Sammlungen
my $datapfad = "../data/";
my $graphpfad = "../graphics/";

# Ein neues CSV-Objekt erzeugen
my $csv = Text::CSV->new(
	{ binary 			=> 1,	# alle Codes erlaubt
	  eol    			=> $\,	# Newline betriebssystemspezifisch setzen
	  allow_whitespace 	=> 1,	# Leerzeichen zwischen den Feldern erlauben
	  quote_char		=> '"',	# Anführungszeichen definieren
	  sep_char			=> ',',	# Feldtrenner definieren
	});

# Formulareingabe parsen
ParseForm();

my $verzeichnis = $FORM{'Verzeichnis'};
my $suchstring = $FORM{'Suchbegriff'};
my $aktion = $FORM{'suchen'};
my $coverpfad = "../data/$verzeichnis/cover/";		# Pfad zum Verzeichnis der Coverbilder
my $indexdatei = "../conf/index.txt";				# Pfad zur Indexdatei
my @indexvorgabe = 999;	# wenn Indexvorgabe = 999, dann werden alle Felder durchsucht

InsertHeader("Index durchsuchen");	

my $izaehler = DatensaetzeZaehlen($indexdatei);		# Zähler der durchsuchten Zeilen, d.h. Indexeinträge

my $accessdat = scalar localtime((stat($indexdatei))[9]);	# Datum des letzten Schreibzugriffs auf die Indexdatei

my @suchergebnis;
my $zaehler;		# Zähler für die Fundstellen

if ($aktion eq "los")
{	
	($zaehler, @suchergebnis) = LiefereSuchergebnis();
}

print "<H2>Liste der Fundstellen</H2>";
print "<h1>Suchbegriff: <I>$suchstring</I></h1>\n";
print "<FORM ACTION=\"$ENV{'SCRIPT_NAME'}\" METHOD=\"GET\">" . "\n";
print '<TABLE BORDER="0" bgcolor="#FFDAB9" CELLPADDING="3" CELLSPACING="1" width=100%>',"\n";
#print '<colgroup><col width=30%><col width=20%><col width=20%><col width=20%></colgroup>', "\n";
print "<TR><TD style=\"height:22px\">Suche nach: <INPUT TYPE=\"text\" name=\"Suchbegriff\" size=\"50\" value=\"$suchstring\"><INPUT TYPE=\"submit\" NAME=\"suchen\" VALUE=\"suchen\" onfocus=\"this.form.suchen.value='los'\"></TD><TD>Fundstellen: $zaehler</TD><TD>Einträge im Index: $izaehler</TD><TD>Datum der Indexdatei: $accessdat</TD></TR>\n";
print "</TABLE><BR />\n";

	print '<TABLE FRAME="BORDER" RULES="all" CELLPADDING="3" CELLSPACING="1">',"\n";	# Beginn der Tabelle
	# Titelzeile ausgeben
	print "<TR><TH>Cover</TH><TH>Heft-Titel</TH><TH>Heft-Untertitel</TH><TH>Serie-Nr.</TH><TH>Serie von</TH><TH>Status</TH><TH>Lagerort</TH><TH>Verlag</TH><TH>ISBN/Barcode-Nr.</TH><TH>Erstauflage</TH><TH>bearb.</TH><TH>Info</TH></TR>";
	my $i;
	#my @felder;
	for $i (0 .. $#suchergebnis)
	{
		my @felder = split_string($suchergebnis[$i]);
		# Heft
		$coverpfad = "../data/" . $felder[0] . "/cover";
		print "<TR><TD><A HREF=\"$coverpfad/$felder[39]\"><IMG ALT=\"$felder[39]\" SRC=\"$coverpfad/$felder[39]\" HEIGHT=\"100\"></A></TD><TD>$felder[2]</TD><TD>$felder[3]</TD><TD align=\"right\">$felder[5]</TD><TD align=\"right\">$felder[6]</TD><TD>$felder[21]</TD><TD>$felder[28]</TD><TD>$felder[8]</TD><TD align=\"right\">$felder[7]</TD><TD align=\"right\">$felder[9]</TD><TD ALIGN=\"center\"><a href=\"./hefteditieren.pl?Verzeichnis=$felder[0]&Datensatz=$felder[1]\" target=\"_blank\"><IMG TITLE=\"editieren\" ALT=\"editieren\" SRC=\"$graphpfad/edittopic.png\" WIDTH=\"16\" HEIGHT=\"16\"></a></TD><TD ALIGN=\"center\"><a href=\"./comicdetails.pl?Verzeichnis=$felder[0]&Datensatz=$felder[1]\" target=\"_blank\"><IMG TITLE=\"anzeigen\" ALT=\"anzeigen\" SRC=\"$graphpfad/info.png\" WIDTH=\"16\" HEIGHT=\"16\"></A></TD></TR>\n";		
	}
	print "</TABLE>\n";				# Ende der Tabelle

InsertTrailer();

#print "\n$zaehler Fundstellen\n";

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
	#print "<FORM METHOD=\"GET\" ACTION=\"sammlung_neu.pl\">";
	#print "</FORM>";
}

sub InsertTrailer
{
	# HTML-Nachspann ausgeben
	print "</BODY>\n</HTML>\n";
}


sub DatensaetzeZaehlen
{
	my $datei = $_[0];	# Dateiname und Pfad übernehmen
	my $zaehler = 0;	# Zähler für Datensätze
	
	# Datei zum Auslesen öffnen
	open(INDEX, "<", $datei) or die "Fehler beim öffnen von $datei: $!\n";
		my @datei = <INDEX>;	# Dateiinhalt in Array einlesen
	close(INDEX);
	
	foreach(@datei)
	{
		$zaehler++;
	}
	
	$zaehler -= 1;	# Einen Datensatz abziehen wegen Überschrift
	
	return($zaehler);
}

sub LiefereSuchergebnis
{
	# Datei zum Auslesen öffnen
	open(INDEX, "<", $indexdatei) or die "Fehler beim öffnen von $indexdatei: $!\n";
		my @datei = <INDEX>;	# Dateiinhalt in Array einlesen
	close(INDEX);
	
	my @daten;	# Array für die Aufnahme der Datenfelder
	my $treffer;	# Anzahl der Treffer der Suchanfrage
	my @ergebnis;	# Array mit den Nummern der Datenfelder in denen die Treffer liegen
	my @sergebnis;	# Array in dem die kompletten Strings abliegen in denen Treffer
						# gefunden wurden
	
	# my @indexvorgabe =(999);	# Vorgabe welche Datenfelder durchsucht werden sollen
	my $indexvorgabe_z = \@indexvorgabe;	# Zeiger (Referenz) auf Indexvorgabe
	
	my $counter = 0;	# Zähler für die durchsuchten Zeilen
	foreach my $zeile (@datei)
	{
		@daten = split_string($zeile);	# Aufteilen des Strings in die Datenfelder
		my $daten_z = \@daten;	# Zeiger (Referenz) auf das Array mit den Datenfeldern
		my ($treffer_t, @ergebnis_t) = DatenInArraySuchen($suchstring, $daten_z, $indexvorgabe_z);
		$treffer += $treffer_t;
		if (@ergebnis_t)
		{
			my @tmp;	# Temporäres Array erzeugen um Zeilenzahl an den Anfang...
			push(@tmp, ($counter, @ergebnis_t));	# des Ergebnis-Arrays schreiben
			push(@ergebnis, [@tmp]);				# zu können
			push(@sergebnis, $zeile);
		}
		$counter++;
	}
	
	if($treffer)
	{
		return($treffer, @sergebnis);
	}
	else
	{
		return(0);
	}
}

exit;