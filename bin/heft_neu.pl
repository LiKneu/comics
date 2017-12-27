#!C:\strawberry\perl\bin\perl

#------------------------------------------------------------------------------
# Skript:			heft_neu.pl
# Aufruf durch: 	seriezeigen.pl
#
# Dieses Skript ergänzt die CSV-Datei einer Serie um ein neues Heft.
#------------------------------------------------------------------------------

use strict;
use warnings;
use File::Copy;
use CGI::Carp qw(fatalsToBrowser);	# Umleitung von Fehlermeldungen in den Browser

$| = 1;

my %FORM = ();

# Formulareingabe parsen
ParseForm();

my $verzeichnis = $FORM{'Verzeichnis'};
my $knopf = $FORM{'speichern'};
my @comicfelder = ($FORM{'titel'},
				   $FORM{'untertitel'},
				   $FORM{'sprache'},
				   $FORM{'seriennr'},
				   $FORM{'serie'},
				   $FORM{'isbn'},
				   $FORM{'verlag'},
				   $FORM{'erstauflage'},
				   $FORM{'kaufdatum'},
				   $FORM{'originalpreis'},
				   $FORM{'einkaufspreis'},
				   $FORM{'handelspreis'},
				   $FORM{'haendler'},
				   $FORM{'bem1'},
				   $FORM{'url'},
				   $FORM{'autoren'},
				   $FORM{'zustand'},
				   $FORM{'eigenschaften'},
				   $FORM{'bewertung'},
				   $FORM{'status'},
				   $FORM{'darsteller'},
				   $FORM{'einbandart'},
				   $FORM{'format'},
				   $FORM{'genre'},
				   $FORM{'bem2'},
				   $FORM{'exemplare'},
				   $FORM{'lagerort'},
				   $FORM{'statushinweis'},
				   $FORM{'heftverweise'},
				   $FORM{'seiten'},
				   $FORM{'inhaltgesch'},
				   $FORM{'rezensionen'},
				   $FORM{'inhaltsbewertung'},
				   $FORM{'handelspreise'},
				   $FORM{'comictyp'},
				   $FORM{'autorenjob'},
				   $FORM{'enthaltenin'},
				   $FORM{'coverlink'});

my %felder = LeseConfig();

InsertHeader("neues Heft");				# Beginn des HTML-Dokuments

# Entfernen von ggf. vorhandenen Zeilenumbrüchen wie z.B. \n \r aus den TEXTAREAS.
$comicfelder[13] =~ tr/\n|\r/ /s;
$comicfelder[24] =~ tr/\n|\r/ /s;
$comicfelder[30] =~ tr/\n|\r/ /s;

