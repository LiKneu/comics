use strict;
use Text::CSV;

# Array nach Fundstellen f�r einen String durchsuchen
# Eingabe : <Suchstring>, <Array mit zu durchsuchenden Feldern>
# R�ckgabe: <Anzahl der Fundstellen>, <Array mit den Nr. der Felder mit Funden>
sub DatenInArraySuchen
{
	my ($suchstring, $daten_z, $indexvorgabe_z) = @_;
	
	my @ergebnis;		# Array f�r die R�ckgabe der Feldnummern mit Fundstellen
	my $zaehler = 0;	# Z�hler f�r Fundstellen (0 bei keiner Fundstelle)


	
	my $feldindex = 0;	# Nummer des Feldes

	foreach (@$daten_z)
	{
		my $feld = $_;

		# Merker ob aktuelles Feld zu den zu durchsuchenden Feldern geh�rt
		my $durchsuchen = 0;	# 0 = nein, 1 = ja
		
		foreach(@$indexvorgabe_z)
		{
			if ($feldindex == $_ || $_ == 999)
			{
				my $tmpzeile = lc($feld);	# alles in Kleinbuchstaben
				$tmpzeile =~ s/�/�/gs;		# �,�,� wird von lc() nicht behandelt
				$tmpzeile =~ s/�/�/gs;
				$tmpzeile =~ s/�/�/gs;
				
				$suchstring = lc($suchstring);	# alles in Kleinbuchstaben
				$suchstring =~ s/�/�/gs;		# �,�,� wird von lc() nicht behandelt
				$suchstring =~ s/�/�/gs;
				$suchstring =~ s/�/�/gs;
					 
				if ($tmpzeile =~ m/$suchstring/)
				{
					push @ergebnis, $feldindex;
					$zaehler++;			
				}				
			}
		}
		$feldindex++;
	}

	if($zaehler)	# wenn $zaehler ungleich NULL, dann Fundstelle vorhanden
	{
		return($zaehler, @ergebnis);	# Fundstelle(n)
	}
	else
	{
		return(0);	# keine Fundstelle
	}
}

# Semikolon separierten String in ein Array mit den jeweiligen Datenfeldern
# unterteilen.
# Eingabe : <Semikolon separierten String>
# R�ckgabe: <Array mit Datenfeldern>
sub split_string
{
	# Ein neues CSV-Objekt erzeugen
	my $csv = Text::CSV->new(
		{ binary 			=> 1,	# alle Codes erlaubt
	  	  eol    			=> $\,	# Newline betriebssystemspezifisch setzen
	  	  allow_whitespace 	=> 1,	# Leerzeichen zwischen den Feldern erlauben
	  	  quote_char		=> '"',	# Anf�hrungszeichen definieren
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

1;

__END__