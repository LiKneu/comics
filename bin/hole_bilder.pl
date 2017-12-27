#!C:\strawberry\perl\bin\perl

#-----------------------------------------------------------------------------------------------------------
#
# Dieses Skript lädt die auf einer Webseite aufgeführten Bilder in das temporäre Verzeichnis herunter.
# Weitere Funktionen sind das Packen der einzelnen Seiten zu einer CBZ-Leseprobe und das Verschieben
# des Covers in das entsprechende Verzeichnis.
#
# Stand: 2013-06-16
#
# Historie:
#
# 2013-06-16		Kopieren des Covers nach Download hinzugefügt.
#					Packen der Einzelseiten in CBZ-Datei und Kopieren in Leseprobenverzeichnis hinzugefügt.
#
#-----------------------------------------------------------------------------------------------------------

use strict;
use warnings;
use File::Copy;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use LWP::Simple;
use HTML::LinkExtor;
use CGI::Carp qw(fatalsToBrowser);	# Umleitung von Fehlermeldungen in den Browser

$| = 1;

my %FORM = ();

# Formulareingabe parsen
ParseForm();

my $internetadresse = $FORM{'Internetadresse'};
# my $verlag = $FORM{'Verlag'};
# my @verlage = ("Splitter", "Finix"); 
my $aktion = $FORM{'download'};
my $optionen = $FORM{'Optionen'};
my $sammlungsname = $FORM{'Sammlungsname'};					# Name der Sammlung zu der die heruntergeladenen Bilder abgelegt werden sollen
my $coverpfad = "../data/$sammlungsname/cover/";			# Pfad zum Verzeichnis der Coverbilder
my $leseprobepfad = "../data/$sammlungsname/leseprobe/";	# Pfad zum Verzeichnis der Coverbilder
my $heftname = $FORM{'Heftname'};							# Name unter dem das heruntergeladenen Cover und ggf. die Leseprobe geseichert werden sollen
my $zipName;	 											# Pfad und Name der CBZ-Datei in der sich die Leseprobe befindet
my $downloadverzeichnis = $FORM{'Downloadverzeichnis'};		# Verzeichnis in dem die heruntergeladenen Datein zwischengespeichert werden
if ($downloadverzeichnis eq "")
{
	$downloadverzeichnis = "../tmp/";						# wenn kein anderes Downloadverzeichnis angegeben wird, dann Default setzen
}
my $renamepfad = $downloadverzeichnis . "rename/";			# Verzeichnis in welches die umbenannten Bilder kopiert und die CBZ-Datei erzeugt wird


InsertHeader("Cover und Leseproben downloaden");		# Beginn des HTML-Dokuments

print "<h2>Download von</h2>\n";
print "<h1>Coverbild und Leseprobe</h1>\n";
print '<TABLE BORDER="0" bgcolor="silver" CELLPADDING="3" CELLSPACING="1" width=100%>',"\n";
print "<TR><TD style=\"height:22px\"></TD></TR>\n";
print "</TABLE><BR />\n";
print "<FORM ACTION=\"$ENV{'SCRIPT_NAME'}\" METHOD=\"GET\">" . "\n";
print '<TABLE BORDER="0" CELLPADDING="3" CELLSPACING="1">',"\n";

# Das Auswahlmenü benötigt man nicht, da weiter unten anhand des Hyperlinks herausgefunden werden kann von welchem Verlag
# die Bilder heruntergeladen werden sollen.
#print "<TR><TD>Verlag auswählen:</TD><TD><SELECT NAME=\"Verlag\" SIZE=\"3\">\n";
#foreach (@verlage)
#{
#	if ($_ eq $verlag)
#	{
#		print "<OPTION SELECTED>$_\n";
#	}
#	else
#	{
#		print "<OPTION>$_\n";
#	}
#}
#print "</SELECT></TD></TR>\n";

print "<TR><TD>URL eingeben:</TD><TD><INPUT TYPE=\"text\" name=\"Internetadresse\" size=\"100\" value=\"$internetadresse\"></TD></TR>\n";
print "<TR><TD> </TD><TD><i>Link zur Internetseite mit den Bildern in obiges Feld kopieren</i></TD></TR>\n";
print "<TR><TD>Downloadverzeichnis:</TD><TD><INPUT TYPE=\"text\" name=\"Downloadverzeichnis\" size=\"50\" value=\"$downloadverzeichnis\"></TD><TD></TD></TR>\n";
print "<TR><TD> </TD><TD><i>Pfad zum Verzeichnis in welches die Bilder heruntergeladen werden sollen.</i></TD></TR>\n";
print "<TR><TD>Sammlungsname:</TD><TD><INPUT TYPE=\"text\" name=\"Sammlungsname\" size=\"50\" value=\"$sammlungsname\"></TD></TR>\n";
print "<TR><TD> </TD><TD><i>Name des Verzeichnisses in dem die Sammlung liegt eingeben.</i></TD></TR>\n";
print "<TR><TD>Heftname:</TD><TD><INPUT TYPE=\"text\" name=\"Heftname\" size=\"50\" value=\"$heftname\"></TD></TR>\n";
print "<TR><TD> </TD><TD><i>Name des Heftes eingeben. Format: Heftname_Heftnr</i></TD></TR>\n";
print "</TABLE><BR />\n";

