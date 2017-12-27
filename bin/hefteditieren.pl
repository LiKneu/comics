#!C:\strawberry\perl\bin\perl

#------------------------------------------------------------------------------
# Skript:			hefteditieren.pl
# Aufruf durch: 	seriezeigen.pl, comicdetails.pl
#
# Übergabeparameter:
# Verzeichnis - um Sammlung zu identifizieren
# Datensatz   - um Zeilen-Nr. im CSV-Datei zu identifizieren
# Aktion      - um Neuanlage, Editieren und Speichern zu unterscheiden
#
# Dieses Skript stellt eine Eingabemaske für das Editieren eines Einzelheftes
# bereit.
# 
# Die unveränderte Originaldatei mit den Heften wird im Dateinamen mit dem
# Tagesdatum versehen und als Backup abgespeichert.
#------------------------------------------------------------------------------

# Aufbau der Comic Keeper CSV-Datei:
# Heft-Titel,Heft-Untertitel,Sprache,Serien-Nr.,Serie von,ISBN/Barcode-Nr.,Verlag,Erstauflage,Kaufdatum,Originalpreis,Einkaufspreis,Akt. Handelspreis,Händler,Bemerkung 1,URL,Autor(en),Zustand,Eigenschaft(en),Bewertung,Status,Darsteller,Einbandart,Format,Genre,Bemerkung 2,Exemplare,Lagerort,Statushinweis,Heft-Verweise,Seiten,Inhalt/Geschichte,Rezensionen,Inhaltsbewertung,Handelspreise,Comic-Typ,Autor(en) + Job,Enthalten in

use strict;
use warnings;
use Text::CSV;
use File::Copy;
use CGI::Carp qw(fatalsToBrowser);

$| = 1;

my $HOMEURL="./";						# Pfad ins Skripteverzeichnis
my $script_url = $ENV{'SCRIPT_NAME'}; 	# Name des Programms

my %FORM = ();

# Formulareingabe parsen (d.h. auswerten)
ParseForm();

my @comicfelder = ($FORM{'titel'},
				   $FORM{'untertitel'},
				   $FORM{'Sprache'},
				   $FORM{'seriennr'},
				   $FORM{'serie'},
				   $FORM{'isbn'},
				   $FORM{'verlag'},
				   $FORM{'erstauflage'},
				   $FORM{'kaufdatum'},
				   $FORM{'originalpreis'},
				   $FORM{'einkaufspreis'},
				   $FORM{'handelspreis'},
				   $FORM{'Haendler'},
				   $FORM{'bem1'},
				   $FORM{'url'},
				   $FORM{'autoren'},
				   $FORM{'Zustand'},
				   $FORM{'Eigenschaften'},
				   $FORM{'Bewertung'},
				   $FORM{'Status'},
				   $FORM{'darsteller'},
				   $FORM{'Einbandart'},
				   $FORM{'Format'},
				   $FORM{'Genre'},
				   $FORM{'bem2'},
				   $FORM{'exemplare'},
				   $FORM{'Lagerort'},
				   $FORM{'statushinweis'},
				   $FORM{'heftverweise'},
				   $FORM{'seiten'},
				   $FORM{'inhaltgesch'},
				   $FORM{'rezensionen'},
				   $FORM{'Inhaltsbewertung'},
				   $FORM{'handelspreise'},
				   $FORM{'comictyp'},
				   $FORM{'autorenjob'},
				   $FORM{'enthaltenin'},
				   $FORM{'coverlink'});

my $verzeichnis = $FORM{'Verzeichnis'};
my $datensatz = $FORM{'Datensatz'};
my $aktion = $FORM{'speichern'};	# Aktion gibt an ob gespeichert werden soll

my $csvdatei = '../data/' . $verzeichnis . '/hefte.txt';	# CSV-Datei der Comics
my $tmpdatei = '../data/' . $verzeichnis . '/tmpdatei.txt';	# temporäre Datei mit dem ggf. geänderten Datensatz des Comics
my $coverpfad = "../data/$verzeichnis/cover/";				# Pfad zum Verzeichnis der Coverbilder
my $graphpfad = "../graphics/";
my @chg;	# change d.h. Änderung wurde vorgenommen
my @hefte;

my %felder = LeseConfig();	# Konfigurationsdaten d.h. Vorgabefelder aus Datei einlesen

