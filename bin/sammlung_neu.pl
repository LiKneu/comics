#!C:\strawberry\perl\bin\perl

#------------------------------------------------------------------------------
# Skript:			sammlung_neu.pl
# Aufruf durch: 	sammlungsliste.pl
#
# Dieses Skript erzeugt die Verzeichnisstruktur und eine leere CSV-Datei für
# eine neue Sammlung.
#------------------------------------------------------------------------------

use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser);	# Umleitung von Fehlermeldungen in den Browser

$| = 1;

my %FORM = ();

# Formulareingabe parsen
ParseForm();

my $sammlung_name = $FORM{'Sammlung'};	# der Sammlungsname ist nur vorhanden wenn dieser ins Feld eingegeben und die RETURN-Taste gedrückt wurde
my $aktion = $FORM{'Aktion'};			# die Aktion "anlegen" ist nur vorhanden, wenn der Link zum Anlegen geklickt wurde.

my $sammlung_pfad = "../data/$sammlung_name";

InsertHeader("Neue Sammlung");		# Beginn des HTML-Dokuments

print "<h1>Neue Sammlung anlegen</h1>\n";

print "<FORM ACTION=\"$ENV{'SCRIPT_NAME'}\" METHOD=\"GET\">" . "\n";
print '<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="2">' . "\n";
print '<TR><TD>Verzeichnisnamen der neuen Sammlung eingeben:</TD></TR>' . "\n";
print '<TR><TD><INPUT TYPE="text" name="Sammlung" size="100" value="' . $sammlung_name . '"></TD><TD><a href="./sammlung_neu.pl?Sammlung=' . $sammlung_name . '&Aktion=anlegen">Sammlung anlegen</a></TD></TR>' . "\n";
print '</TABLE>' . "\n";

if (($sammlung_name ne "") && ($aktion eq "anlegen") )	# falls ein Sammlungsname eingegeben wurde und der Link zum anlegen geklickt wurde ...
{
	print '<P><TABLE BORDER="0" CELLSPACING="0" CELLPADDING="2">' . "\n";
	print '<TR><TD>Name der Sammlung:</TD><TD>' . $sammlung_name . '</TD></TR>' . "\n";
	print '<TR><TD>Pfad zur Sammlung:</TD><TD>' . $sammlung_pfad . '</TD></TR>' . "\n";
	if (opendir(my $dh, $sammlung_pfad))	# ...und falls das angegebene Verzeichnis noch nicht existiert...
	{
		print '<TR><TD>Verzeichnis existiert bereits:</TD><TD><span style="color:red">' . $sammlung_pfad . '</span></TD></TR>' . "\n";
		closedir ($dh);
	}
	else
	{
		# ...dann wird die Verzeichnisstruktur sowie eine leere CSV-Datei mit den Feldüberschriften angelegt.
		print '<TR><TD>Verzeichnisse wurden angelegt:</TD><TD><span style="color:green">' . $sammlung_pfad . '</span></TD></TR>' . "\n";
		mkdir "$sammlung_pfad";
		mkdir "$sammlung_pfad/cover";
		mkdir "$sammlung_pfad/icon";
		mkdir "$sammlung_pfad/leseprobe";
		mkdir "$sammlung_pfad/logo";
		open (DATEI, ">", $sammlung_pfad . "/hefte.txt") or die "Fehler beim Schreiben von $sammlung_pfad/hefte.txt: $?\n";
		print DATEI "Heft-Titel,Heft-Untertitel,Sprache,Serien-Nr.,Serie von,ISBN/Barcode-Nr.,Verlag,Erstauflage,Kaufdatum,Originalpreis,Einkaufspreis,Akt. Handelspreis,Händler,Bemerkung 1,URL,Autor(en),Zustand,Eigenschaft(en),Bewertung,Status,Darsteller,Einbandart,Format,Genre,Bemerkung 2,Exemplare,Lagerort,Statushinweis,Heft-Verweise,Seiten,Inhalt/Geschichte,Rezensionen,Inhaltsbewertung,Handelspreise,Comic-Typ,Autor(en) + Job,Enthalten in,Link zum Cover" . "\n";
		close (DATEI);

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

		my $log_string = "$jjjj-$mm-$tt\_$std$min$sec; NEUE SAMMLUNG; Verzeichnis: $sammlung_pfad";
		SchreibeLog($log_string);
	}
	#print '<TR><TD>zur Serie springen:</TD><TD><a href="/comics/data/' . $sammlung_name . '" target="_blank">' . $sammlung_name . '</a></TD></TR>' . "\n"; # Link zum Öffnen des Verzeichnisses in Apache funktioniert irgendwie nicht??? 
	print '</TABLE></P>' . "\n";
}
print "</FORM>" . "\n";

InsertTrailer();						# Ende des HTML-Dokuments

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

sub SchreibeLog
{
	my ($log_meldung) = @_;
	my $logdatei = "../logs/edit_log.txt";
	open (LOGDATEI, ">>", $logdatei) or die "Fehler beim Schreiben von $logdatei: $?\n";
	print LOGDATEI "$log_meldung\n";
	close (LOGDATEI);
}

exit;