# Prüfen welche optionen eingegeben wurden
my $killcheck;
if ($optionen =~ /killtmp/)
{
	$killcheck = "checked"
}
else
{
	$killcheck = "unchecked"
}

my $umbenenncheck;
if ($optionen =~ /umbenennen/)
{
	$umbenenncheck = "checked"
}
else
{
	$umbenenncheck = "unchecked"
}

my $kopiecheck;
if ($optionen =~ /kopieren/)
{
	$kopiecheck = "checked"
}
else
{
	$kopiecheck = "unchecked"
}

print "<INPUT TYPE=\"checkbox\" name=\"Optionen\" value=\"umbenennen\" $umbenenncheck>umbenennen\n";
print "<INPUT TYPE=\"checkbox\" name=\"Optionen\" value=\"kopieren\" $kopiecheck>kopieren\n";
print "<INPUT TYPE=\"checkbox\" name=\"Optionen\" value=\"killtmp\" $killcheck>tmp-Verzeichnis leeren\n";

print "<p>Optionen: $optionen</p>\n";

print "<p><INPUT TYPE=\"submit\" NAME=\"download\" VALUE=\"download\" onfocus=\"this.form.download.value='load'\"></p>\n";

print "</FORM>\n";

my %links;
my $tag;
my $key;
my $bildname;

if ($aktion eq "load")
{
	if ($optionen =~ "kopieren")	# Falls die Option zum Verschieben der heruntergeladenen Bilder aktiviert ist...
	{
		if($sammlungsname && $heftname)	# Nur wenn ein Sammlungsname und ein Heftname angegeben ist...
		{
			bild_download();	# ...mit dem Download der Bilder und anschließend...
			
			# Prüfen, ob es schon eine Leseprobe oder ein Cover mit dem $heftname gibt.
			# Wenn ja, dann Warnung ausgeben.
			my $tempd = $leseprobepfad . $heftname . "_Leseprobe.cbz";
			my $tempc = $coverpfad . $heftname . "\.jpg";
			if (-e $tempd && -e $tempc)
			{
				print "<p>ACHTUNG: <$tempd> oder <$tempc> schon vorhanden. Packen & Kopieren von Cover und Leseprobe abgebrochen.</p>\n";
			} 
			else
			{
				LeseprobePacken();	# ...dem Umbenennen, Packen und Kopieren der Bilder fortfahren
			}
		}
		else
		{
			print "<p>Sammlungsname und oder Heftname fehlen um das Coverbild sowie die Leseprobe zu erstellen bzw. kopieren.</p>\n";
		}
		
		if ($optionen =~ "killtmp")
		{
			# Prüfen, ob die zu kopierenden Dateien am Bestimmungsort angekommen sind
			# wenn ja, dann überflüssige Dateien löschen
			# wenn nein, dann Warnung ausgeben
			my $tempd = $leseprobepfad . $heftname . "_Leseprobe.cbz";
			my $tempc = $coverpfad . $heftname . "\.jpg";
			if (-e $tempd && -e $tempc)
			{
				print "Die heruntergeladenen Dateien in <$downloadverzeichnis> werden gelöscht.";
				my $rmdateien = $downloadverzeichnis . "*.*";	# Alle Dateien im Downloadverzeichnis löschen
				unlink glob $rmdateien || die "Bein löschen der Dateien <$rmdateien> ist ein Fehler aufgetreten: $!<br />\n";
				$rmdateien = $renamepfad . "*.*";				# Alle Dateien im Renameverzeichnis löschen
				unlink glob $rmdateien || die "Bein löschen der Dateien <$rmdateien> ist ein Fehler aufgetreten: $!<br />\n";
			}
			else
			{
				print "ACHTUNG: Datei <$tempd> oder <$tempc> ist nicht im Zielverzeichnis vorhanden. Dennoch die Ursprungsdateien löschen?<br />\n";
			}
			
		}
	}
	else
	{
		bild_download();	# nur Bilder Download durchführen d.h. kein CBZ, kein Cover
	}
}


InsertTrailer();				# Ende des HTML-Dokuments

sub bild_download
{
	my $URL = get($internetadresse);
	my $LinkExtor = HTML::LinkExtor->new(\&links);
	$LinkExtor->parse($URL);
}

sub links
{
	($tag, %links) = @_;
	if ($tag eq "a")
	{
		foreach $key (keys %links)
		{
			my $hyperlink = $links{$key};
			if ($key eq "href")
			{
				# anhand der Schlüsselwörter "seite", "cover" und "900x1200" lassen sich die Bilder für Cover und Leseprobe
				# identifizieren. Bei Finix wird die "Seite" groß geschrieben, bei Splitter hingegen klein daher zuvor die
				# Umwandlung in Kleinbuchstaben mit lc()
				if (lc($hyperlink)=~ "seite" or $hyperlink =~ "cover" or $hyperlink =~ "900x1200")
				{					
					my @worte = split ("/", $hyperlink);
					$bildname = pop(@worte);
					
					if ($hyperlink =~ "finix")	# prüfen ob Bilder von Finix geladen werden sollen
					{
						$hyperlink = "http://www.finix-comics.de/" . $hyperlink;	# wenn ja, dann muss vor den Link aus dem HTML-Dokument noch die
					}																# Server-Adresse gehängt werden um den Download möglich zu machen
					print "$hyperlink - $bildname<br />\n";
					LWP::Simple::getstore($hyperlink, $downloadverzeichnis . $bildname);
					
				} # if
			} #if
		} #foreach
	} #if
}