print "<H1>Neues Heft in Verzeichnis: <I>$verzeichnis</I></H1>";

	# HTML-Formular ausgeben
	print qq~
	<FORM ACTION="$ENV{'SCRIPT_NAME'}" METHOD="GET">	<!-- # POST (für große Datenmengen), GET (ist schneller als POST) -->
	<INPUT TYPE="HIDDEN" NAME="Verzeichnis" VALUE="$verzeichnis">
	<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="2">
	<TR><TD>Titel:<SPAN STYLE="COLOR:RED"> *</SPAN></TD><TD><INPUT TYPE="TEXT" NAME="titel" VALUE="$comicfelder[0]"  SIZE=50></TD></TR>
	<TR><TD>Untertitel:</TD><TD><INPUT TYPE="TEXT" NAME="untertitel" VALUE="$comicfelder[1]" SIZE=50></TD></TR>
	<TR><TD>Sprache:<SPAN STYLE="COLOR:RED"> *</SPAN></TD><TD>
	~;
	
	
	# ---- Hier die ListBoxSingle für die Sprachen einbinden ----
	# <TR><TD>Sprache:<SPAN STYLE="COLOR:RED"> *</SPAN></TD><TD><INPUT TYPE="TEXT" NAME="sprache" VALUE="$comicfelder[2]" SIZE=10></TD></TR>
	SelectBoxSingle("Sprachen", $comicfelder[2]);
	
	print qq~
	</TD></TR>
	<TR><TD>Serien-Nr.:</TD><TD><INPUT TYPE="TEXT" NAME="seriennr" VALUE="$comicfelder[3]" SIZE=3></TD></TR>
	<TR><TD>Serie von:</TD><TD><INPUT TYPE="TEXT" NAME="serie" VALUE="$comicfelder[4]" SIZE=3></TD></TR>
	<TR><TD>ISBN/Barcode-Nr.:</TD><TD><INPUT TYPE="TEXT" NAME="isbn" VALUE="$comicfelder[5]" SIZE=50></TD></TR>
	<TR><TD>Verlag:</TD><TD><INPUT TYPE="TEXT" NAME="verlag" VALUE="$comicfelder[6]" SIZE=50></TD></TR>
	<TR><TD>Erstauflage:</TD><TD><INPUT TYPE="TEXT" NAME="erstauflage" VALUE="$comicfelder[7]" SIZE=10></TD></TR>
	<TR><TD>Kaufdatum:</TD><TD><INPUT TYPE="TEXT" NAME="kaufdatum" VALUE="$comicfelder[8]" SIZE=10></TD></TR>
	<TR><TD>Originalpreis:</TD><TD><INPUT TYPE="TEXT" NAME="originalpreis" VALUE="$comicfelder[9]" SIZE=9></TD></TR>
	<TR><TD>Einkaufspreis:</TD><TD><INPUT TYPE="TEXT" NAME="einkaufspreis" VALUE="$comicfelder[10]" SIZE=9></TD></TR>
	<TR><TD>akt. Handelspreis:</TD><TD><INPUT TYPE="TEXT" NAME="handelspreis" VALUE="$comicfelder[11]" SIZE=9></TD></TR>
	<TR><TD>H&auml;ndler:</TD><TD><INPUT TYPE="TEXT" NAME="haendler" VALUE="$comicfelder[12]" SIZE=50></TD></TR>
	<TR><TD>Bemerkung 1:</TD><TD><TEXTAREA NAME="bem1" COLS=100 ROWS=5>$comicfelder[13]</TEXTAREA></TD></TR>
	<TR><TD>URL:</TD><TD><INPUT TYPE="TEXT" NAME="url" VALUE="$comicfelder[14]" SIZE=100></TD></TR>
	<TR><TD>Autor(en):</TD><TD><INPUT TYPE="TEXT" NAME="autoren" VALUE="$comicfelder[15]" SIZE=100></TD></TR>
	<TR><TD>Zustand:</TD><TD><INPUT TYPE="TEXT" NAME="zustand" VALUE="$comicfelder[16]" SIZE=50></TD></TR>
	<TR><TD>Eigenschaften:</TD><TD><INPUT TYPE="TEXT" NAME="eigenschaften" VALUE="$comicfelder[17]" SIZE=100></TD></TR>
	<TR><TD>Bewertung:</TD><TD><INPUT TYPE="TEXT" NAME="bewertung" VALUE="$comicfelder[18]" SIZE=20></TD></TR>
	<TR><TD>Status:<SPAN STYLE="COLOR:RED"> *</SPAN></TD><TD><INPUT TYPE="TEXT" NAME="status" VALUE="$comicfelder[19]" SIZE=20></TD></TR>
	<TR><TD>Darsteller:</TD><TD><INPUT TYPE="TEXT" NAME="darsteller" VALUE="$comicfelder[20]" SIZE=100></TD></TR>
	<TR><TD>Einbandart:</TD><TD><INPUT TYPE="TEXT" NAME="einbandart" VALUE="$comicfelder[21]" SIZE=100></TD></TR>
	<TR><TD>Format:</TD><TD><INPUT TYPE="TEXT" NAME="format" VALUE="$comicfelder[22]" SIZE=100></TD></TR>
	<TR><TD>Genre:</TD><TD><INPUT TYPE="TEXT" NAME="genre" VALUE="$comicfelder[23]" SIZE=100></TD></TR>
	<TR><TD>Bemerkung 2:</TD><TD><TEXTAREA NAME="bem2" COLS=100 ROWS=5>$comicfelder[24]</TEXTAREA></TD></TR>
	<TR><TD>Exemplare:</TD><TD><INPUT TYPE="TEXT" NAME="exemplare" VALUE="$comicfelder[25]" SIZE=3></TD></TR>
	<TR><TD>Lagerort:</TD><TD><INPUT TYPE="TEXT" NAME="lagerort" VALUE="$comicfelder[26]" SIZE=50></TD></TR>
	<TR><TD>Statushinweis:</TD><TD><INPUT TYPE="TEXT" NAME="statushinweis" VALUE="$comicfelder[27]" SIZE=20></TD></TR>
	<TR><TD>Heft-Verweise:</TD><TD><INPUT TYPE="TEXT" NAME="heftverweise" VALUE="$comicfelder[28]" SIZE=100></TD></TR>
	<TR><TD>Seiten:</TD><TD><INPUT TYPE="TEXT" NAME="seiten" VALUE="$comicfelder[29]" SIZE=3></TD></TR>
	<TR><TD>Inhalt/Geschichte:</TD><TD><TEXTAREA NAME="inhaltgesch" COLS=100 ROWS=5>$comicfelder[30]</TEXTAREA></TD></TR>
	<TR><TD>Rezensionen:</TD><TD><INPUT TYPE="TEXT" NAME="rezensionen" VALUE="$comicfelder[31]" SIZE=100></TD></TR>
	<TR><TD>Inhaltsbewertung:</TD><TD><INPUT TYPE="TEXT" NAME="inhaltsbewertung" VALUE="$comicfelder[32]" SIZE=50></TD></TR>
	<TR><TD>Handelspreise:</TD><TD><INPUT TYPE="TEXT" NAME="handelspreise" VALUE="$comicfelder[33]" SIZE=100></TD></TR>
	<TR><TD>Comic-Typ:</TD><TD><INPUT TYPE="TEXT" NAME="comictyp" VALUE="$comicfelder[34]" SIZE=20></TD></TR>
	<TR><TD>Autor(en) + Job:</TD><TD><INPUT TYPE="TEXT" NAME="autorenjob" VALUE="$comicfelder[35]" SIZE=100></TD></TR>
	<TR><TD>Enthalten in:</TD><TD><INPUT TYPE="TEXT" NAME="enthaltenin" VALUE="$comicfelder[36]" SIZE=100></TD></TR>
	<TR><TD>Link zum Cover:</TD><TD><INPUT TYPE="TEXT" NAME="coverlink" VALUE="$comicfelder[37]" SIZE=100></TD></TR>
	</TABLE>
	<P>
	<INPUT TYPE="submit" NAME="speichern" VALUE="sichern" onfocus="this.form.speichern.value='speichern'"><BR/>
	</FORM>
	~;
	

