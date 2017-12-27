#!C:\strawberry\perl\bin\perl

#-----------------------------------------------------------------------------------------------------------
# Dieses Skript listet die Einstellungen der Comic-Verwaltungssoftware auf.
#
# Stand: 2013-06-16
#
# Historie:
#-----------------------------------------------------------------------------------------------------------

use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser);	# Umleitung von Fehlermeldungen in den Browser

InsertHeader("Auflistung der Einstellungen und Vorgabewerte");		# Beginn des HTML-Dokuments

my %felder = LeseConfig();	# Konfigurationsdaten d.h. Vorgabefelder aus Datei einlesen

my $k;
my $v;

while ( ($k,$v) = each %felder )	# Hash aus Arrays ausgeben, erst alle Schlüssel...
{
    #print "$k => $v\n";
    print "<h1>$k</h1>\n";
    print "<ul>\n";
    foreach(@$v)					# ...dann die Arrayeinträge.
    {
    	print "<li>$_</li>\n";
    }
    print "</ul>\n";
}

# TODO Einstellungen editierbar machen und nicht nur auflisten


InsertTrailer();				# Ende des HTML-Dokuments

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
	print "<h2> Comic Einstellungen </h2>";
	print "<h1> $htmltitle </h1>";
	print '<TABLE BORDER="0" bgcolor="yellow" CELLPADDING="3" CELLSPACING="1" width=100%>',"\n";
	print "<TR><TD style=\"height:22px\"></TD></TR>\n";
	print "</TABLE><BR />\n";
}

sub InsertTrailer
{
	# HTML-Nachspann ausgeben
	print "</BODY>\n</HTML>\n";
}

exit;