sub InsertHeader
{
	# HTTP-Header und HTML-Vorspann ausgeben
	my ($htmltitle) = @_;
	print "Content-type: text/html\n\n";
	print "<HTML>\n<HEAD>\n";
	print "<TITLE> $htmltitle </TITLE>\n";
	print "</HEAD>\n";
	print "<BODY>";
}

sub InsertTrailer
{
	# HTML-Nachspann ausgeben
	print "</BODY>\n</HTML>\n";
}

# TODO ParseForm durch Funktion in eigenem Modul ersetzen.
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

sub LeseprobePacken
{
	my @bilddateien;
	my @neubilddatei;
	
	opendir(DIR, $downloadverzeichnis);
	while(my $datei = readdir(DIR))	# alle Verzeichniseinträge lesen (Dateien und Verzeichnisse)
	{
		my $dateikpl = $downloadverzeichnis . "/" . $datei;
		if (!-d $dateikpl)	# Verzeichnisse von der weiteren Bearbeitung ausschließen
		{
			push @bilddateien, $datei;
		}
	}
	closedir(DIR);
	
	foreach(@bilddateien)
	{
		my $tmpdatei = $_;
		my $originalname = $downloadverzeichnis . "/" . $tmpdatei; 
		my $neudatei = "";
		my $neuname = "";
	
		if ($tmpdatei =~ /cover/)	# Falls im Dateinamen das Wort "cover" auftritt,
		{							# dann ist das immer die erste Seite d.h. Seite 00
			$neudatei = "00.jpg";
			$neuname = $renamepfad . $neudatei;
			copy ($originalname, $neuname) || die "Kopieren des Covers ging schief: $!\n";
		}
		elsif($tmpdatei =~ /.*([^0-9])([0-9])\.jpg$/)	# Falls die einstelligen Seitenzahlen ohne
		{												# führende Null vorliegen, dann in 01, 02, 03 ...
			$neudatei = "0$2.jpg";						# umwandeln
			$neuname = $renamepfad . $neudatei;
			copy ($originalname, $neuname) || die "Kopieren einer Seite ging schief: $!\n";
		}
		elsif($tmpdatei =~ /[0-9]{2}\.jpg$/)	# Falls die einstelligen Seitenzahlen bereits
		{										# mit führender Null vorliegen, dann so belassen
			$neudatei = "$&";
			$neuname = $renamepfad . $neudatei;
			copy ($originalname, $neuname) || die "Kopieren einer Seite ging schief: $!\n";
		}
		push @neubilddatei, $neudatei;		# neue Dateinamen an das Array anhängen
	}
	
	@neubilddatei = sort(@neubilddatei);	# neue Dateinamen sortieren
	
	my $zip = Archive::Zip->new();			# neues Archiv anlegen
	
	foreach my $seite (@neubilddatei)		# alle sortierten Bilddateien in das Archiv schreiben
	{
		$zip->addFile($renamepfad . "/" . $seite, $seite) || warn "Kann die Seite nicht in das Archiv hängen: $seite\n";
	}
	
	$zipName = $renamepfad . $heftname . "_Leseprobe.cbz";	# Den Dateinamen des Archives zusammen setzen
	my $status = $zip->writeToFileNamed($zipName);			# Das Archiv auf die Festplatte schreiben
	if ($status)
	{
		print "<br\/>Fehler beim Erzeugen der CBZ-Datei <$zipName><br\/>\n";
	}
	
	if($sammlungsname)
	{
		my $sammlungspfad = "../data/$sammlungsname";
		if (-d $sammlungspfad)	# prüfen, ob das angegebene Sammlungsverzeichnis überhaupt existiert
		{
			my $td = $leseprobepfad . $heftname . "_Leseprobe.cbz";
			copy ($zipName, $td) || die "Fehler beim Kopieren der Datei $zipName: $!\n";
			print "<br\/>Datei $zipName nach $td kopiert.<br\/>\n";
		}
		else
		{
			print "<br\/>Sammlungsverzeichnis <$sammlungspfad> existiert nicht.<\/br>\n";
		}
	}
	my $cover_source = $renamepfad . $neubilddatei[0];
	my $cover_destiny = $coverpfad . $heftname . "\.jpg";
	print "Cover Quelle: $cover_source<br \/>\n";
	print "Cover Ziel  : $cover_destiny<br \/>\n";
	copy ($cover_source, $cover_destiny) || die "Fehler beim Kopieren des Covers $cover_source nach $cover_destiny: $!<br \/>\n";
}

exit;