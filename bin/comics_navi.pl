#!C:\strawberry\perl\bin\perl

use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser);	# Umleitung von Fehlermeldungen in den Browser

my $version = "2015-01-10";
my $autor = "V. Thomas";

my $graphpfad = "../graphics/";

InsertHeader("Comics Navi");

print '<TABLE WIDTH="100%" BORDER="0" CELLPADDING="3" CELLSPACING="1">',"\n";	# Beginn der Tabelle
# print "<TH>Funktionen</TH><TH>Links</TH>\n";
print "<TR VALIGN=\"top\"><TD WIDTH=\"50%\">\n";
print "<UL>\n";
print "<LI><a href=\"./sammlungsliste.pl\" target=\"_blank\">Liste aller Sammlungen</a></LI>\n";
print "</UL>\n";
print "<UL>\n";
print "<LI><a href=\"./durchsuche\_index.pl\" target=\"_blank\">Suche</a></LI>\n";
print "<LI><a href=\"./erstelle\_index.pl\" target=\"_blank\">Index erstellen bzw. aktualisieren</a></LI>\n";
print "<LI><a href=\"./sammlung\_neu.pl\" target=\"_blank\">neue Sammlung</a></LI>\n";
print "</UL>";
print "<UL>\n";
print "<LI><a href=\"./hole_bilder.pl\" target=\"_blank\">Cover & Leseproben aus Internet downloaden</a></LI>\n";
print "</UL>";
print "<UL>\n";
print "<LI><a href=\"./einstellungen.pl\" target=\"_blank\">Einstellungen anzeigen</a> <IMG TITLE=\"Einstellungen\" ALT=\"Einstellungen\" SRC=\"$graphpfad/gear.png\" WIDTH=\"16\" HEIGHT=\"16\"></LI>\n";
print "</UL>";
print "</TD>";
print "<TD>\n";
print "<UL>\n";
print "<LI><IMG TITLE=\"Deutscher Comic Guide\" ALT=\"Deutscher Comic Guide\" SRC=\"$graphpfad/comic_guide.ico\" WIDTH=\"16\" HEIGHT=\"16\">  <a href=\"http://www.comicguide.de\" target=\"_blank\">Comic Guide</a></LI>\n";
print "</UL>\n";
print "<UL>\n";
print "<LI><IMG TITLE=\"Bunte Dimensionen\" ALT=\"Bunte Dimensionen\" SRC=\"$graphpfad/bunte_dimensionen.png\" WIDTH=\"16\" HEIGHT=\"16\">  <a href=\"http://www.bunte-dimensionen.de/\" target=\"_blank\">Bunte Dimensionen</a></LI>\n";
print "<LI><IMG TITLE=\"Carlsen Comics\" ALT=\"Carlsen Comics\" SRC=\"$graphpfad/carlsen.ico\" WIDTH=\"16\" HEIGHT=\"16\">  <a href=\"http://www.carlsen.de/web/comic/index\" target=\"_blank\">Carlsen Comics</a></LI>\n";
print "<LI><IMG TITLE=\"comic+\" ALT=\"Comicplus\" SRC=\"$graphpfad/comicplus.gif\" HEIGHT=\"16\">  <a href=\"http://www.comicplus.de\" target=\"_blank\">comic+</a></LI>\n";
print "<LI><IMG TITLE=\"Cross Cult\" ALT=\"Cross Cult\" SRC=\"$graphpfad/cross-cult.ico\" WIDTH=\"16\" HEIGHT=\"16\">  <a href=\"http://www.cross-cult.de\" target=\"_blank\">Cross Cult</a></LI>\n";
print "<LI><IMG TITLE=\"Egmont Comic Collection\" ALT=\"Egmont Comic Collection\" SRC=\"$graphpfad/ehapa.ico\" WIDTH=\"16\" HEIGHT=\"16\">  <a href=\"http://www.ehapa-comic-collection.de\" target=\"_blank\">Ehapa Comic Collection</a></LI>\n";
print "<LI><IMG TITLE=\"EPSiLON\" ALT=\"EPSiLON\" SRC=\"$graphpfad/epsilon.ico\" WIDTH=\"16\" HEIGHT=\"16\">  <a href=\"http://www.epsilongrafix.de\" target=\"_blank\">Epsilon</a></LI>\n";
print "<LI><IMG TITLE=\"Finix\" ALT=\"Finix\" SRC=\"$graphpfad/finix.ico\" WIDTH=\"16\" HEIGHT=\"16\">  <a href=\"http://www.finix-comics.de\" target=\"_blank\">Finix Comics</a></LI>\n";
print "<LI><IMG TITLE=\"Kult Editionen\" ALT=\"Kult Editionen\" SRC=\"$graphpfad/kult.ico\" WIDTH=\"16\" HEIGHT=\"16\">  <a href=\"http://www.kult-editionen.de\" target=\"_blank\">Kult Editionen</a></LI>\n";
print "<LI><IMG TITLE=\"Panini Comics\" ALT=\"Panini Comics\" SRC=\"$graphpfad/panini.ico\" WIDTH=\"16\" HEIGHT=\"16\">  <a href=\"http://www.paninicomics.de\" target=\"_blank\">Panini Comics</a></LI>\n";
print "<LI><IMG TITLE=\"Piredda Verlag\" ALT=\"Piredda Verlag\" SRC=\"$graphpfad/piredda.ico\" WIDTH=\"16\" HEIGHT=\"16\">  <a href=\"http://www.piredda-verlag.de\" target=\"_blank\">Piredda Verlag</a></LI>\n";
print "<LI><IMG TITLE=\"Salleck Publications\" ALT=\"Salleck Publications\" SRC=\"$graphpfad/salleck.ico\" WIDTH=\"16\" HEIGHT=\"16\">  <a href=\"http://www.salleck-publications.de/\" target=\"_blank\">Salleck Publications</a></LI>\n";
print "<LI><IMG TITLE=\"Splitter Verlag\" ALT=\"Splitter Verlag\" SRC=\"$graphpfad/splitter.ico\" WIDTH=\"16\" HEIGHT=\"16\">  <a href=\"http://www.splitter-verlag.eu\" target=\"_blank\">Splitter Verlag</a></LI>\n";
print "</UL>";
print "</TD></TR></TABLE>\n";


InsertTrailer();

exit;

sub InsertHeader
{
	# HTTP-Header und HTML-Vorspann ausgeben
	my ($htmltitle) = @_;
	print "Content-type: text/html\n\n";
	print "<HTML>\n<HEAD>\n";
	print "<link rel=\"icon\" type=\"image\/x-icon\" href=\"../graphics/favicon.ico\" />" . "\n";
	print "<link rel=\"shortcut icon\" href=\"../graphics/favicon.ico\" type=\"image\/x-icon\" />" . "\n";
	print "<TITLE> $htmltitle </TITLE>\n</HEAD>\n";
	print "<BODY>";
	print "<h2> Comic Startseite </h2>";
	print "<h1> $htmltitle </h1>";
	print '<TABLE BORDER="0" bgcolor="#FF0080" CELLPADDING="3" CELLSPACING="1" width=100%>',"\n";
	print "<TR><TD style=\"height:22px\"></TD></TR>\n";
	print "</TABLE><BR />\n";
}

sub InsertTrailer
{
	# HTML-Nachspann ausgeben
	print "<HR>\n";
	print "&copy; $autor; Software vom: $version\n";
	print "</BODY>\n</HTML>\n";
}