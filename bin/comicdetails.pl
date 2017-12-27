#!C:\strawberry\perl\bin\perl

#------------------------------------------------------------------------------
# comicdetails.pl
#
# Dieses Skript liest die durch den Comic Keeper erzeugten CSV Datei ein und
# speichert die Informationen in einem Array.
# Anschließend werden alle Informationen zu einem Heft, welches durch das
# aufrufende Programm spezifiziert wurde, ausgegeben.
#------------------------------------------------------------------------------

# Aufbau der Comic Keeper CSV-Datei:
# Heft-Titel,Heft-Untertitel,Sprache,Serien-Nr.,Serie von,ISBN/Barcode-Nr.,Verlag,Erstauflage,Kaufdatum,Originalpreis,Einkaufspreis,Akt. Handelspreis,Händler,Bemerkung 1,URL,Autor(en),Zustand,Eigenschaft(en),Bewertung,Status,Darsteller,Einbandart,Format,Genre,Bemerkung 2,Exemplare,Lagerort,Statushinweis,Heft-Verweise,Seiten,Inhalt/Geschichte,Rezensionen,Inhaltsbewertung,Handelspreise,Comic-Typ,Autor(en) + Job,Enthalten in

use strict;
use warnings;
use Text::CSV;

$| = 1;

my %FORM = ();

# Formulareingabe parsen
ParseForm();
my $verzeichnis = $FORM{'Verzeichnis'};
my $datensatz = $FORM{'Datensatz'};

my $csvdatei = '../data/' . $verzeichnis . '/hefte.txt';	# CSV-Datei der Comics
my $coverpfad = "../data/$verzeichnis/cover/";				# Pfad zum Verzeichnis der Coverbilder
my $iconpfad = "../data/$verzeichnis/icon/favicon.ico";		# Pfad zum Icon für die Darstellung im Tab
my $graphpfad = "../graphics/";

# Ein neues CSV-Objekt erzeugen
my $csv = Text::CSV->new(
	{ binary 			=> 1,	# alle Codes erlaubt
	  eol    			=> $\,	# Newline betriebssystemspezifisch setzen
	  allow_whitespace 	=> 1,	# Leerzeichen zwischen den Feldern erlauben
	  quote_char		=> '"',	# Anführungszeichen definieren
	  sep_char			=> ',',	# Feldtrenner definieren
	});

# Einlesen der CSV-Datei mit den Datensätzen der in der Sammlung enthaltenen Hefte
open (SAMMLUNG, "<", $csvdatei) or die "Fehler beim öffnen von $csvdatei: $?\n";
my @hefte = <SAMMLUNG>;
close(SAMMLUNG);

my $anzhefte = $#hefte;	# Anzahl der Datensätze im Array ermitteln


my @ueberschriften = split_string($hefte[0]);
# my @felder = split_string($hefte[$FORM{'Datensatz'}]);
my @felder = split_string($hefte[$datensatz]);

my $src;	# Text für IMG Tag
my $alt;	# Text für IMG Tag
my $keincover;	# Text für Fehlermeldung

