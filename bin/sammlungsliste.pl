#!C:\strawberry\perl\bin\perl

#------------------------------------------------------------------------------
# Dieses Programm durchsucht das data-Verzeichnis nach enthaltenen
# Comic-Sammlungen
#
# Vorgehensweise:
# 1. Alle Verzeichnisse einlesen. Jedes Verzeichnis enthält eine Sammlung.
# 2. Um den Klartextnamen der Sammlung zu erhalten muss die CSV-Datei geöffnet
#    und die 2. Zeile mit dem Sammlungsnamen ausgelesen werden.
#
# Anker definieren und im gleichen Dokument verlinken:
# <a name="ankername"></a>
# <a href="#ankername">zum Anker</a>
#
# Link in neuem Tab/Fenster öffnen
# <a href="URL" target="_blank">Linkname</a>
#------------------------------------------------------------------------------

use strict;
use warnings;
use Text::CSV;

# im Nachfolgenden Pfaf befinden sich die Verzeichnisse mit den
# verschiedenen Comic Sammlungen
my $datapfad = "../data/";
my $graphpfad = "../graphics/";

# alle Verzeichnisse d.h. alle möglichen Sammlungen in das Array
# @verzeichnisse einlesen

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

InsertHeader("$i Sammlungen");		# Beginn des HTML-Dokuments

SchreibeAnker();

# nun die CSV-Dateien der einzelnen Verzeichnisse nach dem
# Sammlungsnamen durchsuchen

my $tmp = "";
my $tabelleoffen = 0;
for(@verzeichnisse)
{
	my $verzeichnis = $_;

	my $sammlungsdatei = $datapfad . $verzeichnis . "/" . "hefte\.txt";

	my @zeile;
	@zeile = csv_lesen($sammlungsdatei);

	if ($tmp !~ substr($zeile[36],0,1))
	{
		if ($tabelleoffen)
		{
			print "</TABLE>" . "\n";
		}
		$tmp = substr($zeile[36],0,1);
		print '<P><a name="' . $tmp . '">' . $tmp . '</a></P>' . "\n";
		print '<TABLE FRAME="BORDER" RULES="all" CELLPADDING="3" CELLSPACING="1">',"\n";
		print '<colgroup><col width="400"><col width="400"><col width="45"></colgroup>';
		print '<TR><TH align="left">Sammlung</TH><TH align="left">Verzeichnis</TH><TH align="left">vollständig</TH><TH align="left">Info</TH></TR>',"\n";
		# <A HREF="' . $src . '"><IMG ALT="' . $alt . '" SRC="' . $src . '" WIDTH="150"><BR /></A>
		print "<TR><TD>$zeile[36]</TD><TD><i>$verzeichnis</i></TD><TD></TD><TD ALIGN=\"center\"><a href=\"./seriezeigen.pl?Verzeichnis=$verzeichnis\" target=\"_blank\"><IMG TITLE=\"anzeigen\" ALT=\"anzeigen\" SRC=\"$graphpfad/info.png\" WIDTH=\"16\" HEIGHT=\"16\"></a></TD></TR>\n";
		$tabelleoffen = 1;
	}
	else
	{
		print "<TR><TD>$zeile[36]</TD><TD><i>$verzeichnis</i></TD><TD></TD><TD ALIGN=\"center\"><a href=\"./seriezeigen.pl?Verzeichnis=$verzeichnis\" target=\"_blank\"><IMG TITLE=\"anzeigen\" ALT=\"anzeigen\" SRC=\"$graphpfad/info.png\" WIDTH=\"16\" HEIGHT=\"16\"></a></TD></TR>\n";		
	}	
}
print "</TABLE> \n";

InsertTrailer();				# Ende des HTML-Dokuments


sub csv_lesen
{
	my $csvdatei = shift;
	my @felder;
	
	# Einlesen der CSV-Datei mit den Datensätzen der in der Sammlung enthaltenen Hefte
	open (SAMMLUNG, "<", $csvdatei) or die "Fehler beim Öffnen von $csvdatei: $?\n";
	my @hefte = <SAMMLUNG>;
	close(SAMMLUNG);

	my $anzhefte = $#hefte;	# Anzahl der Datensätze im Array ermitteln
	
#	my $maxhefte = 0;	# Anzahl der Hefte die vorhanden sein muss damit die Serie vollständig ist
#	my $i = 0;
#	foreach(@hefte)
#	{
#		my @datenfelder = split_string($_);
#		if ($datenfelder[4] ne "")	# falls Eintrag "Serie von" nicht leer ist, dann enthält diese Feld die Anzahl der in der Serie enthaltenen Hefte
#		{
#			$maxhefte = $datenfelder[4];	# Anzahl der Hefte speichern
#		}
#		
#	}

	#my @ueberschriften = split_string($hefte[0]);
	@felder = split_string($hefte[1]);
	return @felder;
}

sub split_string
{
	my $line = shift;
	my @new;
	
	# Ein neues CSV-Objekt erzeugen
	my $csv = Text::CSV->new(
	{ binary 			=> 1,	# alle Codes erlaubt
	  eol    			=> $\,	# Newline betriebssystemspezifisch setzen
	  allow_whitespace 	=> 1,	# Leerzeichen zwischen den Feldern erlauben
	  quote_char		=> '"',	# Anführungszeichen definieren
	  sep_char			=> ',',	# Feldtrenner definieren
	});
	
	if ($csv->parse($line))
	{
		@new = $csv->fields();
		return (@new);
	}
	else
	{
		# sonst die aktuelle Zeile ausgeben
		print "**** ", $csv->error_input, "\n",
		# und die Fehlerursache (Zahl am Schluss = Fehlerposition)
		      "**** ", $csv->error_diag, "\n";
		return (undef);
	}
}

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

sub SchreibeAnker
{
	my @alphabet = ('A'..'Z');
	print "<P>\n";
	print '<TABLE BORDER="0" bgcolor="#ADFF2F" WIDTH="100%" CELLPADDING="3" CELLSPACING="0">',"\n<TR>\n";
	for(@alphabet)
	{
		print "<TD><a href=\"#$_\"> $_ </a></TD>";
	}
	print "</TR>\n</TABLE>\n";
	print "</P>\n";	
}

exit;