InsertHeader("Heft editieren: $verzeichnis, $datensatz");		# Beginn des HTML-Dokuments

SammlungEinlesen($csvdatei);

# Für den Fall, dass während des Editierens der Felder einmal RETURN gedrückt wird, werden die Inhalte der Felder
# mit dem ursprünglichen Inhalt der CSV Datei verglichen und die geänderten Inhalte in ein neues Array geschrieben.
if ($aktion =~ "sichern")
{
	my $i;
	for $i (0..$#{$hefte[$datensatz]})
	{
		if ($comicfelder[$i] ne $hefte[$datensatz][$i])
		{
			$chg[$i] = $hefte[$datensatz][$i];
		}
	}	
}
elsif ($aktion =~ "speichern")
{
	SammlungSpeichern();
}
else	# sämtliche Feldinhalte werden aus der CSV-Datei eingelesen und angezeigt
{
	my $i;
	for $i (0..$#{$hefte[$datensatz]})
	{
		$comicfelder[$i] = $hefte[$datensatz][$i];
	}
}

# Entfernen von ggf. vorhandenen Zeilenumbrüchen wie z.B. \n \r aus den TEXTAREAS.
$comicfelder[13] =~ tr/\n|\r/ /s;
$comicfelder[24] =~ tr/\n|\r/ /s;
$comicfelder[30] =~ tr/\n|\r/ /s;

print "<h2>Heft editieren: Datensatz $datensatz von $#hefte</h2>";
print "<h1>Verzeichnis: <I>$verzeichnis</I></h1>";

print '<TABLE BORDER="0" bgcolor="#FF0000" CELLPADDING="3" CELLSPACING="1" width=100%>',"\n";
print '<TR align="center"><TD width="10%"><a href="./hefteditieren.pl?Verzeichnis=' . $verzeichnis . '&' . 'Datensatz=1"><IMG TITLE="erstes" ALT="erstes" SRC="' . $graphpfad . '/go_start.png" WIDTH="16" HEIGHT="16"></a></TD><TD width="10%"><a href="./hefteditieren.pl?Verzeichnis=' . $verzeichnis . '&' . 'Datensatz=' . ($datensatz - 1) .'"><IMG TITLE="zurück" ALT="zurück" SRC="' . $graphpfad . '/go_back.png" WIDTH="16" HEIGHT="16"></a></TD><TD></TD><TD width="10%"> <a href="./hefteditieren.pl?Verzeichnis=' . $verzeichnis . '&' . 'Datensatz=' . ($datensatz + 1) .'"><IMG TITLE="n&auml;chstes" ALT="n&auml;chstes" SRC="' . $graphpfad . '/go_forward.png" WIDTH="16" HEIGHT="16"></a> </TD><TD width="10%"> <a href="./hefteditieren.pl?Verzeichnis=' . $verzeichnis . '&' . 'Datensatz=' . $#hefte .'"><IMG TITLE="letztes" ALT="letztes" SRC="' . $graphpfad . '/go_end.png" WIDTH="16" HEIGHT="16"></a> </TD></TR>' . "\n";
print '</TABLE>' . "\n";

ShowCover();
ShowForm();
InsertTrailer();				# Ende des HTML-Dokuments

# Cover anzeigen
sub ShowCover
{
	my $src;	# Text für IMG Tag
	my $alt;	# Text für IMG Tag
	my $keincover;	# Text für Fehlermeldung
	
	if ($comicfelder[37])	# prüfen ob schon ein Dateiname eingegeben wurde...
	{
		$alt = $comicfelder[37];			# ...ja - also Texte zuweisen
		$src = $coverpfad . $comicfelder[37];
	}
	else
	{
		$alt = "kein Coverbild zugeordnet";	# ...nein - also auf fehlende Informationen hinweisen
		$keincover = $alt;
		$src = "$graphpfad/kein_Cover.png"; 
	}
	print '<P><A HREF="' . $src . '"><IMG TITLE="' . $alt . '" ALT="' . $alt . '" SRC="' . $src . '" WIDTH="150"><BR /></A>' . $keincover . '</P>' . "\n";
}

sub ShowForm
{
	# HTML ausgeben
	print qq~
	<FORM ACTION="$ENV{'SCRIPT_NAME'}" METHOD="GET">	<!--- # POST (für große Datenmengen), GET (ist schneller als POST) -->
	<INPUT TYPE="HIDDEN" NAME="Verzeichnis" VALUE="$verzeichnis">
	<INPUT TYPE="HIDDEN" NAME="Datensatz" VALUE="$datensatz">
	<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="2">
	<TR><TD>Titel:<SPAN STYLE="COLOR:RED"> *</SPAN></TD><TD><INPUT TYPE="TEXT" NAME="titel" VALUE="$comicfelder[0]" SIZE=50></TD><TD><FONT COLOR="red">$chg[0]</FONT></TD></TR>
	<TR><TD>Untertitel:</TD><TD><INPUT TYPE="TEXT" NAME="untertitel" VALUE="$comicfelder[1]" SIZE=50></TD><TD><FONT COLOR="red">$chg[1]</FONT></TD></TR>
	<TR><TD>Sprache:<SPAN STYLE="COLOR:RED"> *</SPAN></TD><TD>
	~;
	
	SelectBoxSingle("Sprache", $comicfelder[2]);
	
	print qq~
	</TD><TD><FONT COLOR="red">$chg[2]</FONT></TD></TR>
	<TR><TD>Serien-Nr.:</TD><TD><INPUT TYPE="TEXT" NAME="seriennr" VALUE="$comicfelder[3]" SIZE=3></TD><TD><FONT COLOR="red">$chg[3]</FONT></TD></TR>
	<TR><TD>Serie von:</TD><TD><INPUT TYPE="TEXT" NAME="serie" VALUE="$comicfelder[4]" SIZE=3></TD><TD><FONT COLOR="red">$chg[4]</FONT></TD></TR>
	<TR><TD>ISBN/Barcode-Nr.:</TD><TD><INPUT TYPE="TEXT" NAME="isbn" VALUE="$comicfelder[5]" SIZE=50></TD><TD><FONT COLOR="red">$chg[5]</FONT></TD></TR>
	<TR><TD>Verlag:</TD><TD><INPUT TYPE="TEXT" NAME="verlag" VALUE="$comicfelder[6]" SIZE=50></TD><TD><FONT COLOR="red">$chg[6]</FONT></TD></TR>
	<TR><TD>Erstauflage:</TD><TD><INPUT TYPE="TEXT" NAME="erstauflage" VALUE="$comicfelder[7]" SIZE=10></TD><TD><FONT COLOR="red">$chg[7]</FONT></TD></TR>
	<TR><TD>Kaufdatum:</TD><TD><INPUT TYPE="TEXT" NAME="kaufdatum" VALUE="$comicfelder[8]" SIZE=10></TD><TD><FONT COLOR="red">$chg[8]</FONT></TD></TR>
	<TR><TD>Originalpreis:</TD><TD><INPUT TYPE="TEXT" NAME="originalpreis" VALUE="$comicfelder[9]" SIZE=9></TD><TD><FONT COLOR="red">$chg[9]</FONT></TD></TR>
	<TR><TD>Einkaufspreis:</TD><TD><INPUT TYPE="TEXT" NAME="einkaufspreis" VALUE="$comicfelder[10]" SIZE=9></TD><TD><FONT COLOR="red">$chg[10]</FONT></TD></TR>
	<TR><TD>akt. Handelspreis:</TD><TD><INPUT TYPE="TEXT" NAME="handelspreis" VALUE="$comicfelder[11]" SIZE=9></TD><TD><FONT COLOR="red">$chg[11]</FONT></TD></TR>
	<TR><TD>H&auml;ndler:</TD><TD><INPUT TYPE="TEXT" NAME="Haendler" VALUE="$comicfelder[12]" SIZE=50></TD><TD><FONT COLOR="red">$chg[12]</FONT></TD></TR>
	<TR><TD>Bemerkung 1:</TD><TD><TEXTAREA NAME="bem1" COLS=100 ROWS=5>$comicfelder[13]</TEXTAREA></TD><TD><FONT COLOR="red">$chg[13]</FONT></TD></TR>
	<TR><TD>URL:</TD><TD><INPUT TYPE="TEXT" NAME="url" VALUE="$comicfelder[14]" SIZE=100></TD><TD><FONT COLOR="red">$chg[14]</FONT></TD></TR>
	<TR><TD>Autor(en):</TD><TD><INPUT TYPE="TEXT" NAME="autoren" VALUE="$comicfelder[15]" SIZE=100></TD><TD><FONT COLOR="red">$chg[15]</FONT></TD></TR>
	<TR><TD>Zustand:</TD><TD><INPUT TYPE="TEXT" NAME="Zustand" VALUE="$comicfelder[16]" SIZE=50>
	~;
	
	# CheckBox("Zustand", $comicfelder[16]);
	
	print qq~
	</TD><TD><FONT COLOR="red">$chg[16]</FONT></TD></TR>
	<TR><TD>Eigenschaften:</TD><TD><INPUT TYPE="TEXT" NAME="Eigenschaften" VALUE="$comicfelder[17]" SIZE=100>
	~;
	 
	#CheckBox("Eigenschaften", $comicfelder[17]);
	
	print qq~
	</TD><TD><FONT COLOR="red">$chg[17]</FONT></TD></TR>
	<TR><TD>Bewertung:</TD><TD>
	~;
	
	# <INPUT TYPE="TEXT" NAME="Bewertung" VALUE="$comicfelder[18]" SIZE=20>
	SelectBoxSingle("Bewertung", $comicfelder[18]);
	
	print qq~
	</TD><TD><FONT COLOR="red">$chg[18]</FONT></TD></TR>
	<TR><TD>Status:<SPAN STYLE="COLOR:RED"> *</SPAN></TD><TD>
	~;
	
	# <INPUT TYPE="TEXT" NAME="Status" VALUE="$comicfelder[19]" SIZE=20>
	SelectBoxSingle("Status", $comicfelder[19]);
	
	print qq~
	</TD><TD><FONT COLOR="red">$chg[19]</FONT></TD></TR>
	<TR><TD>Darsteller:</TD><TD><INPUT TYPE="TEXT" NAME="darsteller" VALUE="$comicfelder[20]" SIZE=100></TD><TD><FONT COLOR="red">$chg[20]</FONT></TD></TR>
	<TR><TD>Einbandart:</TD><TD>
	~;
	
	# <INPUT TYPE="TEXT" NAME="Einbandart" VALUE="$comicfelder[21]" SIZE=100>
	SelectBoxSingle("Einbandart", $comicfelder[21]);
	
	print qq~
	</TD><TD><FONT COLOR="red">$chg[21]</FONT></TD></TR>
	<TR><TD>Format:</TD><TD>
	~;
	
	#<INPUT TYPE="TEXT" NAME="Format" VALUE="$comicfelder[22]" SIZE=100>
	SelectBoxSingle("Format", $comicfelder[22]);
	
	print qq~
	</TD><TD><FONT COLOR="red">$chg[22]</FONT></TD></TR>
	<TR><TD>Genre:</TD><TD>
	~;
	
	# <INPUT TYPE="TEXT" NAME="Genre" VALUE="$comicfelder[23]" SIZE=100>
	SelectBoxSingle("Genre", $comicfelder[23]);
	
	print qq~
	</TD><TD><FONT COLOR="red">$chg[23]</FONT></TD></TR>
	<TR><TD>Bemerkung 2:</TD><TD><TEXTAREA NAME="bem2" COLS=100 ROWS=5>$comicfelder[24]</TEXTAREA></TD><TD><FONT COLOR="red">$chg[24]</FONT></TD></TR>
	<TR><TD>Exemplare:</TD><TD><INPUT TYPE="TEXT" NAME="exemplare" VALUE="$comicfelder[25]" SIZE=3></TD><TD><FONT COLOR="red">$chg[25]</FONT></TD></TR>
	<TR><TD>Lagerort:</TD><TD>
	~;
	
	# <INPUT TYPE="TEXT" NAME="Lagerort" VALUE="$comicfelder[26]" SIZE=50>
	SelectBoxSingle("Lagerort", $comicfelder[26]);
	
	print qq~
	</TD><TD><FONT COLOR="red">$chg[26]</FONT></TD></TR>
	<TR><TD>Statushinweis:</TD><TD><INPUT TYPE="TEXT" NAME="statushinweis" VALUE="$comicfelder[27]" SIZE=20></TD><TD><FONT COLOR="red">$chg[27]</FONT></TD></TR>
	<TR><TD>Heft-Verweise:</TD><TD><INPUT TYPE="TEXT" NAME="heftverweise" VALUE="$comicfelder[28]" SIZE=100></TD><TD><FONT COLOR="red">$chg[28]</FONT></TD></TR>
	<TR><TD>Seiten:</TD><TD><INPUT TYPE="TEXT" NAME="seiten" VALUE="$comicfelder[29]" SIZE=3></TD><TD><FONT COLOR="red">$chg[29]</FONT></TD></TR>
	<TR><TD>Inhalt/Geschichte:</TD><TD><TEXTAREA NAME="inhaltgesch" COLS=100 ROWS=5>$comicfelder[30]</TEXTAREA></TD><TD><FONT COLOR="red">$chg[30]</FONT></TD></TR>
	<TR><TD>Rezensionen:</TD><TD><INPUT TYPE="TEXT" NAME="rezensionen" VALUE="$comicfelder[31]" SIZE=100></TD><TD><FONT COLOR="red">$chg[31]</FONT></TD></TR>
	<TR><TD>Inhaltsbewertung:</TD><TD>
	~;
	
	#<INPUT TYPE="TEXT" NAME="Inhaltsbewertung" VALUE="$comicfelder[32]" SIZE=50>
	SelectBoxSingle("Inhaltsbewertung", $comicfelder[32]);
	
	print qq~
	</TD><TD><FONT COLOR="red">$chg[32]</FONT></TD></TR>
	<TR><TD>Handelspreise:</TD><TD><INPUT TYPE="TEXT" NAME="handelspreise" VALUE="$comicfelder[33]" SIZE=100></TD><TD><FONT COLOR="red">$chg[33]</FONT></TD></TR>
	<TR><TD>Comic-Typ:</TD><TD><INPUT TYPE="TEXT" NAME="comictyp" VALUE="$comicfelder[34]" SIZE=20></TD><TD><FONT COLOR="red">$chg[34]</FONT></TD></TR>
	<TR><TD>Autor(en) + Job:</TD><TD><INPUT TYPE="TEXT" NAME="autorenjob" VALUE="$comicfelder[35]" SIZE=100></TD><TD><FONT COLOR="red">$chg[35]</FONT></TD></TR>
	<TR><TD>Enthalten in:</TD><TD><INPUT TYPE="TEXT" NAME="enthaltenin" VALUE="$comicfelder[36]" SIZE=100></TD><TD><FONT COLOR="red">$chg[36]</FONT></TD></TR>
	<TR><TD>Link zum Cover:</TD><TD><INPUT TYPE="TEXT" NAME="coverlink" VALUE="$comicfelder[37]" SIZE=100></TD><TD><FONT COLOR="red">$chg[37]</FONT></TD></TR>
	</TABLE>
	<P>
	<INPUT TYPE="submit" NAME="speichern" VALUE="sichern" onfocus="this.form.speichern.value='speichern'"><BR/>
	</FORM>	
	~;
}

# Einlesen der CSV-Datei mit den Datensätzen der in der Sammlung enthaltenen Hefte
sub SammlungEinlesen
{
	my @tmp;
	open (SAMMLUNG, "<", @_) or die "Fehler beim Öffnen von @_: $?\n";
	flock(SAMMLUNG, 2);	# Datei für exklusiven Zugriff sperren
	while (my $line = <SAMMLUNG>)
	{
		@tmp = split_string($line);
		push (@hefte ,[@tmp]);
	}
	flock(SAMMLUNG, 8);	# Datei wieder freigeben
	close(SAMMLUNG);
}

# Speichern der CSV-Datei mit den Datensätzen der Sammlung
sub SammlungSpeichern
{
	# alte CSV-Datei sichern
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
		
		# Alte CSV-Datei einlesen und alle Datensätze, die nicht geändert wurden gleich in eine temporäre Datei schreiben.
		# Wenn die Schleife auf den neuen Datensatz stößt, dann diesen in die temporäre Datei schreiben und Original übergehen
		open (TMPDATEI, ">", $tmpdatei) or die "Fehler beim Schreiben von $tmpdatei: $?\n";
		open (CSVDATEI, "<", $csvdatei) or die "Fehler beim Lesen von $csvdatei: $?\n";
		my $j = 0;
		while (my $line = <CSVDATEI>)
		{
			if($j == 0)
			{
				# Spaltenüberschriften immer neu schreiben, da ggf. die Spalte mit dem Cover-Link nicht vorhanden
				print TMPDATEI "Heft-Titel,Heft-Untertitel,Sprache,Serien-Nr.,Serie von,ISBN/Barcode-Nr.,Verlag,Erstauflage,Kaufdatum,Originalpreis,Einkaufspreis,Akt. Handelspreis,Händler,Bemerkung 1,URL,Autor(en),Zustand,Eigenschaft(en),Bewertung,Status,Darsteller,Einbandart,Format,Genre,Bemerkung 2,Exemplare,Lagerort,Statushinweis,Heft-Verweise,Seiten,Inhalt/Geschichte,Rezensionen,Inhaltsbewertung,Handelspreise,Comic-Typ,Autor(en) + Job,Enthalten in,Link zum Cover" . "\n";
			}
			elsif ($j == $datensatz)
			{
				print TMPDATEI $zeile . "\n";
			}
			else
			{
				print TMPDATEI $line;
			}
			$j++;
		}
		close (CSVDATEI);
		close (TMPDATEI);
		unlink ($csvdatei);				# alte CSV-Datei löschen
		rename ($tmpdatei, $csvdatei);	# temporäre Datei mit geändertem Datensatz in CSV-Datei umbenennen
		
		# Log-Datei schreiben
		my $log_string = "$jjjj-$mm-$tt\_$std$min$sec; HEFT EDITIERT; Verzeichnis: $verzeichnis; Datensatz: $datensatz; Serie-Nr.: $comicfelder[3]";
		SchreibeLog($log_string);
	}
	else
	{
		print "$csvdatei nicht gefunden.\n";
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

# Einzelne Zeile der CSV-Datei in ihre Felder zerlegen und im Array @new zurückliefern
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

# In URL übergebenen String in Paare eines Hash aufteilen und im globalen Hash FORM abspeichern
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

# Erzeugt eine Auswahlbox mit max. einem vorselektierten Eintrag
sub SelectBoxSingle	# ($schluessel, $vorgabe)
{
	my ($schluessel, $vorgabe) = @_;
	
	my $aref_felder = $felder{$schluessel};		# anzahl der Felder im
	my $anz = $#$aref_felder + 1;				# Array des Hash ermitteln	
	
	print "<SELECT NAME=\"$schluessel\" SIZE=\"$anz\">\n";	# SelectBox ist so hoch wie es Einträge gibt
	# print "<SELECT NAME=\"$schluessel\" SIZE=\"1\">\n";		# SelectBox ist nur einen Eintrag hoch
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

# Erzeugt ein Feld mit Checkboxen bei denen mehrere Ausgewählt d.h. angehakt sein können
sub CheckBox
{
	my ($schluessel, @angehakt) = @_;
	
	my $br = 0;		# Es sollen 5 Checkboxen untereinander angeordnet werden. Hierführ wird der Zähler $br benötigt
	
	print '<TABLE BORDER="0" CELLPADDING="3" CELLSPACING="1">',"\n";
	print "<TR VALIGN=\"top\"><TD>\n";
	
	foreach (@{$felder{$schluessel}})
	{
		my $wert = $_;
		my $haken = 0;
		foreach (@angehakt)		# für jedes Feld aus dem Array prüfen der angehakten Werte
		{						# ob es in der Web-Oberfläche angehakt wurde...
			if ($_ eq $wert)
			{
				$haken = 1;		# ...wenn ja, dann Haken setzen...
			}
		}
		if ($haken)
		{
			# ...und in der Web-Oberfläche ausgeben.
			print "<INPUT TYPE=\"checkbox\" NAME=\"$schluessel\" VALUE=\"$wert\" CHECKED=\"checked\"> $wert<BR />\n";
		}
		else
		{
			# ...andernfalls nur die Auswahl ohne Haken zur Auswahl stellen.
			print "<INPUT TYPE=\"checkbox\" NAME=\"$schluessel\" VALUE=\"$wert\"> $wert <BR />\n";
		}
		$br ++;
		if ($br == 5)
		{
			print "</TD><TD>\n";
			$br = 0;
		}		
	}
	print "</TD></TR></TABLE>\n";
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
	print "</BODY>\n</HTML>\n";
}

exit;