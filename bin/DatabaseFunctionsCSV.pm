package DatabaseFunctionsCSV;

#-------------------------------------------------------------------------------
#   Package holds functions needed to handle comic book information stored
#   in CSV file hefte.txt
#-------------------------------------------------------------------------------

use strict;
use warnings;
use 5.24.0;

use Text::CSV qw( csv );
use Path::Tiny;

require Exporter;

our @ISA = qw ( Exporter );

our @EXPORT = qw (
    get_series_name_from_CSV
    csv_2_AoH
    );

#-------------------------------------------------------------------------------
#   Reads a CSV file and returns the name of the comic series if available.
#   Returns undef if no series name can be found.
#
sub get_series_name_from_CSV {
    my $path_to_CSV = shift;

    # read the whole series line by line into an array holding the issues
    # CAUTION: the old CSV files were stored in Windows encoding (cp1252)
    open (SERIES, "<:encoding(cp1252)", $path_to_CSV) or die "Couldn't open $path_to_CSV: $?";
    my @issues = <SERIES>;
    close(SERIES);

    # create new CSV object
    my $csv = Text::CSV->new(
        { binary 			=> 1,       # alle codes allowed
            eol    			=> $\,      # set newline according to OS
            allow_whitespace 	=> 1,	# allow whitespace between fields
            quote_char		=> '"',     # set type of quotation marks
            sep_char			=> ',',	# set character for field separation
        });

    # split the fields of the first line holding issue information into its
    # data fields
    if ($csv->parse($issues[1]))
    {
        my @fields = $csv->fields();
        return $fields[36]; # field 36 should hold the name of the series
    }
    else
    {
        # If we have to return undef it is most likely that no data sets of
        # comic book issues exist jet.
        # Maybe only excerpts (Leseproben) existieren.
        return undef;
    }
}

#-------------------------------------------------------------------------------
#   Reads the comic book series into an array of hashes
#
sub csv_2_AoH {
    my $path_to_series = shift;

    my $path_to_hefte = path( $path_to_series )->child("hefte.txt")->canonpath;

    my $AoH = csv ({ in => $path_to_hefte, headers => "auto", encoding => "cp1252" }) or
        die Text::CSV->error_diag;

    return $AoH;
}

1;