if ($#ueberschriften > 36)	# prüfen ob es schon mehr als 37 Datenfelder gibt, d.h. ob schon eine Spalte 38 für den Eintrag des Coverbildes vorhanden ist
{
	#if ($felder[37] =~ "")	# prüfen ob schon ein Dateiname eingegeben wurde...
	if ($felder[37])	# prüfen ob schon ein Dateiname eingegeben wurde...
	{
		$alt = $felder[37];					# ...ja - also Texte zuweisen
		$src = $coverpfad . $felder[37];
	}
	else
	{
		$alt = "kein Coverbild zugeordnet";	# ...nein - also auf fehlende Informationen hinweisen
		$keincover = $alt;
		$src = "$graphpfad/kein_Cover.png"; 
	}
}
else	# wenn die CSV-Datei noch alt ist, d.h. keinen Eintrag für Coverbilder enthält, dann darauf hinweisen.
{
	$alt = "CSV-Datei enthält noch keine Spalte für ein Coverbild";
	$keincover = $alt;
	$src = "$graphpfad/kein_Cover.png";
}


InsertHeader("Details zu: $verzeichnis, $datensatz");		# Beginn des HTML-Dokuments

print "<h2>Details zum Heft: <I>Datensatz $datensatz</I></h2>";
print "<h1>Verzeichnis: <I>$verzeichnis</I></h1>";
print '<TABLE BORDER="0" bgcolor="#ADFF2F" CELLPADDING="3" CELLSPACING="1" width=100%>',"\n";
# print '<TABLE BORDER="1" frame="hsides" rules="none" bgcolor="silver" CELLPADDING="3" CELLSPACING="1" width=100%>',"\n";
print '<TR align="center"><TD width="10%"><a href="./comicdetails.pl?Verzeichnis=' . $verzeichnis . '&' . 'Datensatz=1"><IMG TITLE="erstes" ALT="erstes" SRC="' . $graphpfad . '/go_start.png" WIDTH="16" HEIGHT="16"></a></TD><TD width="10%"><a href="./comicdetails.pl?Verzeichnis=' . $verzeichnis . '&' . 'Datensatz=' . ($datensatz - 1) .'"><IMG TITLE="zur�ck" ALT="zur�ck" SRC="' . $graphpfad . '/go_back.png" WIDTH="16" HEIGHT="16"></a></TD><TD><a href="./hefteditieren.pl?Verzeichnis=' . $verzeichnis . '&Datensatz=' . $datensatz . '" target="_blank"><IMG TITLE="editieren" ALT="editieren" SRC="' . $graphpfad . '/edittopic.png" WIDTH="16" HEIGHT="16"></a></TD><TD width="10%"> <a href="./comicdetails.pl?Verzeichnis=' . $verzeichnis . '&' . 'Datensatz=' . ($datensatz + 1) .'"><IMG TITLE="n&auml;chstes" ALT="n&auml;chstes" SRC="' . $graphpfad . '/go_forward.png" WIDTH="16" HEIGHT="16"></a> </TD><TD width="10%"> <a href="./comicdetails.pl?Verzeichnis=' . $verzeichnis . '&' . 'Datensatz=' . $#hefte .'"><IMG TITLE="letztes" ALT="letztes" SRC="' . $graphpfad . '/go_end.png" WIDTH="16" HEIGHT="16"></a> </TD></TR>' . "\n";
#print '<TR align="center"><TD width="10%"><a href="./comicdetails.pl?Verzeichnis=' . $verzeichnis . '&' . 'Datensatz=1"> << </a></TD><TD width="10%"><a href="./comicdetails.pl?Verzeichnis=' . $verzeichnis . '&' . 'Datensatz=' . ($datensatz - 1) .'"> < </a></TD><TD><a href="./hefteditieren.pl?Verzeichnis=' . $verzeichnis .'&' . 'Datensatz=' . $datensatz .'" target="_blank">editieren</a></TD><TD width="10%"> <a href="./comicdetails.pl?Verzeichnis=' . $verzeichnis . '&' . 'Datensatz=' . ($datensatz + 1) .'"> > </a> </TD><TD width="10%"> <a href="./comicdetails.pl?Verzeichnis=' . $verzeichnis . '&' . 'Datensatz=' . $#hefte .'"> >> </a> </TD></TR>' . "\n";
print '</TABLE>' . "\n";

# Coverbild ausgeben (wenn vorhanden)
print '<P><A HREF="' . $src . '"><IMG ALT="' . $alt . '" SRC="' . $src . '" WIDTH="150"><BR /></A>' . $keincover . '</P>' . "\n";

# sämtliche Überschriften und dazugehörige Feldinformationen in einer Tabelle darstellen
print '<TABLE FRAME="BORDER" RULES="all" CELLPADDING="3" CELLSPACING="1">',"\n";	# Beginn der Tabelle
my $i;
for $i (0 .. $#ueberschriften){
	print "<TR><TH align=\"left\">$ueberschriften[$i]</TH><TD>$felder[$i]</TD><TD align=\"center\">$i</TD></TR>\n";
}
print "</TABLE>\n";				# Ende der Tabelle

InsertTrailer();				# Ende des HTML-Dokuments

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

sub InsertHeader
{
	# HTTP-Header und HTML-Vorspann ausgeben
	my ($htmltitle) = @_;
	print "Content-type: text/html\n\n";
	print "<HTML>\n<HEAD>\n";
	print "<TITLE> $htmltitle </TITLE>\n";
	print '<link rel="icon" href="' . $iconpfad .'" type="image/x-icon" />' . "\n";
	print '<link rel="shortcut icon" href="' . $iconpfad .'" type="image/x-icon" />' . "\n";
	print "</HEAD>\n";
	print "<BODY>";
}

sub InsertTrailer
{
	# HTML-Nachspann ausgeben
	print "</BODY>\n</HTML>\n";
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

exit;