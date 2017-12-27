#!C:\strawberry\perl\bin\perl

use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser);	# Umleitung von Fehlermeldungen in den Browser

my $datapfad = "../data/";				# im Falle der Web-Anwendung
my $indexdatei = "../conf/index.txt";	# im Falle der Web-Anwendung
#my $datapfad = "C:/Users/Volker/Documents/Perl/comics/data/";				# im Falle der Konsolen-Anwendung
#my $indexdatei = "C:/Users/Volker/Documents/Perl/comics/conf/index.txt";	# im Falle der Konsolen-Anwendung

# verfügbare Verzeichnisse, d.h. Sammlungen auslesen
opendir(DIR, $datapfad);
my @verzeichnisse;
my $i = 0;
while(my $datei = readdir(DIR))
{
	my $dateikpl = $datapfad . $datei ;
	if (-d $dateikpl)
	{
		if ($datei !~ /\./)		# Die Verzeichniseinträge . und .. ausschließen
		{
			$verzeichnisse[$i] = $datei;
			$i++;
		}
	}
}
closedir(DIR);

open (INDEXDAT, ">", $indexdatei) or die "Fehler beim Öffnen von $indexdatei: $?\n";
print INDEXDAT "Verzeichnis,Datensatz,Heft-Titel,Heft-Untertitel,Sprache,Serien-Nr.,Serie von,ISBN/Barcode-Nr.,Verlag,Erstauflage,Kaufdatum,Originalpreis,Einkaufspreis,Akt. Handelspreis,Händler,Bemerkung 1,URL,Autor(en),Zustand,Eigenschaft(en),Bewertung,Status,Darsteller,Einbandart,Format,Genre,Bemerkung 2,Exemplare,Lagerort,Statushinweis,Heft-Verweise,Seiten,Inhalt/Geschichte,Rezensionen,Inhaltsbewertung,Handelspreise,Comic-Typ,Autor(en) + Job,Enthalten in,Link zum Cover" . "\n";
# in jedem Verzeichnis nach der Date hefte.txt suchen und diese in die zuvor geöffnete Indexdatei schreiben
foreach (@verzeichnisse)
{
	my $verzeichnis = $_;
	my $csvdatei = $datapfad . $verzeichnis . "/hefte.txt";
	open (CSVDAT, "<", $csvdatei) or die "Fehler beim Öffnen von $csvdatei: $?\n";
	my @hefte = <CSVDAT>;
	close(CSVDAT);
	# print "Verzeichnis: $verzeichnis\tAnzahl Hefteinträge: $#hefte\n"
	my $i;
	for $i (1 .. $#hefte)
	{
		print INDEXDAT "\"$verzeichnis\",\"$i\",$hefte[$i]";	# in der Ausgabe noch den Verzeichnisnamen sowie die Datensatz-Nr. am Anfang jeder Zeile einfügen
	}
}
close (INDEXDAT);

InsertHeader("Index erstellen");
InsertTrailer();

exit;

sub InsertHeader
{
	# HTTP-Header und HTML-Vorspann ausgeben
	my ($htmltitle) = @_;
	print "Content-type: text/html\n\n";
	print "<HTML>\n<HEAD>\n";
	print "<link rel=\"icon\" type=\"image\/x-icon\" href=\"C:/Users/Volker/Documents/Perl/comics/favicon.ico\" />" . "\n";
	print "<link rel=\"shortcut icon\" href=\"C:/Users/Volker/Documents/Perl/comics/favicon.ico\" type=\"image\/x-icon\" />" . "\n";
	print "<TITLE> $htmltitle </TITLE>\n</HEAD>\n";
	print "<BODY>";
	print "<h2> Comic Startseite </h2>";
	print "<h1> $htmltitle </h1>";
}

sub InsertTrailer
{
	# HTML-Nachspann ausgeben
	print "</BODY>\n</HTML>\n";
}