if ($knopf =~ "speichern")	# wenn User auf speichern klickt, dann Datensatz an vorhandene Datei anhängen
{
	
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

	my $csvdatei = "../data/$verzeichnis/hefte.txt";
	# zur Datensicherung wird die Kopie der original CSV-Datei mit einem vorangestellten Zeitstempel versehen
	my $kopie_datei = "../data/$verzeichnis/$jjjj-$mm-$tt\_$std$min$sec\_hefte.txt";
	
	# Die Originaldatei vor der Manipulation sichern
	if (-e $csvdatei)
	{
		# die csv-Datei existiert und soll somit zur Sicherung kopiert werden
		copy ($csvdatei, $kopie_datei) || die "Kopieren von $csvdatei ging schief: $!\n";
		
		my $zeile;	# Variable für die Aufnahme des String, der als Ergebnis in die CSV-Datei geschrieben wird
		# in der kommenden for-Schleife werden die einzelnen Felder mit umchließenden "" zu einem String zusammen gefügt
		my $i;	
		for $i (0..$#comicfelder)
		{
			if ($i == 0)	# beim ersten Feld darf kein vorangestelltes Komma ausgegeben werden
			{
				$zeile = $zeile . "\"" . $comicfelder[$i] . "\"";
			}
			else			# bei allen nachfolgenden Feldern ist ein Komma gewünscht
			{
				$zeile = $zeile . ",\"" . $comicfelder[$i] . "\"";
			}	
		}
		
		open (DATEI, ">>", $csvdatei) or die "Fehler beim Schreiben von $csvdatei: $?\n";	# kompletten String an die CSV-Datei anhängen.
		print DATEI $zeile ."\n";
		close (DATEI);
		
		my $log_string = "$jjjj-$mm-$tt\_$std$min$sec; NEUES HEFT; Verzeichnis: $verzeichnis; Titel: $comicfelder[0]; Untertitel: $comicfelder[1]; Serie-Nr.: $comicfelder[3]";
		SchreibeLog($log_string);
	}
	else
	{
		print "$csvdatei nicht gefunden.\n";
	}
	

}

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

sub SchreibeLog
{
	my ($log_meldung) = @_;
	my $logdatei = "../logs/edit_log.txt";
	open (LOGDATEI, ">>", $logdatei) or die "Fehler beim Schreiben von $logdatei: $?\n";
	print LOGDATEI "$log_meldung\n";
	close (LOGDATEI);
}

# Erzeugt eine Auswahlbox mit max. einem vorselektierten Eintrag
sub SelectBoxSingle	# ($schluessel, $vorgabe)
{
	my ($schluessel, $vorgabe) = @_;
	
	my $aref_felder = $felder{$schluessel};		# anzahl der Felder im
	my $anz = $#$aref_felder + 1;				# Array des Hash ermitteln	
	
	print "<SELECT NAME=\"$schluessel\" SIZE=\"$anz\">\n";
	foreach (@{$felder{$schluessel}})
	{
		if ($_ eq $vorgabe)
		{
			print "<OPTION SELECTED>$_\n";		# Wert wird hervorgehoben dargestellt
		}
		else
		{
			print "<OPTION>$_\n";				# Wert ohne Hervorhebung
		}
	}
	print "</SELECT>\n";
}

exit;